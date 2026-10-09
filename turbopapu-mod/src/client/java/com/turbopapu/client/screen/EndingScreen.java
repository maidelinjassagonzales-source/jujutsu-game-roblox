package com.turbopapu.client.screen;

import com.turbopapu.registry.ModEntities;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.screen.ingame.InventoryScreen;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.client.sound.SoundInstance;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.math.RotationAxis;

import java.util.ArrayList;
import java.util.List;

/**
 * Final al estilo "Resacón en Las Vegas" (The Hangover): durante los créditos aparecen las "fotos" de la
 * fiesta descontrolada que nadie recuerda, una tras otra, como polaroids encontradas en una cámara.
 */
public class EndingScreen extends Screen {
    private static final int SLIDE_TICKS = 110;

    private record Photo(String caption, List<EntityType<? extends LivingEntity>> who) {}

    private static final List<Photo> PHOTOS = List.of(
            new Photo("La fiesta empezó tranquila. Los Turbopapuenses despertaron todos a la vez.",
                    List.of(ModEntities.TURBOPAPUENSE, ModEntities.TURBOPAPUENSE, ModEntities.TURBOPAPUENSE)),
            new Photo("Juanma dando una clase de inflación... a Sualenidus. Le cayó bien.",
                    List.of(ModEntities.JUANMA, ModEntities.SUALENIDUS)),
            new Photo("Alguien le dio mate a Verity Gorda. Se tomó 40.",
                    List.of(ModEntities.VERITY_GORDA)),
            new Photo("elink_64 haciendo el moonwalk encima del cohete. ¡Hee-hee!",
                    List.of(ModEntities.ELINK_64)),
            new Photo("Guinxu después de que le cayera un iceberg. El pelo, intacto.",
                    List.of(ModEntities.GUINXU, ModEntities.ALPHATEMP)),
            new Photo("William_Piraton salió del retiro solo por esta noche. Hizo directo. Con aroy24.",
                    List.of(ModEntities.WILLIAM_PIRATON)),
            new Photo("Alphafaterfur sigue grabando su video de 2 horas. Ahora sale todo esto en el video.",
                    List.of(ModEntities.ALPHAFATERFUR)),
            new Photo("Sualenidus, ya bueno y despierto. Sigue oliendo a lavanda. Sigue hablando de la Vandal.",
                    List.of(ModEntities.SUALENIDUS, ModEntities.TURBOPAPUENSE)),
            new Photo("Nadie sabe quién se llevó el cohete. Ni por qué hay un tigre en la aldea.",
                    List.of(ModEntities.TURBOPAPUENSE, ModEntities.VERITY_GORDA, ModEntities.ELINK_64))
    );

    private final List<List<LivingEntity>> actors = new ArrayList<>();
    private SoundInstance music;
    private int ticks;

    public EndingScreen() {
        super(Text.literal("Fin"));
    }

    @Override
    protected void init() {
        if (!actors.isEmpty() || client == null || client.world == null) {
            return;
        }
        for (Photo photo : PHOTOS) {
            List<LivingEntity> list = new ArrayList<>();
            for (EntityType<? extends LivingEntity> type : photo.who()) {
                LivingEntity e = type.create(client.world);
                if (e != null) {
                    list.add(e);
                }
            }
            actors.add(list);
        }
        music = PositionedSoundInstance.master(SoundEvents.MUSIC_DISC_PIGSTEP, 1f, 0.7f);
        client.getSoundManager().play(music);
    }

    @Override
    public void tick() {
        ticks++;
        for (List<LivingEntity> list : actors) {
            for (LivingEntity e : list) {
                e.age++;
            }
        }
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        ctx.fill(0, 0, width, height, 0xFF000000);
        int slide = ticks / SLIDE_TICKS;
        if (slide >= PHOTOS.size()) {
            renderCredits(ctx, ticks - PHOTOS.size() * SLIDE_TICKS);
            return;
        }
        Photo photo = PHOTOS.get(slide);
        float local = (ticks % SLIDE_TICKS + delta) / SLIDE_TICKS;
        float tilt = (slide % 2 == 0 ? -1 : 1) * (4 + slide % 3 * 2);

        int pw = Math.min(220, width - 40);
        int ph = Math.min(190, height - 50);
        int px = (width - pw) / 2;
        int py = (height - ph) / 2 - 10;

        // Polaroid inclinada.
        ctx.getMatrices().push();
        ctx.getMatrices().translate(width / 2f, height / 2f, 0);
        ctx.getMatrices().multiply(RotationAxis.POSITIVE_Z.rotationDegrees(tilt * (1 - Math.min(1, local * 4)) + tilt * 0.4f));
        ctx.getMatrices().translate(-width / 2f, -height / 2f, 0);
        ctx.fill(px - 2, py - 2, px + pw + 2, py + ph + 2, 0xFF333333);
        ctx.fill(px, py, px + pw, py + ph, 0xFFF5F5F0);
        // "Foto" con fondo de fiesta (flash).
        int fx = px + 10, fy = py + 10, fw = pw - 20, fh = ph - 50;
        ctx.fillGradient(fx, fy, fx + fw, fy + fh, 0xFF3A1C5C, 0xFFB5651D);
        for (int i = 0; i < 12; i++) {
            int lx = fx + (i * 37 + slide * 13) % fw;
            int ly = fy + (i * 23 + slide * 7) % (fh / 2);
            int color = (i % 3 == 0) ? 0xFFF2A33A : (i % 3 == 1) ? 0xFF4B3FD1 : 0xFFB57EDC;
            ctx.fill(lx, ly, lx + 3, ly + 3, color);
        }
        ctx.drawText(textRenderer, "#" + (slide + 1), px + pw - 26, py + ph - 14, 0xFF888888, false);
        int textY = py + ph - 36;
        for (var line : textRenderer.wrapLines(Text.literal(photo.caption()), pw - 20)) {
            ctx.drawText(textRenderer, line, px + 10, textY, 0xFF222222, false);
            textY += 10;
        }
        ctx.getMatrices().pop();

        // Los protagonistas de la foto.
        List<LivingEntity> who = slide < actors.size() ? actors.get(slide) : List.of();
        int n = who.size();
        for (int i = 0; i < n; i++) {
            LivingEntity e = who.get(i);
            int ex = fx + fw * (i + 1) / (n + 1);
            int ey = fy + fh - 6;
            int size = (int) (fh * 0.42f / Math.max(e.getHeight(), 1.0f));
            InventoryScreen.drawEntity(ctx, ex, ey, size, (i - n / 2f) * 30f, -10f, e);
        }

        // Flash de cámara al cambiar de foto.
        if (local < 0.08f) {
            int alpha = (int) ((1 - local / 0.08f) * 220) & 0xFF;
            ctx.fill(0, 0, width, height, (alpha << 24) | 0xFFFFFF);
        }
        ctx.drawCenteredTextWithShadow(textRenderer, Text.literal("Fotos encontradas en la cámara de alguien..."), width / 2, height - 16, 0xFFAAAAAA);
    }

    private void renderCredits(DrawContext ctx, int t) {
        String[] lines = {
                "FIN",
                "",
                "Has salvado el Planeta TurboPapu.",
                "",
                "TurboPapu y los Turbopapuenses",
                "Alphatemp (y Alphafaterfur, que sigue grabando)",
                "William_Piraton, retirado (otra vez)",
                "Juanma, profesor de economía y fan de los argentinos",
                "Guinxu y su pelo",
                "elink_64, el streamer que nunca olvidaremos",
                "Verity Gorda, invitada especial",
                "Sualenidus, que ahora huele a lavanda... pero en buena onda",
                "",
                "Gracias por jugar.  (ESC para cerrar)"
        };
        int y = Math.max(height - t, 20);
        for (String line : lines) {
            int color = line.equals("FIN") ? 0xFFF2A33A : 0xFFFFFFFF;
            ctx.drawCenteredTextWithShadow(textRenderer, Text.literal(line), width / 2, y, color);
            y += line.equals("FIN") ? 24 : 14;
        }
    }

    @Override
    public void removed() {
        if (music != null && client != null) {
            client.getSoundManager().stop(music);
        }
    }

    @Override
    public boolean shouldPause() {
        return false;
    }
}
