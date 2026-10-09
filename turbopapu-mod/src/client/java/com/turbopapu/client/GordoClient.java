package com.turbopapu.client;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModEffects;
import net.fabricmc.fabric.api.client.keybinding.v1.KeyBindingHelper;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.option.KeyBinding;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.client.util.InputUtil;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.Vec3d;
import org.lwjgl.glfw.GLFW;

/** Cosas del Gordo Pañales en el cliente: el screamer, el deslizamiento con mantequilla y la tecla del pañal. */
public final class GordoClient {
    private static final Identifier SCREAMER = TurboPapuMod.id("textures/gui/screamer_gordo.png");
    private static final int SCREAMER_TICKS = 50;
    private static int screamerTicks;
    private static KeyBinding poopKey;

    private GordoClient() {}

    public static void init() {
        poopKey = KeyBindingHelper.registerKeyBinding(new KeyBinding("key.turbopapu.cagarse", InputUtil.Type.KEYSYM,
                GLFW.GLFW_KEY_G, "category.turbopapu"));
    }

    public static void screamer() {
        screamerTicks = SCREAMER_TICKS;
        MinecraftClient client = MinecraftClient.getInstance();
        client.getSoundManager().play(PositionedSoundInstance.master(SoundEvents.ENTITY_GHAST_SCREAM, 0.5f, 1.5f));
        client.getSoundManager().play(PositionedSoundInstance.master(SoundEvents.ENTITY_WARDEN_ROAR, 0.8f, 1.5f));
    }

    public static void tick(MinecraftClient client) {
        if (screamerTicks > 0) {
            screamerTicks--;
        }
        while (poopKey.wasPressed()) {
            ClientPlayNetworking.send(ModPackets.CAGARSE, PacketByteBufs.empty());
        }
        slide(client);
    }

    /** Con mantequilla en los pies casi no hay rozamiento y aceleras muchísimo. */
    private static void slide(MinecraftClient client) {
        var player = client.player;
        if (player == null || !player.hasStatusEffect(ModEffects.UNTADO) || player.isSpectator() || player.getAbilities().flying
                || player.isTouchingWater() || player.hasVehicle()) {
            return;
        }
        Vec3d v = player.getVelocity();
        float forward = player.input.movementForward, side = player.input.movementSideways;
        if (player.isOnGround()) {
            double ax = 0, az = 0;
            if (forward != 0 || side != 0) {
                Vec3d look = Vec3d.fromPolar(0, player.getYaw());
                Vec3d right = Vec3d.fromPolar(0, player.getYaw() + 90);
                Vec3d push = look.multiply(forward).add(right.multiply(side)).normalize().multiply(player.isSprinting() ? 0.09 : 0.06);
                ax = push.x;
                az = push.z;
            }
            // Mantiene el impulso: el suelo resbala como si fuera hielo con mantequilla.
            double vx = v.x * 1.06 + ax, vz = v.z * 1.06 + az;
            double speed = Math.sqrt(vx * vx + vz * vz), max = 1.3;
            if (speed > max) {
                vx = vx / speed * max;
                vz = vz / speed * max;
            }
            player.setVelocity(vx, v.y, vz);
            if (speed > 0.3 && player.age % 3 == 0) {
                player.getWorld().addParticle(net.minecraft.particle.ParticleTypes.FALLING_HONEY, player.getX(), player.getY() + 0.1, player.getZ(), 0, 0, 0);
            }
        }
    }

    public static void render(DrawContext ctx) {
        if (screamerTicks <= 0) {
            return;
        }
        MinecraftClient client = MinecraftClient.getInstance();
        int w = ctx.getScaledWindowWidth(), h = ctx.getScaledWindowHeight();
        ctx.fill(0, 0, w, h, 0xFF000000);
        int t = SCREAMER_TICKS - screamerTicks;
        float grow = Math.min(1f, 0.55f + t * 0.06f);
        int size = (int) (Math.max(w, h) * 1.1f * grow);
        int shake = 14;
        int ox = client.world == null ? 0 : client.world.random.nextInt(shake * 2 + 1) - shake;
        int oy = client.world == null ? 0 : client.world.random.nextInt(shake * 2 + 1) - shake;
        ctx.drawTexture(SCREAMER, (w - size) / 2 + ox, (h - size) / 2 + oy, 0, 0, size, size, size, size);
        if ((t / 3) % 2 == 0) {
            ctx.fill(0, 0, w, h, 0x55FF0000);
        }
    }
}
