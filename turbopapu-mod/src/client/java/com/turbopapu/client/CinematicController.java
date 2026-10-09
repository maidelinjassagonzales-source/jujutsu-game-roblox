package com.turbopapu.client;

import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.network.ClientPlayerEntity;
import net.minecraft.entity.Entity;
import net.minecraft.text.Text;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

/**
 * Cinemática de la caída del meteorito: bandas negras de cine, la cámara sigue al meteorito
 * y al impactar la pantalla tiembla.
 */
public final class CinematicController {
    private static int entityId = -1;
    private static int ticksLeft;
    private static int shake;
    private static Vec3d lastPos;

    private CinematicController() {}

    public static void start(int id, int ticks) {
        entityId = id;
        ticksLeft = ticks;
        shake = 0;
        lastPos = null;
    }

    public static boolean isActive() {
        return ticksLeft > 0;
    }

    public static void tick(MinecraftClient client) {
        if (ticksLeft <= 0 || client.player == null || client.world == null) {
            return;
        }
        ticksLeft--;
        ClientPlayerEntity player = client.player;
        Entity meteor = client.world.getEntityById(entityId);
        if (meteor != null && !meteor.isInvisible()) {
            lastPos = meteor.getPos().add(0, 2, 0);
        } else if (lastPos != null && shake == 0) {
            shake = 30; // ¡Impacto!
        }
        if (lastPos != null) {
            Vec3d eye = player.getEyePos();
            Vec3d d = lastPos.subtract(eye);
            double horiz = Math.sqrt(d.x * d.x + d.z * d.z);
            float targetYaw = (float) (MathHelper.atan2(d.z, d.x) * MathHelper.DEGREES_PER_RADIAN) - 90f;
            float targetPitch = (float) -(MathHelper.atan2(d.y, horiz) * MathHelper.DEGREES_PER_RADIAN);
            float yaw = player.getYaw() + MathHelper.wrapDegrees(targetYaw - player.getYaw()) * 0.25f;
            float pitch = player.getPitch() + (targetPitch - player.getPitch()) * 0.25f;
            if (shake > 0) {
                shake--;
                float strength = shake / 30f * 4f;
                yaw += (player.getRandom().nextFloat() - 0.5f) * strength;
                pitch += (player.getRandom().nextFloat() - 0.5f) * strength;
            }
            player.setYaw(yaw);
            player.setPitch(MathHelper.clamp(pitch, -90f, 90f));
        }
    }

    public static void renderHud(DrawContext ctx, float tickDelta) {
        if (ticksLeft <= 0) {
            return;
        }
        MinecraftClient client = MinecraftClient.getInstance();
        int w = ctx.getScaledWindowWidth();
        int h = ctx.getScaledWindowHeight();
        int bar = Math.min(h / 8, Math.min(ticksLeft, 20) * 2);
        ctx.fill(0, 0, w, bar, 0xFF000000);
        ctx.fill(0, h - bar, w, h, 0xFF000000);
        Text caption = shake > 0 || (lastPos != null && client.world != null && client.world.getEntityById(entityId) == null)
                ? Text.translatable("cinematic.turbopapu.impact")
                : Text.translatable("cinematic.turbopapu.falling");
        ctx.drawCenteredTextWithShadow(client.textRenderer, caption, w / 2, h - bar / 2 - 4, 0xFFF2A33A);
    }
}
