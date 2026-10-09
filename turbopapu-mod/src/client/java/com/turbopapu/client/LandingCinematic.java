package com.turbopapu.client;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.option.Perspective;
import net.minecraft.entity.Entity;
import net.minecraft.text.Text;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

/**
 * Cinemática de aterrizaje: la cámara se pone en el suelo junto a la pista y sigue al cohete
 * mientras baja del cielo, con bandas de cine y el nombre del planeta.
 */
public final class LandingCinematic {
    private static int rocketId = -1, cameraId = -1;
    private static int ticks;
    private static boolean attached;
    private static Perspective oldPerspective;

    private LandingCinematic() {}

    public static void start(int rocket, int camera) {
        MinecraftClient client = MinecraftClient.getInstance();
        if (rocket < 0) {
            stop();
            return;
        }
        rocketId = rocket;
        cameraId = camera;
        ticks = 0;
        attached = false;
        oldPerspective = client.options.getPerspective();
    }

    public static boolean active() {
        return rocketId >= 0;
    }

    private static void stop() {
        MinecraftClient client = MinecraftClient.getInstance();
        if (rocketId >= 0 && client.player != null) {
            client.setCameraEntity(client.player);
            if (oldPerspective != null) {
                client.options.setPerspective(oldPerspective);
            }
        }
        rocketId = -1;
        cameraId = -1;
    }

    public static void tick(MinecraftClient client) {
        if (rocketId < 0 || client.world == null) {
            return;
        }
        ticks++;
        Entity rocket = client.world.getEntityById(rocketId);
        Entity cam = client.world.getEntityById(cameraId);
        if (cam == null || rocket == null) {
            if (ticks > 400) {
                stop();
            }
            return;
        }
        if (!attached && client.currentScreen == null) {
            client.options.setPerspective(Perspective.FIRST_PERSON);
            client.setCameraEntity(cam);
            attached = true;
        }
        // La cámara mira al cohete.
        Vec3d d = rocket.getPos().add(0, 2, 0).subtract(cam.getEyePos());
        double horiz = Math.sqrt(d.x * d.x + d.z * d.z);
        float yaw = (float) (MathHelper.atan2(d.z, d.x) * MathHelper.DEGREES_PER_RADIAN) - 90f;
        float pitch = (float) -(MathHelper.atan2(d.y, horiz) * MathHelper.DEGREES_PER_RADIAN);
        cam.prevYaw = cam.getYaw();
        cam.prevPitch = cam.getPitch();
        cam.setYaw(cam.getYaw() + MathHelper.wrapDegrees(yaw - cam.getYaw()) * (attached && ticks > 2 ? 0.3f : 1f));
        cam.setPitch(cam.getPitch() + (pitch - cam.getPitch()) * (attached && ticks > 2 ? 0.3f : 1f));
        if (cam instanceof net.minecraft.entity.LivingEntity living) {
            living.setHeadYaw(cam.getYaw());
            living.prevHeadYaw = cam.prevYaw;
        }
    }

    public static void renderHud(DrawContext ctx) {
        if (rocketId < 0 || !attached) {
            return;
        }
        MinecraftClient client = MinecraftClient.getInstance();
        int w = ctx.getScaledWindowWidth(), h = ctx.getScaledWindowHeight();
        int bar = h / 8;
        ctx.fill(0, 0, w, bar, 0xFF000000);
        ctx.fill(0, h - bar, w, h, 0xFF000000);
        int alpha = Math.min(255, ticks * 4);
        if (alpha > 8) {
            ctx.getMatrices().push();
            ctx.getMatrices().translate(w / 2f, h - bar / 2f - 6, 0);
            ctx.getMatrices().scale(1.6f, 1.6f, 1);
            Text title = Text.literal("PLANETA TURBOPAPU");
            ctx.drawText(client.textRenderer, title, -client.textRenderer.getWidth(title) / 2, 0, (alpha << 24) | 0xF2A33A, true);
            ctx.getMatrices().pop();
        }
    }
}
