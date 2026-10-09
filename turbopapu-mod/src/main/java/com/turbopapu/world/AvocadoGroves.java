package com.turbopapu.world;

import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Blocks;
import net.minecraft.block.LeavesBlock;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.ChunkPos;
import net.minecraft.util.math.random.Random;

/**
 * Los aguacates cubanos crecen en el Planeta TurboPapu: arboledas de aguacateros repartidas por el mapa
 * (celdas de 160x160) con Aguacates Cubanos paseando debajo. Se plantan cuando un jugador se acerca.
 */
public final class AvocadoGroves {
    private static final int CELL = 160;
    private static final int MARGIN = 30;
    private static final float CHANCE = 0.6f;
    private static final int BUILD_DISTANCE = 90;

    private AvocadoGroves() {}

    public static void tick(ServerWorld world, ServerPlayerEntity player, TurboState state) {
        int pcx = Math.floorDiv((int) player.getX(), CELL);
        int pcz = Math.floorDiv((int) player.getZ(), CELL);
        for (int cx = pcx - 1; cx <= pcx + 1; cx++) {
            for (int cz = pcz - 1; cz <= pcz + 1; cz++) {
                long key = ChunkPos.toLong(cx, cz);
                if (state.builtGroves.contains(key)) {
                    continue;
                }
                Random random = Random.create(world.getSeed() + cx * 49157L + cz * 7907L + 77L);
                if (random.nextFloat() > CHANCE) {
                    state.builtGroves.add(key);
                    state.markDirty();
                    continue;
                }
                int x = cx * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                int z = cz * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                double lx = x - TurboState.LAIR_X, lz = z - TurboState.LAIR_Z;
                if (x * x + z * z < 60 * 60 || lx * lx + lz * lz < 120 * 120) {
                    state.builtGroves.add(key);
                    state.markDirty();
                    continue;
                }
                double dx = player.getX() - x, dz = player.getZ() - z;
                if (dx * dx + dz * dz > (double) BUILD_DISTANCE * BUILD_DISTANCE) {
                    continue;
                }
                state.builtGroves.add(key);
                state.markDirty();
                buildGrove(world, x, z, random);
            }
        }
    }

    /** 3-5 aguacateros y 2-4 Aguacates Cubanos. */
    public static void buildGrove(ServerWorld world, int x, int z, Random random) {
        int trees = 3 + random.nextInt(3);
        for (int i = 0; i < trees; i++) {
            int tx = x + random.nextInt(17) - 8, tz = z + random.nextInt(17) - 8;
            buildTree(world, tx, tz, random);
        }
        int avocados = 2 + random.nextInt(3);
        for (int i = 0; i < avocados; i++) {
            int ax = x + random.nextInt(9) - 4, az = z + random.nextInt(9) - 4;
            int y = Build.surface(world, ax, az);
            Build.spawn(world, ModEntities.AGUACATE_CUBANO, ax + 0.5, y, az + 0.5, 14);
        }
    }

    /** Aguacatero: tronco de jungla, copa redonda y aguacates (bloques de musgo) colgando. */
    private static void buildTree(ServerWorld world, int x, int z, Random random) {
        int y0 = Build.surface(world, x, z);
        int height = 5 + random.nextInt(2);
        Build.fill(world, x, y0, z, x, y0 + height - 1, z, Blocks.JUNGLE_LOG);
        int cy = y0 + height;
        var leaves = Blocks.JUNGLE_LEAVES.getDefaultState().with(LeavesBlock.PERSISTENT, true);
        for (int dx = -3; dx <= 3; dx++) {
            for (int dy = -2; dy <= 2; dy++) {
                for (int dz = -3; dz <= 3; dz++) {
                    if (dx * dx + dy * dy * 2 + dz * dz <= 11 && world.getBlockState(new net.minecraft.util.math.BlockPos(x + dx, cy + dy, z + dz)).isAir()) {
                        Build.set(world, new net.minecraft.util.math.BlockPos(x + dx, cy + dy, z + dz), leaves);
                    }
                }
            }
        }
        for (int i = 0; i < 5; i++) {
            int ax = x + random.nextInt(3) - 1, az = z + random.nextInt(3) - 1;
            if (ax == x && az == z) {
                continue;
            }
            Build.set(world, ax, cy - 2, az, Blocks.MOSS_BLOCK);
        }
    }
}
