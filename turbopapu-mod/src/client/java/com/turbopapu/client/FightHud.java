package com.turbopapu.client;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.fight.PvzPlantType;
import com.turbopapu.item.VandalItem;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModItems;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.item.ItemStack;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.sound.SoundCategory;
import net.minecraft.util.math.random.Random;

/**
 * Estado de la pelea final en el cliente (lo manda el servidor cada 4 ticks) y HUD:
 * temporizador de la Spike y barra de desactivado en Valorant, munición de la Vandal,
 * efecto "glitch" al cambiar de juego y la música de zona.
 */
public final class FightHud {
    public static int phase = -1;
    public static int round, spikeTicks, defuse;
    public static int sun, wave, waveProgress;
    public static String message = "";
    public static final int[] cooldowns = new int[PvzPlantType.values().length];

    private static int glitchTicks;
    private static SoundInstance areaMusic;
    private static String areaMusicKey = "";

    private FightHud() {}

    // Fases (mismo orden que BossFight.Phase)
    public static final int RING = 0, TO_VALORANT = 1, VALORANT_PREP = 2, VALORANT = 3, SOULS = 4, PVZ = 5;

    public static void read(PacketByteBuf buf) {
        phase = buf.readVarInt();
        if (phase < 0) {
            return;
        }
        round = buf.readVarInt();
        spikeTicks = buf.readVarInt();
        defuse = buf.readVarInt();
        if (buf.readBoolean()) {
            sun = buf.readVarInt();
            wave = buf.readVarInt();
            waveProgress = buf.readVarInt();
            message = buf.readString();
            for (int i = 0; i < cooldowns.length; i++) {
                cooldowns[i] = buf.readVarInt();
            }
        }
    }

    public static void glitch() {
        glitchTicks = 40;
    }

    public static void tick() {
        if (glitchTicks > 0) {
            glitchTicks--;
        }
    }

    public static void sendDialogueAction(String action) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeString(action);
        ClientPlayNetworking.send(ModPackets.DIALOGUE_ACTION, buf);
    }

    /** Música de zona en bucle (por ejemplo, la aldea Mudokon). */
    public static void setAreaMusic(String key) {
        MinecraftClient client = MinecraftClient.getInstance();
        if (key.equals(areaMusicKey)) {
            return;
        }
        if (areaMusic != null) {
            client.getSoundManager().stop(areaMusic);
            areaMusic = null;
        }
        areaMusicKey = key;
        if (!key.isEmpty()) {
            client.getMusicTracker().stop();
            areaMusic = new PositionedSoundInstance(TurboPapuMod.id("music." + key), SoundCategory.MUSIC, 0.8f, 1f,
                    Random.create(), true, 0, SoundInstance.AttenuationType.NONE, 0, 0, 0, true);
            client.getSoundManager().play(areaMusic);
        }
    }

    public static void render(DrawContext ctx) {
        MinecraftClient client = MinecraftClient.getInstance();
        int w = ctx.getScaledWindowWidth();
        int h = ctx.getScaledWindowHeight();

        if (phase == VALORANT || phase == VALORANT_PREP) {
            // Cabecera estilo Valorant.
            int cx = w / 2;
            ctx.fill(cx - 70, 4, cx + 70, 30, 0xC0101820);
            ctx.fill(cx - 70, 4, cx - 40, 30, 0xC03ED6C4);
            ctx.fill(cx + 40, 4, cx + 70, 30, 0xC0FF4655);
            ctx.drawCenteredTextWithShadow(client.textRenderer, "TÚ", cx - 55, 13, 0xFFFFFFFF);
            ctx.drawCenteredTextWithShadow(client.textRenderer, "SUAL", cx + 55, 13, 0xFFFFFFFF);
            String time = phase == VALORANT_PREP ? "PREP." : String.format("%d.%d", spikeTicks / 20, (spikeTicks % 20) / 2);
            int timeColor = spikeTicks < 200 && (spikeTicks / 5) % 2 == 0 ? 0xFFFF4655 : 0xFFFFFFFF;
            ctx.drawCenteredTextWithShadow(client.textRenderer, "◆ " + time, cx, 9, timeColor);
            ctx.drawCenteredTextWithShadow(client.textRenderer, "RONDA " + round, cx, 20, 0xFFAAAAAA);
            if (defuse > 0) {
                int bw = 160, bx = cx - bw / 2, by = h / 2 + 30;
                ctx.drawCenteredTextWithShadow(client.textRenderer, "¡Sualenidus está desactivando la Spike!", cx, by - 12, 0xFFFF4655);
                ctx.fill(bx - 1, by - 1, bx + bw + 1, by + 7, 0xFF000000);
                ctx.fill(bx, by, bx + bw * defuse / 140, by + 6, 0xFF3ED6C4);
                ctx.fill(bx + bw / 2, by - 2, bx + bw / 2 + 1, by + 8, 0xFFFFFFFF);
            }
        }
        // Munición de la Vandal.
        if (client.player != null) {
            ItemStack stack = client.player.getMainHandStack();
            if (stack.isOf(ModItems.VANDAL)) {
                int reload = VandalItem.getReload(stack);
                String ammo = reload > 0 ? "RECARGANDO..." : VandalItem.getAmmo(stack) + " / " + VandalItem.MAG;
                ctx.fill(w - 96, h - 34, w - 6, h - 8, 0xA0101820);
                ctx.drawText(client.textRenderer, "VANDAL", w - 90, h - 30, 0xFFFF4655, true);
                ctx.drawText(client.textRenderer, ammo, w - 90, h - 19, 0xFFFFFFFF, true);
            }
        }
        if (glitchTicks > 0) {
            renderGlitch(ctx, w, h);
        }
    }

    /** "¡ESTE NO ES MI JUEGO!": franjas de colores desplazadas y ruido. */
    private static void renderGlitch(DrawContext ctx, int w, int h) {
        java.util.Random r = new java.util.Random();
        int alpha = Math.min(255, glitchTicks * 10);
        for (int i = 0; i < 18; i++) {
            int y = r.nextInt(h);
            int bh = 2 + r.nextInt(14);
            int off = r.nextInt(40) - 20;
            int color = switch (r.nextInt(4)) {
                case 0 -> 0xFF4655;
                case 1 -> 0x3ED6C4;
                case 2 -> 0xB57EDC;
                default -> 0xFFFFFF;
            };
            ctx.fill(off, y, w + off, y + bh, ((alpha / 2) << 24) | color);
        }
        if (glitchTicks > 20) {
            String txt = "ESTE NO ES MI JUEGO";
            int tw = MinecraftClient.getInstance().textRenderer.getWidth(txt);
            ctx.getMatrices().push();
            ctx.getMatrices().translate(w / 2f, h / 3f, 0);
            ctx.getMatrices().scale(2.5f, 2.5f, 1);
            ctx.drawText(MinecraftClient.getInstance().textRenderer, txt, -tw / 2 + r.nextInt(3) - 1, 0, 0xFFFF4655, true);
            ctx.getMatrices().pop();
        }
    }
}
