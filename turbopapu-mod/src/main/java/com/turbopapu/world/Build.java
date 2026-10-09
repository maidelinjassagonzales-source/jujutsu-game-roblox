package com.turbopapu.world;

import net.minecraft.block.Block;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.Heightmap;

/** Pequeñas utilidades para construir estructuras bloque a bloque. */
public final class Build {
    private Build() {}

    public static void set(ServerWorld world, BlockPos pos, BlockState state) {
        world.setBlockState(pos, state, Block.NOTIFY_LISTENERS | Block.FORCE_STATE);
    }

    public static void set(ServerWorld world, int x, int y, int z, Block block) {
        set(world, new BlockPos(x, y, z), block.getDefaultState());
    }

    public static void fill(ServerWorld world, int x1, int y1, int z1, int x2, int y2, int z2, BlockState state) {
        for (int x = Math.min(x1, x2); x <= Math.max(x1, x2); x++) {
            for (int y = Math.min(y1, y2); y <= Math.max(y1, y2); y++) {
                for (int z = Math.min(z1, z2); z <= Math.max(z1, z2); z++) {
                    set(world, new BlockPos(x, y, z), state);
                }
            }
        }
    }

    public static void fill(ServerWorld world, int x1, int y1, int z1, int x2, int y2, int z2, Block block) {
        fill(world, x1, y1, z1, x2, y2, z2, block.getDefaultState());
    }

    public static void clear(ServerWorld world, int x1, int y1, int z1, int x2, int y2, int z2) {
        fill(world, x1, y1, z1, x2, y2, z2, Blocks.AIR);
    }

    /** Altura del suelo (primer bloque libre) en x,z. */
    public static int surface(ServerWorld world, int x, int z) {
        return world.getTopY(Heightmap.Type.MOTION_BLOCKING_NO_LEAVES, x, z);
    }

    public static <T extends MobEntity> T spawn(ServerWorld world, EntityType<T> type, double x, double y, double z, int homeRadius) {
        T mob = type.create(world);
        if (mob == null) {
            return null;
        }
        mob.refreshPositionAndAngles(x, y, z, world.getRandom().nextFloat() * 360f, 0);
        mob.setPersistent();
        if (mob instanceof net.minecraft.entity.mob.PathAwareEntity aware && homeRadius > 0) {
            aware.setPositionTarget(BlockPos.ofFloored(x, y, z), homeRadius);
        }
        world.spawnEntity(mob);
        return mob;
    }
}
