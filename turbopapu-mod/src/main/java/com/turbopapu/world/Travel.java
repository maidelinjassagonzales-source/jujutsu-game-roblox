package com.turbopapu.world;

import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModItems;
import net.minecraft.item.ItemStack;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;

/** Viajes en cohete entre el Overworld y el Planeta TurboPapu. */
public final class Travel {
    private Travel() {}

    public static void travel(ServerPlayerEntity player, ServerWorld from) {
        if (from.getRegistryKey() == ModDimensions.PLANETA) {
            toOverworld(player);
        } else {
            toPlanet(player);
        }
    }

    public static void toPlanet(ServerPlayerEntity player) {
        ServerWorld planet = player.getServer().getWorld(ModDimensions.PLANETA);
        if (planet == null) {
            player.sendMessage(Text.literal("¡No se encuentra la dimensión del planeta! (¿datapack desactivado?)").formatted(Formatting.RED), false);
            return;
        }
        TurboState state = TurboState.get(player.getServer());
        boolean firstTime = !state.villageBuilt;
        if (firstTime) {
            PlanetBuilds.buildVillage(planet, state);
        }
        ModPackets.showTravel(player, true);
        player.fallDistance = 0;
        player.teleport(planet, 0.5, state.villageY + 1, 6.5, 180f, 0f);
        giveRocketBack(player);
        player.sendMessage(Text.translatable("message.turbopapu.arrived").formatted(Formatting.GOLD, Formatting.BOLD), false);
        if (firstTime) {
            player.sendMessage(Text.translatable("message.turbopapu.welcome").formatted(Formatting.YELLOW), false);
        }
    }

    public static void toOverworld(ServerPlayerEntity player) {
        ServerWorld overworld = player.getServer().getWorld(World.OVERWORLD);
        BlockPos spawn = player.getSpawnPointPosition() != null && player.getSpawnPointDimension() == World.OVERWORLD
                ? player.getSpawnPointPosition() : overworld.getSpawnPos();
        int y = Build.surface(overworld, spawn.getX(), spawn.getZ());
        ModPackets.showTravel(player, false);
        player.fallDistance = 0;
        player.teleport(overworld, spawn.getX() + 0.5, y, spawn.getZ() + 0.5, player.getYaw(), 0f);
        giveRocketBack(player);
    }

    private static void giveRocketBack(ServerPlayerEntity player) {
        if (!player.giveItemStack(new ItemStack(ModItems.COHETE))) {
            player.dropItem(new ItemStack(ModItems.COHETE), false);
        }
    }
}
