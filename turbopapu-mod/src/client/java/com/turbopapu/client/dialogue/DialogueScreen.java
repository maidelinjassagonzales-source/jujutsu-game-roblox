package com.turbopapu.client.dialogue;

import com.mojang.blaze3d.systems.RenderSystem;
import com.turbopapu.TurboPapuMod;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.entity.Entity;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.OrderedText;
import net.minecraft.text.StringVisitable;
import net.minecraft.text.Text;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import org.lwjgl.glfw.GLFW;

import java.util.List;
import java.util.Objects;
import java.util.Random;

/**
 * Pantalla de diálogo al estilo de LoyolaQuest: caja oscura con borde dorado, etiqueta con el nombre,
 * texto que aparece letra a letra, retrato del personaje a la derecha (que tiembla si "shake"),
 * música por personaje, foto opcional y "Clic / Espacio" para avanzar.
 * Mientras habla, la cámara mira al personaje y se oculta el HUD.
 */
public class DialogueScreen extends Screen {
    private static final long MS_PER_CHAR = 22;

    private final List<Dialogues.Step> steps;
    private final Random random = new Random();
    private final int npcId;
    private Runnable onFinish;
    private int index;
    private long stepStart;
    private boolean fullyShown;
    private String musicKey;
    private SoundInstance music;
    private boolean oldHudHidden;

    public DialogueScreen(List<Dialogues.Step> steps, int npcId) {
        super(Text.literal("Diálogo"));
        this.steps = steps;
        this.npcId = npcId;
    }

    public DialogueScreen onFinish(Runnable onFinish) {
        this.onFinish = onFinish;
        return this;
    }

    @Override
    protected void init() {
        if (stepStart == 0) {
            oldHudHidden = client.options.hudHidden;
            client.options.hudHidden = true;
            startStep();
        }
    }

    private Dialogues.Step step() {
        return steps.get(index);
    }

    private void startStep() {
        stepStart = System.currentTimeMillis();
        fullyShown = false;
        String key = step().music();
        if (key != null && !key.equals(musicKey)) {
            playMusic(key);
        }
    }

    private void playMusic(String key) {
        stopMusic();
        musicKey = key;
        client.getMusicTracker().stop();
        music = PositionedSoundInstance.master(SoundEvent.of(TurboPapuMod.id("music." + key)), 1f, 0.8f);
        client.getSoundManager().play(music);
    }

    private void stopMusic() {
        if (music != null) {
            client.getSoundManager().stop(music);
            music = null;
        }
        musicKey = null;
    }

    private int visibleChars() {
        if (fullyShown) {
            return Integer.MAX_VALUE;
        }
        return (int) ((System.currentTimeMillis() - stepStart) / MS_PER_CHAR);
    }

    private void advance() {
        if (visibleChars() < step().text().length()) {
            fullyShown = true;
            return;
        }
        if (index + 1 >= steps.size()) {
            close();
            return;
        }
        index++;
        client.getSoundManager().play(PositionedSoundInstance.master(SoundEvents.UI_BUTTON_CLICK.value(), 1.6f, 0.25f));
        startStep();
    }

    @Override
    public void tick() {
        // Cámara: gira la vista hacia la cabeza del personaje que habla.
        if (npcId >= 0 && client.world != null && client.player != null) {
            Entity npc = client.world.getEntityById(npcId);
            if (npc != null) {
                Vec3d d = npc.getEyePos().subtract(client.player.getEyePos());
                double horiz = Math.sqrt(d.x * d.x + d.z * d.z);
                float yaw = (float) (MathHelper.atan2(d.z, d.x) * MathHelper.DEGREES_PER_RADIAN) - 90f;
                float pitch = (float) -(MathHelper.atan2(d.y, horiz) * MathHelper.DEGREES_PER_RADIAN);
                client.player.setYaw(client.player.getYaw() + MathHelper.wrapDegrees(yaw - client.player.getYaw()) * 0.3f);
                client.player.setPitch(client.player.getPitch() + (pitch - client.player.getPitch()) * 0.3f);
            }
        }
    }

    @Override
    public boolean mouseClicked(double mouseX, double mouseY, int button) {
        advance();
        return true;
    }

    @Override
    public boolean keyPressed(int keyCode, int scanCode, int modifiers) {
        if (keyCode == GLFW.GLFW_KEY_SPACE || keyCode == GLFW.GLFW_KEY_ENTER || keyCode == GLFW.GLFW_KEY_KP_ENTER) {
            advance();
            return true;
        }
        return super.keyPressed(keyCode, scanCode, modifiers);
    }

    @Override
    public void removed() {
        stopMusic();
        client.options.hudHidden = oldHudHidden;
    }

    @Override
    public void close() {
        super.close();
        if (onFinish != null) {
            Runnable r = onFinish;
            onFinish = null;
            r.run();
        }
    }

    @Override
    public boolean shouldPause() {
        return false;
    }

    @Override
    public void renderBackground(DrawContext ctx) {
        ctx.fillGradient(0, 0, width, height, 0x30000000, 0xB0000000);
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        renderBackground(ctx);
        super.render(ctx, mouseX, mouseY, delta);
        Dialogues.Step step = step();
        int boxH = Math.max(70, height / 4);
        int boxX = 20;
        int boxW = width - 40;
        int boxY = height - boxH - 12;

        if (step.photo() != null) {
            // "imagen:ancho:alto" centrada encima de la caja.
            String[] p = step.photo().split(":");
            int pw = Integer.parseInt(p[1]);
            int ph = Integer.parseInt(p[2]);
            int maxW = width - 60;
            int maxH = boxY - 30;
            int w = maxW;
            int h = ph * w / pw;
            if (h > maxH) {
                h = maxH;
                w = pw * h / ph;
            }
            int x = (width - w) / 2;
            int y = Math.max(12, (boxY - 18 - h) / 2 + 6);
            ctx.fill(x - 4, y - 4, x + w + 4, y + h + 4, 0xFFF0F0F0);
            ctx.drawTexture(TurboPapuMod.id("textures/photo/" + p[0] + ".png"), x, y, w, h, 0, 0, pw, ph, pw, ph);
            renderBox(ctx, step, boxX, boxY, boxW, boxH, 0, 0);
            return;
        }

        int sx = 0, sy = 0;
        if (step.shake() && System.currentTimeMillis() - stepStart < 600) {
            sx = random.nextInt(9) - 4;
            sy = random.nextInt(7) - 3;
        }
        if (step.portrait() != null && step.pw() > 0 && step.ph() > 0) {
            int drawH = Math.min(boxY + boxH / 3 - 8, (int) (height * 0.62));
            int drawW = step.pw() * drawH / step.ph();
            if (drawW > width / 2) {
                drawW = width / 2;
                drawH = step.ph() * drawW / step.pw();
            }
            int px = width - drawW - 30 + sx;
            int py = boxY + boxH / 3 - drawH + sy;
            RenderSystem.enableBlend();
            ctx.drawTexture(TurboPapuMod.id("textures/portrait/" + step.portrait() + ".png"), px, py, drawW, drawH,
                    0, 0, step.pw(), step.ph(), step.pw(), step.ph());
            RenderSystem.disableBlend();
        }
        renderBox(ctx, step, boxX, boxY, boxW, boxH, sx, sy);
    }

    private void renderBox(DrawContext ctx, Dialogues.Step step, int x, int y, int w, int h, int sx, int sy) {
        ctx.fill(x + sx, y + sy, x + w + sx, y + h + sy, 0xE0101018);
        ctx.drawBorder(x + sx, y + sy, w, h, 0xFFE0B040);

        String name = Objects.requireNonNullElse(step.name(), "");
        int color = switch (name) {
            case "Tú" -> 0xFFFFC040;
            case "Sistema" -> 0xFFFFFF55;
            case "Sualenidus" -> 0xFFD8A8FF;
            default -> 0xFFFFFFFF;
        };
        int tagW = textRenderer.getWidth(name) + 12;
        int tagX = x + 10 + sx;
        int tagY = y - 14 + sy;
        ctx.fill(tagX, tagY, tagX + tagW, tagY + 14, 0xF0202030);
        ctx.drawBorder(tagX, tagY, tagW, 14, 0xFFE0B040);
        ctx.drawText(textRenderer, name, tagX + 6, tagY + 3, color, true);

        String text = step.text();
        int shown = Math.min(text.length(), visibleChars());
        if (shown >= text.length()) {
            fullyShown = true;
        }
        List<OrderedText> lines = textRenderer.wrapLines(StringVisitable.plain(text.substring(0, shown)), w - 24);
        int lineY = y + 12 + sy;
        for (OrderedText line : lines) {
            ctx.drawText(textRenderer, line, x + 12 + sx, lineY, 0xFFFFFFFF, true);
            lineY += 11;
        }
        if (fullyShown && (System.currentTimeMillis() / 400) % 2 == 0) {
            String hint = index + 1 < steps.size() ? "▶ Clic / Espacio" : "■ Cerrar";
            ctx.drawText(textRenderer, hint, x + w - textRenderer.getWidth(hint) - 10, y + h - 14, 0xFFAAAAAA, false);
        }
        ctx.drawText(textRenderer, (index + 1) + "/" + steps.size(), x + 10, y + h - 14, 0xFF666677, false);
    }
}
