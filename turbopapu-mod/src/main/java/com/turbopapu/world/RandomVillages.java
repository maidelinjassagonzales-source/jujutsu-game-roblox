package com.turbopapu.world;

import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.ChunkPos;
import net.minecraft.util.math.random.Random;

/**
 * Aldeas repartidas al azar por el planeta. El mapa se divide en celdas de 320x320 bloques y en la mayoría
 * hay una aldea en una posición aleatoria (siempre la misma para la misma semilla del mundo).
 * Se construyen cuando un jugador se acerca.
 */
public final class RandomVillages {
    public static final int CELL = 320;
    private static final int MARGIN = 70;
    private static final float CHANCE = 0.7f;
    private static final int BUILD_DISTANCE = 112;

    private RandomVillages() {}

    public static void tick(ServerWorld world, ServerPlayerEntity player, TurboState state) {
        int pcx = Math.floorDiv((int) player.getX(), CELL);
        int pcz = Math.floorDiv((int) player.getZ(), CELL);
        for (int cx = pcx - 1; cx <= pcx + 1; cx++) {
            for (int cz = pcz - 1; cz <= pcz + 1; cz++) {
                long key = ChunkPos.toLong(cx, cz);
                if (state.builtVillages.contains(key)) {
                    continue;
                }
                int[] center = center(world.getSeed(), cx, cz);
                if (center == null) {
                    state.builtVillages.add(key);
                    state.markDirty();
                    continue;
                }
                double dx = player.getX() - center[0];
                double dz = player.getZ() - center[1];
                if (dx * dx + dz * dz > (double) BUILD_DISTANCE * BUILD_DISTANCE) {
                    continue;
                }
                state.builtVillages.add(key);
                state.markDirty();
                Random random = Random.create(world.getSeed() ^ key * 31L);
                VillageBuilder.build(world, center[0], center[1], random, false, state.sualenidusDefeated);
                player.sendMessage(Text.translatable("message.turbopapu.village_found").formatted(Formatting.GOLD), false);
            }
        }
    }

    /** Centro de la aldea de una celda, o null si la celda no tiene aldea. */
    static int[] center(long seed, int cx, int cz) {
        Random random = Random.create(seed + cx * 341873128712L + cz * 132897987541L);
        if (random.nextFloat() > CHANCE) {
            return null;
        }
        int x = cx * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
        int z = cz * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
        // Lejos de la aldea principal (0,0) y de la guarida de Sualenidus.
        if (x * x + z * z < 200 * 200) {
            return null;
        }
        double lx = x - TurboState.LAIR_X, lz = z - TurboState.LAIR_Z;
        if (lx * lx + lz * lz < 180 * 180) {
            return null;
        }
        return new int[]{x, z};
    }
}
