package com.turbopapu.world;

import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.entity.EquipmentSlot;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.DyeColor;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.random.Random;

/** El Mundo de Caca: llanura marrón con montoncitos de caca. Aquí vive Verity de Caca, que te deja volver a casa. */
public final class PoopWorld {
    /** Altura del suelo del mundo plano (bedrock + 3 terracota + barro). */
    private static final int GROUND = 5;

    private PoopWorld() {}

    public static void bouncedTooMuch(ServerPlayerEntity player) {
        if (!GordoEvents.isPooped(player.getEquippedStack(EquipmentSlot.LEGS))
                || player.getWorld().getRegistryKey() == ModDimensions.MUNDO_CACA) {
            return;
        }
        ServerWorld poop = player.getServer().getWorld(ModDimensions.MUNDO_CACA);
        if (poop == null) {
            return;
        }
        TurboState state = TurboState.get(player.getServer());
        if (!state.poopWorldBuilt) {
            build(poop);
            state.poopWorldBuilt = true;
            state.markDirty();
        }
        player.getWorld().playSound(null, player.getBlockPos(), SoundEvents.ENTITY_SLIME_SQUISH, SoundCategory.PLAYERS, 2f, 0.4f);
        player.teleport(poop, 0.5, GROUND + 6, 6.5, 180, 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.NAUSEA, 120, 0, false, false));
        player.sendMessage(Text.literal("¡Has rebotado tanto que has atravesado el suelo hasta el MUNDO DE CACA!")
                .formatted(Formatting.GOLD, Formatting.BOLD), false);
    }

    /** Verity de Caca te devuelve a casa (a tu cama o al spawn del mundo). */
    public static void leave(ServerPlayerEntity player) {
        if (player.getWorld().getRegistryKey() != ModDimensions.MUNDO_CACA) {
            return;
        }
        ServerWorld overworld = player.getServer().getOverworld();
        BlockPos target = player.getSpawnPointPosition() != null && player.getSpawnPointDimension() == net.minecraft.world.World.OVERWORLD
                ? player.getSpawnPointPosition().up() : overworld.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES, overworld.getSpawnPos());
        player.teleport(overworld, target.getX() + 0.5, target.getY() + 0.5, target.getZ() + 0.5, player.getYaw(), 0);
        overworld.playSound(null, player.getBlockPos(), SoundEvents.BLOCK_HONEY_BLOCK_SLIDE, SoundCategory.PLAYERS, 1.5f, 0.6f);
        player.sendMessage(Text.literal("Verity de Caca te ha mandado de vuelta. Hueles un poco...").formatted(Formatting.YELLOW), false);
    }

    private static void build(ServerWorld world) {
        Random random = Random.create(4242L);
        // Plaza de Verity.
        for (int x = -6; x <= 6; x++) {
            for (int z = -6; z <= 6; z++) {
                if (x * x + z * z <= 36) {
                    Build.set(world, x, GROUND - 1, z, (x + z) % 2 == 0 ? Blocks.BROWN_TERRACOTTA : Blocks.BROWN_CONCRETE);
                }
            }
        }
        FriendBuilds.sign(world, new BlockPos(0, GROUND + 1, 7), Direction.SOUTH, DyeColor.BROWN, "MUNDO DE CACA", "Población: 1", "(Verity)", "Huele regular");
        Build.set(world, 0, GROUND, 7, Blocks.BROWN_CONCRETE);
        Build.spawn(world, ModEntities.VERITY_CACA, 0.5, GROUND, 0.5, 10);
        // Montones de caca (con su remolino) por todas partes.
        for (int i = 0; i < 40; i++) {
            int x = random.nextInt(121) - 60, z = random.nextInt(121) - 60;
            if (x * x + z * z < 100) {
                continue;
            }
            mound(world, x, z, 1 + random.nextInt(3));
        }
    }

    private static void mound(ServerWorld world, int x, int z, int size) {
        Block[] layers = {Blocks.BROWN_TERRACOTTA, Blocks.BROWN_CONCRETE, Blocks.BROWN_TERRACOTTA, Blocks.BROWN_CONCRETE};
        for (int level = 0; level <= size; level++) {
            int r = size - level;
            for (int dx = -r; dx <= r; dx++) {
                for (int dz = -r; dz <= r; dz++) {
                    if (dx * dx + dz * dz <= r * r + 1) {
                        Build.set(world, x + dx, GROUND + level, z + dz, layers[level % layers.length]);
                    }
                }
            }
        }
        Build.set(world, x, GROUND + size + 1, z, Blocks.BROWN_CONCRETE);
    }
}
