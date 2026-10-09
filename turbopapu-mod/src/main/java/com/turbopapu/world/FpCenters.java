package com.turbopapu.world;

import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.DyeColor;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.ChunkPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.random.Random;

/**
 * Centros de FP de Jardinería que aparecen al azar por el mundo normal, como si fueran aldeas
 * (celdas de 512x512). Dentro está el Gordo Rubio, el profe más borde del mundo.
 */
public final class FpCenters {
    private static final int CELL = 512;
    private static final int MARGIN = 60;
    private static final float CHANCE = 0.5f;
    private static final int BUILD_DISTANCE = 110;

    private FpCenters() {}

    public static void tick(ServerWorld world, ServerPlayerEntity player, TurboState state) {
        int pcx = Math.floorDiv((int) player.getX(), CELL);
        int pcz = Math.floorDiv((int) player.getZ(), CELL);
        for (int cx = pcx - 1; cx <= pcx + 1; cx++) {
            for (int cz = pcz - 1; cz <= pcz + 1; cz++) {
                long key = ChunkPos.toLong(cx, cz);
                if (state.builtFpCenters.contains(key)) {
                    continue;
                }
                Random random = Random.create(world.getSeed() + cx * 92821L + cz * 68917L + 5L);
                if (random.nextFloat() > CHANCE) {
                    state.builtFpCenters.add(key);
                    state.markDirty();
                    continue;
                }
                int x = cx * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                int z = cz * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                double dx = player.getX() - x, dz = player.getZ() - z;
                if (dx * dx + dz * dz > (double) BUILD_DISTANCE * BUILD_DISTANCE) {
                    continue;
                }
                state.builtFpCenters.add(key);
                state.markDirty();
                build(world, x, z, random);
                player.sendMessage(Text.literal("Has encontrado un Centro de FP de Jardinería...").formatted(Formatting.GREEN), false);
            }
        }
    }

    /** Edificio de ladrillo con aula, invernadero de cristal y huerto delante. Mira al sur (+z). */
    public static void build(ServerWorld world, int cx, int cz, Random random) {
        int y0 = Build.surface(world, cx, cz);
        int x1 = cx - 8, x2 = cx + 8, z1 = cz - 6, z2 = cz + 6;
        // Cimientos y limpieza.
        Build.fill(world, x1 - 1, y0 - 4, z1 - 1, x2 + 1, y0 - 1, z2 + 9, Blocks.DIRT);
        Build.fill(world, x1 - 1, y0 - 1, z1 - 1, x2 + 1, y0 - 1, z2 + 9, Blocks.GRASS_BLOCK);
        Build.clear(world, x1 - 1, y0, z1 - 1, x2 + 1, y0 + 9, z2 + 9);
        // Aula: ladrillo con suelo de madera.
        Build.fill(world, x1, y0 - 1, z1, cx, y0 - 1, z2, Blocks.OAK_PLANKS);
        Build.fill(world, x1, y0, z1, cx, y0 + 4, z2, Blocks.BRICKS);
        Build.clear(world, x1 + 1, y0, z1 + 1, cx - 1, y0 + 3, z2 - 1);
        Build.fill(world, x1, y0 + 5, z1, cx, y0 + 5, z2, Blocks.SMOOTH_STONE_SLAB);
        for (int x = x1 + 2; x < cx - 1; x += 3) {
            Build.set(world, x, y0 + 2, z1, Blocks.GLASS_PANE);
            Build.set(world, x, y0 + 2, z2, Blocks.GLASS_PANE);
        }
        Build.clear(world, x1 + 3, y0, z2, x1 + 4, y0 + 2, z2);
        Build.set(world, x1 + 4, y0 + 4, z1 + 3, Blocks.GLOWSTONE);
        Build.set(world, x1 + 4, y0 + 4, z2 - 3, Blocks.GLOWSTONE);
        // Pupitres, pizarra y la mesa del profe.
        for (int x = x1 + 2; x < cx - 1; x += 2) {
            for (int z = z1 + 2; z <= z1 + 6; z += 2) {
                Build.set(world, x, y0, z, Blocks.SPRUCE_TRAPDOOR);
            }
        }
        Build.fill(world, x1 + 2, y0 + 1, z1 + 1, cx - 2, y0 + 2, z1 + 1, Blocks.BLACK_CONCRETE);
        Build.fill(world, x1 + 3, y0, z1 + 9, x1 + 5, y0, z1 + 9, Blocks.DARK_OAK_PLANKS);
        Build.set(world, x1 + 3, y0 + 1, z1 + 9, Blocks.POTTED_CACTUS);
        // Invernadero de cristal.
        Build.fill(world, cx + 1, y0 - 1, z1, x2, y0 - 1, z2, Blocks.FARMLAND);
        Build.fill(world, cx + 1, y0, z1, x2, y0 + 4, z2, Blocks.GLASS);
        Build.clear(world, cx + 1, y0, z1 + 1, x2 - 1, y0 + 3, z2 - 1);
        Build.fill(world, cx, y0, z1 + 5, cx, y0 + 1, z1 + 6, Blocks.AIR);
        Block[] plants = {Blocks.POPPY, Blocks.DANDELION, Blocks.BLUE_ORCHID, Blocks.ALLIUM, Blocks.CORNFLOWER, Blocks.OXEYE_DAISY, Blocks.FERN};
        for (int x = cx + 2; x < x2; x++) {
            for (int z = z1 + 1; z < z2; z++) {
                if ((z - z1) % 3 == 0) {
                    Build.set(world, x, y0 - 1, z, Blocks.WATER);
                } else {
                    Build.set(world, x, y0, z, plants[random.nextInt(plants.length)]);
                }
            }
        }
        // Huerto de fuera, compostadores y el cartel.
        for (int x = x1; x <= x2; x += 2) {
            Build.set(world, x, y0 - 1, z2 + 3, Blocks.FARMLAND);
            Build.set(world, x, y0, z2 + 3, Blocks.WHEAT);
        }
        Build.set(world, x1 + 1, y0, z2 + 6, Blocks.COMPOSTER);
        Build.set(world, x1 + 2, y0, z2 + 6, Blocks.COMPOSTER);
        Build.set(world, x1 + 8, y0, z2 + 1, Blocks.OAK_FENCE);
        FriendBuilds.sign(world, new BlockPos(x1 + 6, y0 + 3, z2 + 1), Direction.SOUTH, DyeColor.GREEN,
                "CENTRO DE FP", "JARDINERÍA", "Grado Medio", "Prohibido llorar");
        // El Gordo Rubio, en su mesa.
        Build.spawn(world, ModEntities.GORDO_RUBIO, x1 + 4.5, y0, z1 + 8.5, 4);
    }
}
