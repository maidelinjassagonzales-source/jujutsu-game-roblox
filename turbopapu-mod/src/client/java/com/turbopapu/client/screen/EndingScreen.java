package com.turbopapu.client.screen;

import com.turbopapu.registry.ModEntities;
import net.minecraft.client.MinecraftClient;
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

    /** Escenario de fondo de cada foto (para que cuadre con lo que cuenta). */
    private enum Scene { FIESTA, CLASE, ASADO, CASTILLO, ICEBERG, MAR, PLAYA, SOTANO, LAVANDA, HOTEL, VALORANT, JARDIN, ALDEA }

    private record Photo(String caption, Scene scene, List<EntityType<? extends LivingEntity>> who) {}

    private static final List<Photo> PHOTOS = List.of(
            new Photo("La fiesta empezó tranquila. Los Turbopapuenses despertaron todos a la vez.", Scene.FIESTA,
                    List.of(ModEntities.TURBOPAPUENSE, ModEntities.TURBOPAPUENSE, ModEntities.TURBOPAPUENSE)),
            new Photo("Juanma dando una clase de inflación... a Sualenidus. Le cayó bien.", Scene.CLASE,
                    List.of(ModEntities.JUANMA, ModEntities.SUALENIDUS_AMIGO)),
            new Photo("Alguien le dio mate a Verity Gorda en el asado. Se tomó 40 y salió rodando.", Scene.ASADO,
                    List.of(ModEntities.VERITY_GORDA)),
            new Photo("elink_64 haciendo el moonwalk en la pista de Billie Jean de su castillo. ¡Hee-hee!", Scene.CASTILLO,
                    List.of(ModEntities.ELINK_64)),
            new Photo("A Guinxu le cayó un iceberg de Alphatemp en la cabeza. El pelo, intacto.", Scene.ICEBERG,
                    List.of(ModEntities.GUINXU, ModEntities.ALPHATEMP)),
            new Photo("William_Piraton salió del retiro solo por esta noche. Hizo directo desde su balsa. Con aroy24.", Scene.MAR,
                    List.of(ModEntities.WILLIAM_PIRATON, ModEntities.AROY)),
            new Photo("Aroy se bebió su propia leche de coco en la playa. Nadie sabe cómo. Ni él.", Scene.PLAYA,
                    List.of(ModEntities.AROY)),
            new Photo("Alphafaterfur sigue grabando su video de 2 horas en el sótano. Ahora sale todo esto en el video.", Scene.SOTANO,
                    List.of(ModEntities.ALPHAFATERFUR)),
            new Photo("Revancha de Valorant. Sualenidus perdió otra vez. Dice que fue lag.", Scene.VALORANT,
                    List.of(ModEntities.SUALENIDUS_AMIGO)),
            new Photo("Los Mudokons ganaron el torneo de Plantas vs Sualems. Abe hizo de nuez.", Scene.JARDIN,
                    List.of(ModEntities.MUDOKON, ModEntities.ABE, ModEntities.MUDOKON)),
            new Photo("Sualenidus, ya bueno y despierto. Sigue oliendo a lavanda.", Scene.LAVANDA,
                    List.of(ModEntities.SUALENIDUS_AMIGO, ModEntities.TURBOPAPUENSE)),
            new Photo("Nadie sabe quién se llevó el cohete. Ni por qué hay un tigre en el baño del hotel.", Scene.HOTEL,
                    List.of(ModEntities.TURBOPAPUENSE, ModEntities.VERITY_GORDA, ModEntities.ELINK_64)),
            new Photo("Y desde entonces, todos viven juntos en la Aldea de los Amigos.", Scene.ALDEA,
                    List.of(ModEntities.ALPHATEMP, ModEntities.GUINXU, ModEntities.AROY, ModEntities.JUANMA, ModEntities.VERITY_GORDA))
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
        drawScene(ctx, photo.scene(), fx, fy, fw, fh, slide);
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

    // ------------------------------------------------------------ fondos de las fotos

    private static void circle(DrawContext ctx, int cx, int cy, int r, int color) {
        for (int dy = -r; dy <= r; dy++) {
            int dx = (int) Math.sqrt(r * r - dy * dy);
            ctx.fill(cx - dx, cy + dy, cx + dx, cy + dy + 1, color);
        }
    }

    private static void triangle(DrawContext ctx, int cx, int baseY, int halfW, int h, int color) {
        for (int i = 0; i < h; i++) {
            int w = halfW * (i + 1) / h;
            ctx.fill(cx - w, baseY - h + i, cx + w, baseY - h + i + 1, color);
        }
    }

    private void drawScene(DrawContext ctx, Scene scene, int x, int y, int w, int h, int seed) {
        int ground = y + h * 2 / 3;
        switch (scene) {
            case FIESTA, ALDEA -> {
                // Cielo morado del planeta, suelo naranja, cúpulas y guirnaldas.
                ctx.fillGradient(x, y, x + w, ground, 0xFF5B2A8C, 0xFFE07A3A);
                ctx.fill(x, ground, x + w, y + h, 0xFFE8963A);
                for (int i = 0; i < 4; i++) {
                    int cx = x + w * (i * 2 + 1) / 8;
                    circle(ctx, cx, ground, w / 12, i % 2 == 0 ? 0xFFF2A33A : 0xFF3B3FD8);
                    ctx.fill(cx - w / 12, ground, cx + w / 12, ground + 2, 0xFFE8963A);
                }
                circle(ctx, x + w - 26, y + 18, 10, 0xFFFFE680);
                for (int i = 0; i < 14; i++) {
                    int lx = x + 4 + i * (w - 8) / 14;
                    ctx.fill(lx, y + 8 + (i % 2) * 3, lx + 4, y + 13 + (i % 2) * 3, i % 3 == 0 ? 0xFFFF4655 : i % 3 == 1 ? 0xFF3ED6C4 : 0xFFFFD34E);
                }
                if (scene == Scene.ALDEA) {
                    ctx.fill(x + w / 2 - 30, ground - 26, x + w / 2 + 30, ground - 14, 0xFF8B5A2B);
                    ctx.drawCenteredTextWithShadow(MinecraftClient.getInstance().textRenderer, "Aldea de los Amigos", x + w / 2, ground - 24, 0xFFFFFFFF);
                }
            }
            case CLASE -> {
                ctx.fill(x, y, x + w, y + h, 0xFFE8DCC0);
                ctx.fill(x + 10, y + 8, x + w - 10, y + h / 2, 0xFF2E5A3A);
                ctx.drawBorder(x + 10, y + 8, w - 20, h / 2 - 8, 0xFF8B5A2B);
                var tr = MinecraftClient.getInstance().textRenderer;
                ctx.drawText(tr, "INFLACIÓN: 300%", x + 18, y + 16, 0xFFEFEFEF, false);
                ctx.drawText(tr, "Sueño = 0 productividad", x + 18, y + 28, 0xFFEFEFEF, false);
                ctx.drawText(tr, "¡Che, tomá mate!", x + 18, y + 40, 0xFFFFE680, false);
                ctx.fill(x, ground + 6, x + w, y + h, 0xFF9C6B3A);
            }
            case ASADO -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFF0B1030, 0xFF3A2050);
                for (int i = 0; i < 20; i++) {
                    ctx.fill(x + (i * 53 + seed * 7) % w, y + (i * 29) % (h / 2), x + (i * 53 + seed * 7) % w + 1, y + (i * 29) % (h / 2) + 1, 0xFFFFFFFF);
                }
                ctx.fill(x, ground, x + w, y + h, 0xFFE8963A);
                ctx.fill(x + w - 60, ground - 18, x + w - 14, ground - 14, 0xFF555555);
                for (int i = 0; i < 4; i++) {
                    ctx.fill(x + w - 56 + i * 10, ground - 22, x + w - 50 + i * 10, ground - 18, 0xFF8B2A1A);
                }
                triangle(ctx, x + w - 37, ground - 18, 10, 12, 0xC0FF8A1A);
            }
            case CASTILLO -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFF4A90E2, 0xFFA8D8FF);
                ctx.fill(x + w / 4, ground - h / 3, x + w * 3 / 4, ground, 0xFFF2EFE6);
                triangle(ctx, x + w / 2, ground - h / 3, w / 6, h / 5, 0xFFD32F2F);
                ctx.fill(x + w / 2 - 6, ground - h / 3 + 6, x + w / 2 + 6, ground - h / 3 + 18, 0xFFF48FB1);
                ctx.fill(x + w / 2 - 6, ground - 14, x + w / 2 + 6, ground, 0xFF6B4423);
                for (int i = 0; i < 8; i++) {
                    for (int j = 0; j < 3; j++) {
                        int c = (i + j + seed) % 3 == 0 ? 0xFFFFF59D : (i + j) % 3 == 1 ? 0xFFFF80AB : 0xFF80DEEA;
                        ctx.fill(x + i * w / 8, ground + j * (h - (ground - y)) / 3, x + (i + 1) * w / 8, ground + (j + 1) * (h - (ground - y)) / 3, c);
                    }
                }
            }
            case ICEBERG -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFF8FD3F4, 0xFFE0F7FF);
                ctx.fill(x, ground, x + w, y + h, 0xFF2C7FB8);
                triangle(ctx, x + w / 3, ground, w / 5, h / 2, 0xFFF4FBFF);
                triangle(ctx, x + w / 3 + 6, ground, w / 9, h / 3, 0xFFB3E5FC);
                triangle(ctx, x + w * 3 / 4, ground, w / 7, h / 3, 0xFFE1F5FE);
                for (int i = 0; i < 25; i++) {
                    ctx.fill(x + (i * 41 + seed * 11) % w, y + (i * 17) % h, x + (i * 41 + seed * 11) % w + 2, y + (i * 17) % h + 2, 0xFFFFFFFF);
                }
            }
            case MAR -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFFFF9E5E, 0xFFFFD08A);
                circle(ctx, x + w / 2, ground, 18, 0xFFFFE680);
                ctx.fill(x, ground, x + w, y + h, 0xFF1E5AA8);
                for (int i = 0; i < 6; i++) {
                    ctx.fill(x + i * w / 6 + 4, ground + 6 + (i % 2) * 6, x + i * w / 6 + 18, ground + 7 + (i % 2) * 6, 0xFF7FB3FF);
                }
                ctx.fill(x + 8, ground - 4, x + 60, ground + 2, 0xFF8B5A2B);
                ctx.fill(x + 30, ground - 30, x + 32, ground - 4, 0xFF5A3A1A);
                ctx.fill(x + 33, ground - 28, x + 50, ground - 12, 0xFFF5F5F5);
                ctx.fill(x + w - 46, y + 6, x + w - 6, y + 18, 0xFFE53935);
                ctx.drawText(MinecraftClient.getInstance().textRenderer, "● EN VIVO", x + w - 44, y + 8, 0xFFFFFFFF, false);
            }
            case PLAYA -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFF4FC3F7, 0xFFB3E5FC);
                circle(ctx, x + w - 24, y + 16, 10, 0xFFFFEB3B);
                ctx.fill(x, ground, x + w, ground + 8, 0xFF29B6F6);
                ctx.fill(x, ground + 8, x + w, y + h, 0xFFF6D7A7);
                ctx.fill(x + 20, ground - 40, x + 25, ground + 10, 0xFF8D6E63);
                for (int i = -2; i <= 2; i++) {
                    ctx.fill(x + 22 + i * 8 - 6, ground - 44 + Math.abs(i) * 3, x + 22 + i * 8 + 6, ground - 40 + Math.abs(i) * 3, 0xFF43A047);
                }
                circle(ctx, x + 24, ground - 38, 3, 0xFF6D4C41);
            }
            case SOTANO -> {
                ctx.fill(x, y, x + w, y + h, 0xFF101014);
                ctx.fill(x + w / 2 - 30, y + 14, x + w / 2 + 30, y + 50, 0xFF1A1A22);
                ctx.fill(x + w / 2 - 27, y + 17, x + w / 2 + 27, y + 47, 0xFF4FC3F7);
                ctx.fill(x, ground + 8, x + w, y + h, 0xFF5A0E0E);
                ctx.drawText(MinecraftClient.getInstance().textRenderer, "● REC 01:59:59", x + 6, y + 6, (seed + System.currentTimeMillis() / 500) % 2 == 0 ? 0xFFFF3030 : 0xFF661010, false);
            }
            case LAVANDA -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFFB39DDB, 0xFFF3E5F5);
                ctx.fill(x, ground, x + w, y + h, 0xFF7CB342);
                for (int i = 0; i < 40; i++) {
                    int lx = x + (i * 23) % w, ly = ground + (i * 13) % (y + h - ground);
                    ctx.fill(lx, ly - 4, lx + 2, ly, 0xFF9575CD);
                }
            }
            case HOTEL -> {
                for (int i = 0; i < w; i += 10) {
                    for (int j = 0; j < h; j += 10) {
                        ctx.fill(x + i, y + j, x + Math.min(w, i + 10), y + Math.min(h, j + 10), ((i + j) / 10) % 2 == 0 ? 0xFFF0F0F0 : 0xFFB0BEC5);
                    }
                }
                // ¿Un tigre?
                ctx.fill(x + w - 70, ground - 10, x + w - 20, ground + 10, 0xFFFF9800);
                for (int i = 0; i < 5; i++) {
                    ctx.fill(x + w - 66 + i * 10, ground - 10, x + w - 63 + i * 10, ground + 10, 0xFF212121);
                }
                ctx.fill(x + w - 22, ground - 16, x + w - 8, ground - 2, 0xFFFF9800);
            }
            case VALORANT -> {
                ctx.fillGradient(x, y, x + w, ground, 0xFFFFE0B2, 0xFFFFCC80);
                ctx.fill(x, ground, x + w, y + h, 0xFFD7B98E);
                ctx.fill(x + 10, ground - 30, x + 40, ground, 0xFFE8D2A8);
                ctx.fill(x + w - 50, ground - 24, x + w - 20, ground, 0xFFC8A87A);
                ctx.fill(x + w / 2 - 8, ground - 30, x + w / 2 + 8, ground - 16, 0xFFFF4655);
                ctx.drawCenteredTextWithShadow(MinecraftClient.getInstance().textRenderer, "A", x + w / 2, ground - 27, 0xFFFFFFFF);
                ctx.drawText(MinecraftClient.getInstance().textRenderer, "VICTORIA 13-0", x + 6, y + 6, 0xFF3ED6C4, true);
            }
            case JARDIN -> {
                ctx.fillGradient(x, y, x + w, y + h / 3, 0xFF81D4FA, 0xFFE1F5FE);
                for (int r = 0; r < 4; r++) {
                    for (int c = 0; c < 9; c++) {
                        int yy = y + h / 3 + r * (h * 2 / 3) / 4;
                        ctx.fill(x + c * w / 9, yy, x + (c + 1) * w / 9, yy + (h * 2 / 3) / 4 + 1, (r + c) % 2 == 0 ? 0xFF8BC34A : 0xFF689F38);
                    }
                }
                ctx.fill(x, y + h / 3, x + 14, y + h, 0xFFEFEFEF);
            }
        }
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
                "Verity Gorda, la pelota con cara (invitada especial)",
                "Aroy (aroy24 / aroy25), la lata de leche de coco",
                "Sualenidus, que ahora huele a lavanda... pero en buena onda",
                "",
                "Y ahora todos viven juntos en la Aldea de los Amigos.",
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
