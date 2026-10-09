package com.turbopapu.client.screen;

import com.turbopapu.client.FightHud;
import com.turbopapu.client.PlantVisuals;
import com.turbopapu.fight.Arenas;
import com.turbopapu.fight.PvzPlantType;
import com.turbopapu.network.ModPackets;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.gui.screen.ingame.InventoryScreen;
import net.minecraft.client.option.Perspective;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.text.Text;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

/**
 * Plantas vs Zombies: la cámara pasa a una vista fija del jardín (como en el juego original),
 * arriba a la izquierda está la barra de semillas con los amigos y los soles,
 * y con el ratón se planta en las casillas del césped.
 */
public class PvzScreen extends Screen {
    private static final int CARD_W = 36, CARD_H = 50;

    private final int cameraId;
    private Entity camera;
    private int selected = -1;
    private boolean shovel;
    private int hoverCol = -1, hoverRow = -1;
    private boolean oldHud;
    private Perspective oldPerspective;
    private int ticks;

    public PvzScreen(int cameraId) {
        super(Text.literal("Plantas vs Sualems"));
        this.cameraId = cameraId;
    }

    @Override
    protected void init() {
        if (ticks == 0) {
            oldHud = client.options.hudHidden;
            oldPerspective = client.options.getPerspective();
            client.options.hudHidden = true;
            client.options.setPerspective(Perspective.FIRST_PERSON);
        }
    }

    @Override
    public void tick() {
        ticks++;
        if (camera == null || camera.isRemoved()) {
            camera = client.world == null ? null : client.world.getEntityById(cameraId);
            if (camera != null) {
                client.setCameraEntity(camera);
            }
        }
    }

    @Override
    public void removed() {
        if (client.player != null) {
            client.setCameraEntity(client.player);
        }
        client.options.hudHidden = oldHud;
        if (oldPerspective != null) {
            client.options.setPerspective(oldPerspective);
        }
    }

    @Override
    public boolean shouldPause() {
        return false;
    }

    @Override
    public boolean shouldCloseOnEsc() {
        return false;
    }

    // ------------------------------------------------------------ cámara -> casillas

    private double[] basis() {
        float yaw = camera.getYaw() * MathHelper.RADIANS_PER_DEGREE;
        float pitch = camera.getPitch() * MathHelper.RADIANS_PER_DEGREE;
        Vec3d f = Vec3d.fromPolar(camera.getPitch(), camera.getYaw());
        Vec3d right = f.crossProduct(new Vec3d(0, 1, 0)).normalize();
        Vec3d up = right.crossProduct(f).normalize();
        return new double[]{f.x, f.y, f.z, right.x, right.y, right.z, up.x, up.y, up.z, yaw, pitch};
    }

    private double tanHalf() {
        return Math.tan(Math.toRadians(client.options.getFov().getValue()) / 2.0);
    }

    /** Rayo desde la cámara por el ratón hasta el plano del césped. */
    private int[] cellAt(double mx, double my) {
        if (camera == null) {
            return null;
        }
        double[] b = basis();
        double aspect = (double) width / height;
        double nx = (2 * mx / width - 1) * tanHalf() * aspect;
        double ny = (1 - 2 * my / height) * tanHalf();
        double dx = b[0] + b[3] * nx + b[6] * ny;
        double dy = b[1] + b[4] * nx + b[7] * ny;
        double dz = b[2] + b[5] * nx + b[8] * ny;
        Vec3d eye = camera.getEyePos();
        if (dy >= -1e-4) {
            return null;
        }
        double t = (Arenas.LAWN_Y - eye.y) / dy;
        double px = eye.x + dx * t, pz = eye.z + dz * t;
        int col = MathHelper.floor((px - Arenas.LAWN_X) / Arenas.CELL);
        int row = MathHelper.floor((pz - Arenas.LAWN_Z) / Arenas.CELL);
        if (col < 0 || col >= Arenas.COLS || row < 0 || row >= Arenas.ROWS) {
            return null;
        }
        return new int[]{col, row};
    }

    /** Punto del mundo -> pantalla (para dibujar el recuadro de la casilla). */
    private double[] project(double x, double y, double z) {
        double[] b = basis();
        Vec3d eye = camera.getEyePos();
        double vx = x - eye.x, vy = y - eye.y, vz = z - eye.z;
        double cz = vx * b[0] + vy * b[1] + vz * b[2];
        if (cz <= 0.1) {
            return null;
        }
        double cx = vx * b[3] + vy * b[4] + vz * b[5];
        double cy = vx * b[6] + vy * b[7] + vz * b[8];
        double aspect = (double) width / height;
        double sx = (cx / (cz * tanHalf() * aspect) + 1) / 2 * width;
        double sy = (1 - cy / (cz * tanHalf())) / 2 * height;
        return new double[]{sx, sy};
    }

    private void line(DrawContext ctx, double[] a, double[] b, int color) {
        if (a == null || b == null) {
            return;
        }
        int steps = (int) Math.max(Math.abs(b[0] - a[0]), Math.abs(b[1] - a[1]));
        for (int i = 0; i <= steps; i++) {
            int x = (int) (a[0] + (b[0] - a[0]) * i / Math.max(1, steps));
            int y = (int) (a[1] + (b[1] - a[1]) * i / Math.max(1, steps));
            ctx.fill(x, y, x + 2, y + 2, color);
        }
    }

    // ------------------------------------------------------------ entrada

    @Override
    public void mouseMoved(double mouseX, double mouseY) {
        int[] cell = cellAt(mouseX, mouseY);
        hoverCol = cell == null ? -1 : cell[0];
        hoverRow = cell == null ? -1 : cell[1];
    }

    @Override
    public boolean mouseClicked(double mouseX, double mouseY, int button) {
        if (button == 1) {
            selected = -1;
            shovel = false;
            return true;
        }
        // Barra de semillas.
        int n = PvzPlantType.values().length;
        for (int i = 0; i < n; i++) {
            int x = 52 + i * (CARD_W + 2);
            if (mouseX >= x && mouseX < x + CARD_W && mouseY >= 6 && mouseY < 6 + CARD_H) {
                selected = selected == i ? -1 : i;
                shovel = false;
                return true;
            }
        }
        int shovelX = 52 + n * (CARD_W + 2) + 4;
        if (mouseX >= shovelX && mouseX < shovelX + 32 && mouseY >= 6 && mouseY < 6 + 32) {
            shovel = !shovel;
            selected = -1;
            return true;
        }
        int[] cell = cellAt(mouseX, mouseY);
        if (cell != null) {
            PacketByteBuf buf = PacketByteBufs.create();
            buf.writeVarInt(cell[0]);
            buf.writeVarInt(cell[1]);
            if (shovel) {
                ClientPlayNetworking.send(ModPackets.PVZ_SHOVEL, buf);
                shovel = false;
            } else if (selected >= 0) {
                buf.writeVarInt(selected);
                ClientPlayNetworking.send(ModPackets.PVZ_PLACE, buf);
                selected = -1;
            }
        }
        return true;
    }

    @Override
    public boolean keyPressed(int keyCode, int scanCode, int modifiers) {
        // En el modo libre, ESC sale del minijuego.
        if (keyCode == 256 && FightHud.arcade) {
            net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking.send(com.turbopapu.network.ModPackets.PVZ_QUIT,
                    net.fabricmc.fabric.api.networking.v1.PacketByteBufs.empty());
            return true;
        }
        // Atajos 1-9 para elegir amigo.
        if (keyCode >= 49 && keyCode < 49 + PvzPlantType.values().length) {
            selected = keyCode - 49;
            shovel = false;
            return true;
        }
        return super.keyPressed(keyCode, scanCode, modifiers);
    }

    // ------------------------------------------------------------ dibujo

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        if (camera == null) {
            ctx.fill(0, 0, width, height, 0xFF000000);
            ctx.drawCenteredTextWithShadow(textRenderer, "Cargando el jardín...", width / 2, height / 2, 0xFFFFFFFF);
            return;
        }
        // Casilla bajo el ratón.
        if (hoverCol >= 0 && (selected >= 0 || shovel)) {
            double x0 = Arenas.LAWN_X + hoverCol * Arenas.CELL, z0 = Arenas.LAWN_Z + hoverRow * Arenas.CELL;
            double y = Arenas.LAWN_Y + 0.02;
            double[] a = project(x0, y, z0), b = project(x0 + Arenas.CELL, y, z0);
            double[] c = project(x0 + Arenas.CELL, y, z0 + Arenas.CELL), d = project(x0, y, z0 + Arenas.CELL);
            int color = shovel ? 0xFFFF5555 : 0xFFFFFF80;
            line(ctx, a, b, color);
            line(ctx, b, c, color);
            line(ctx, c, d, color);
            line(ctx, d, a, color);
        }

        // Barra de semillas (madera).
        int n = PvzPlantType.values().length;
        int barW = 52 + n * (CARD_W + 2) + 42;
        ctx.fill(2, 2, barW, 6 + CARD_H + 4, 0xFF6B4423);
        ctx.fill(4, 4, barW - 2, 6 + CARD_H + 2, 0xFF8B5A2B);
        // Soles.
        ctx.fill(8, 8, 46, 52, 0xFF5A3A1A);
        ctx.fill(17, 12, 37, 32, 0xFFFFD400);
        ctx.fill(20, 15, 34, 29, 0xFFFFF176);
        ctx.drawCenteredTextWithShadow(textRenderer, String.valueOf(FightHud.sun), 27, 38, 0xFFFFFFFF);
        for (int i = 0; i < n; i++) {
            PvzPlantType type = PvzPlantType.byId(i);
            int x = 52 + i * (CARD_W + 2), y = 6;
            boolean affordable = FightHud.sun >= type.cost;
            ctx.fill(x, y, x + CARD_W, y + CARD_H, i == selected ? 0xFFFFF59D : 0xFFE8D9A8);
            ctx.drawBorder(x, y, CARD_W, CARD_H, 0xFF3A2A10);
            LivingEntity dummy = PlantVisuals.dummy(type);
            if (dummy != null) {
                int size = (int) (26 / Math.max(1.0f, dummy.getHeight()));
                InventoryScreen.drawEntity(ctx, x + CARD_W / 2, y + 36, size, 20f, 0f, dummy);
            }
            ctx.drawCenteredTextWithShadow(textRenderer, String.valueOf(type.cost), x + CARD_W / 2, y + 40, 0xFFFFFFFF);
            int cd = FightHud.cooldowns[i];
            if (cd > 0) {
                ctx.fill(x, y, x + CARD_W, y + CARD_H * cd / 100, 0xA0000000);
            }
            if (!affordable) {
                ctx.fill(x, y, x + CARD_W, y + CARD_H, 0x70000000);
            }
            ctx.drawText(textRenderer, String.valueOf(i + 1), x + 2, y + 2, 0xFF3A2A10, false);
        }
        int shovelX = 52 + n * (CARD_W + 2) + 4;
        ctx.fill(shovelX, 6, shovelX + 32, 38, shovel ? 0xFFFFF59D : 0xFF5A3A1A);
        ctx.fill(shovelX + 14, 10, shovelX + 18, 26, 0xFF8B5A2B);
        ctx.fill(shovelX + 10, 24, shovelX + 22, 34, 0xFFB0B0B0);

        // Nombre / descripción del amigo seleccionado.
        if (selected >= 0) {
            PvzPlantType type = PvzPlantType.byId(selected);
            ctx.drawTextWithShadow(textRenderer, type.displayName + " — " + type.description, mouseX + 10, mouseY + 4, 0xFFFFFF80);
        } else if (shovel) {
            ctx.drawTextWithShadow(textRenderer, "Pala: quitar amigo", mouseX + 10, mouseY + 4, 0xFFFF8080);
        }

        // Progreso de oleadas (abajo a la derecha).
        int pw = 120, px = width - pw - 10, py = height - 20;
        ctx.fill(px - 2, py - 2, px + pw + 2, py + 10, 0xFF3A2A10);
        ctx.fill(px, py, px + pw, py + 8, 0xFF5A3A1A);
        ctx.fill(px + pw - pw * FightHud.waveProgress / 100, py, px + pw, py + 8, 0xFF8BC34A);
        if (FightHud.arcade) {
            ctx.drawTextWithShadow(textRenderer, "ESC: salir", px, py - 24, 0xFFAAAAAA);
        }
        ctx.drawTextWithShadow(textRenderer, "Oleada " + FightHud.wave + "/" + FightHud.totalWaves, px, py - 12, 0xFFFFFFFF);

        // Mensajes grandes.
        String msg = FightHud.message;
        if (!msg.isEmpty()) {
            ctx.getMatrices().push();
            ctx.getMatrices().translate(width / 2f, height / 2f - 20, 0);
            ctx.getMatrices().scale(2f, 2f, 1f);
            int tw = textRenderer.getWidth(msg);
            ctx.drawText(textRenderer, msg, -tw / 2, 0, msg.startsWith("¡UNA") || msg.startsWith("¡SUALENIDUS") ? 0xFFFF3030 : 0xFFFFFFFF, true);
            ctx.getMatrices().pop();
        }
        if (ticks < 200) {
            ctx.drawCenteredTextWithShadow(textRenderer, "Clic en un amigo (o teclas 1-8) y luego en el césped para plantarlo. Clic derecho: cancelar.",
                    width / 2, height - 36, 0xFFFFFFFF);
        }
        super.render(ctx, mouseX, mouseY, delta);
    }
}
