package com.turbopapu.world;

import com.turbopapu.registry.ModDimensions;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.registry.tag.BiomeTags;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;

/** Lógica de la historia que corre cada segundo en el servidor. */
public final class TurboEvents {
    /** El meteorito cae cuando llevas este tiempo jugando (2 minutos). */
    public static final int METEOR_DELAY_TICKS = 20 * 120;

    private static int ticks;

    private TurboEvents() {}

    public static void register() {
        ServerTickEvents.END_SERVER_TICK.register(TurboEvents::onTick);
    }

    private static void onTick(MinecraftServer server) {
        if (++ticks % 20 != 0) {
            return;
        }
        TurboState state = TurboState.get(server);
        ServerWorld overworld = server.getOverworld();

        for (ServerPlayerEntity player : overworld.getPlayers()) {
            if (player.isSpectator()) {
                continue;
            }
            if (!state.meteorFallen && !state.meteorIncoming && player.age > METEOR_DELAY_TICKS
                    && overworld.isSkyVisible(player.getBlockPos().up())) {
                MeteorEvent.launch(overworld, player);
            }
            if (state.meteorFallen && holdsHutCompass(player)) {
                showHutDistance(player, state);
            }
            if (state.meteorFallen && !state.hutBuilt && near(player, state.hutX, state.hutZ, 80)) {
                OverworldBuilds.buildAlphatempHut(overworld, state.hutX, state.hutZ);
                state.hutBuilt = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.williamSpawned && ticks % 100 == 0
                    && overworld.getBiome(player.getBlockPos()).isIn(BiomeTags.IS_OCEAN)
                    && player.getY() > overworld.getSeaLevel() - 4) {
                if (OverworldBuilds.spawnWilliamRaft(overworld, player)) {
                    state.williamSpawned = true;
                    state.markDirty();
                }
            }
        }

        ServerWorld planet = server.getWorld(ModDimensions.PLANETA);
        if (planet != null) {
            for (ServerPlayerEntity player : planet.getPlayers()) {
                if (!state.lairBuilt && near(player, TurboState.LAIR_X, TurboState.LAIR_Z, 96)) {
                    PlanetBuilds.buildLair(planet, state);
                }
                RandomVillages.tick(planet, player, state);
                // Gravedad lunar: se salta más alto.
                if (!player.isSpectator()) {
                    player.addStatusEffect(new StatusEffectInstance(StatusEffects.JUMP_BOOST, 50, 1, true, false, true));
                }
            }
        }
    }

    private static boolean holdsHutCompass(ServerPlayerEntity player) {
        for (net.minecraft.item.ItemStack stack : new net.minecraft.item.ItemStack[]{player.getMainHandStack(), player.getOffHandStack()}) {
            if (stack.hasNbt() && stack.getNbt().getBoolean("TurboPapuChoza")) {
                return true;
            }
        }
        return false;
    }

    /** Con la brújula en la mano: distancia y dirección a la choza de Alphatemp encima de la barra de objetos. */
    private static void showHutDistance(ServerPlayerEntity player, TurboState state) {
        double dx = state.hutX + 0.5 - player.getX();
        double dz = state.hutZ + 0.5 - player.getZ();
        int dist = (int) Math.sqrt(dx * dx + dz * dz);
        if (dist < 12) {
            player.sendMessage(net.minecraft.text.Text.literal("¡Has llegado a la choza de Alphatemp!")
                    .formatted(net.minecraft.util.Formatting.AQUA), true);
            return;
        }
        String[] dirs = {"sur", "suroeste", "oeste", "noroeste", "norte", "noreste", "este", "sureste"};
        double angle = Math.toDegrees(Math.atan2(-dx, dz));
        String dir = dirs[Math.floorMod((int) Math.round(angle / 45.0), 8)];
        player.sendMessage(net.minecraft.text.Text.literal("Choza de Alphatemp: " + dist + " bloques al " + dir
                + "  (X " + state.hutX + ", Z " + state.hutZ + ")").formatted(net.minecraft.util.Formatting.AQUA), true);
    }

    private static boolean near(ServerPlayerEntity player, int x, int z, int dist) {
        double dx = player.getX() - x;
        double dz = player.getZ() - z;
        return dx * dx + dz * dz < (double) dist * dist;
    }
}
