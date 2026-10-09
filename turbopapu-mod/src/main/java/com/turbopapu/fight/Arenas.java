package com.turbopapu.fight;

import com.turbopapu.world.Build;
import com.turbopapu.world.TurboState;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.block.ChainBlock;
import net.minecraft.block.StairsBlock;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;

/** Escenarios de la pelea final: el ring de boxeo, el mapa de Valorant y el jardín de Plantas vs Zombies. */
public final class Arenas {
    // Mapa de Valorant (flotando en el cielo del planeta).
    public static final int VAL_X = TurboState.LAIR_X + 1200;
    public static final int VAL_Y = 160;
    public static final int VAL_Z = TurboState.LAIR_Z;

    // Jardín de Plantas vs Zombies.
    public static final int LAWN_X = TurboState.LAIR_X + 2400;
    public static final int LAWN_Y = 170;
    public static final int LAWN_Z = TurboState.LAIR_Z;
    public static final int COLS = 9;
    public static final int ROWS = 5;
    public static final int CELL = 2;

    private Arenas() {}

    /** Altura del suelo de la guarida (encima del hormigón morado). */
    public static int lairFloor(ServerWorld world) {
        int cx = TurboState.LAIR_X, cz = TurboState.LAIR_Z;
        int top = Build.surface(world, cx, cz);
        for (int y = top; y > world.getBottomY(); y--) {
            if (world.getBlockState(new BlockPos(cx, y, cz)).isOf(Blocks.PURPLE_CONCRETE)) {
                return y + 1;
            }
        }
        return top;
    }

    /**
     * Ring de boxeo en el centro de la guarida: lona blanca elevada, postes rojo y azul en las esquinas,
     * cuerdas, escalera de entrada al sur y focos en el techo. Devuelve la altura de la lona (donde se pisa).
     */
    public static int buildRing(ServerWorld world, int floorY) {
        int cx = TurboState.LAIR_X, cz = TurboState.LAIR_Z;
        int r = 5;
        Build.clear(world, cx - r, floorY, cz - r, cx + r, floorY + 7, cz + r);
        for (int x = -r; x <= r; x++) {
            for (int z = -r; z <= r; z++) {
                boolean edge = Math.abs(x) == r || Math.abs(z) == r;
                Build.set(world, cx + x, floorY, cz + z, edge ? Blocks.BLUE_CONCRETE : (Math.abs(x) + Math.abs(z) < 2 ? Blocks.YELLOW_CONCRETE : Blocks.WHITE_CONCRETE));
            }
        }
        int[][] corners = {{-r, -r}, {r, -r}, {-r, r}, {r, r}};
        Block[] colors = {Blocks.RED_CONCRETE, Blocks.BLUE_CONCRETE, Blocks.BLUE_CONCRETE, Blocks.RED_CONCRETE};
        for (int i = 0; i < 4; i++) {
            Build.fill(world, cx + corners[i][0], floorY + 1, cz + corners[i][1], cx + corners[i][0], floorY + 3, cz + corners[i][1], colors[i]);
        }
        for (int y = floorY + 2; y <= floorY + 3; y++) {
            for (int i = -r + 1; i <= r - 1; i++) {
                Build.set(world, new BlockPos(cx + i, y, cz - r), Blocks.CHAIN.getDefaultState().with(ChainBlock.AXIS, Direction.Axis.X));
                if (i != 0) {
                    Build.set(world, new BlockPos(cx + i, y, cz + r), Blocks.CHAIN.getDefaultState().with(ChainBlock.AXIS, Direction.Axis.X));
                }
                Build.set(world, new BlockPos(cx - r, y, cz + i), Blocks.CHAIN.getDefaultState().with(ChainBlock.AXIS, Direction.Axis.Z));
                Build.set(world, new BlockPos(cx + r, y, cz + i), Blocks.CHAIN.getDefaultState().with(ChainBlock.AXIS, Direction.Axis.Z));
            }
        }
        // Escalera de entrada.
        Build.set(world, new BlockPos(cx, floorY, cz + r + 1), Blocks.QUARTZ_STAIRS.getDefaultState().with(StairsBlock.FACING, Direction.NORTH));
        // Focos.
        for (int[] c : corners) {
            Build.set(world, cx + c[0], floorY + 9, cz + c[1], Blocks.SEA_LANTERN);
        }
        Build.set(world, cx, floorY + 10, cz, Blocks.SEA_LANTERN);
        return floorY + 1;
    }

    public static boolean insideRing(double x, double y, double z, int standY) {
        return Math.abs(x - (TurboState.LAIR_X + 0.5)) < 5.2 && Math.abs(z - (TurboState.LAIR_Z + 0.5)) < 5.2 && y >= standY - 0.5;
    }

    /**
     * Mapa estilo Valorant: suelo de arenisca, muros con pasillos, cajas de cobertura y el site A con la Spike.
     * Sualenidus sale por el oeste y tiene que llegar a la Spike (este) para desactivarla.
     */
    public static void buildValorant(ServerWorld world) {
        int x0 = VAL_X, y0 = VAL_Y, z0 = VAL_Z;
        int rx = 24, rz = 15;
        for (int x = -rx; x <= rx; x++) {
            for (int z = -rz; z <= rz; z++) {
                boolean edge = Math.abs(x) == rx || Math.abs(z) == rz;
                Build.set(world, x0 + x, y0 - 2, z0 + z, Blocks.SANDSTONE);
                Block floor = ((x / 3 + z / 3) % 2 == 0) ? Blocks.SMOOTH_SANDSTONE : Blocks.CUT_SANDSTONE;
                Build.set(world, x0 + x, y0 - 1, z0 + z, floor);
                Build.clear(world, x0 + x, y0, z0 + z, x0 + x, y0 + 8, z0 + z);
                if (edge) {
                    Build.fill(world, x0 + x, y0, z0 + z, x0 + x, y0 + 5, z0 + z, Blocks.SMOOTH_SANDSTONE);
                    Build.set(world, x0 + x, y0 + 5, z0 + z, (x + z) % 6 == 0 ? Blocks.GLOWSTONE : Blocks.CUT_SANDSTONE);
                }
            }
        }
        // Muros centrales con tres pasillos (A largo, mid, A corto).
        for (int z = -rz; z <= rz; z++) {
            boolean door = Math.abs(z - 9) <= 1 || Math.abs(z) <= 1 || Math.abs(z + 9) <= 1;
            if (!door) {
                Build.fill(world, x0 - 4, y0, z0 + z, x0 - 4, y0 + 4, z0 + z, Blocks.WHITE_TERRACOTTA);
                Build.fill(world, x0 + 5, y0, z0 + z, x0 + 5, y0 + 4, z0 + z, Blocks.TERRACOTTA);
            }
        }
        // Cajas de cobertura.
        int[][] boxes = {{-14, -6}, {-12, 7}, {-8, 0}, {1, -6}, {1, 6}, {9, -4}, {10, 5}, {15, -9}, {17, 9}, {19, 0}};
        for (int[] b : boxes) {
            Build.fill(world, x0 + b[0], y0, z0 + b[1], x0 + b[0] + 1, y0 + 1, z0 + b[1] + 1, Blocks.STRIPPED_BIRCH_WOOD);
            Build.set(world, x0 + b[0], y0 + 2, z0 + b[1], Blocks.BARREL);
        }
        // Site A: suelo amarillo con la letra A.
        int sx = x0 + 13, sz = z0;
        for (int x = -3; x <= 3; x++) {
            for (int z = -3; z <= 3; z++) {
                Build.set(world, sx + x, y0 - 1, sz + z, Blocks.YELLOW_TERRACOTTA);
            }
        }
        int[][] letterA = {{-1, -2}, {0, -2}, {1, -2}, {-2, -1}, {2, -1}, {-2, 0}, {-1, 0}, {0, 0}, {1, 0}, {2, 0}, {-2, 1}, {2, 1}, {-2, 2}, {2, 2}};
        for (int[] p : letterA) {
            Build.set(world, sx + p[1], y0 - 1, sz + p[0], Blocks.RED_CONCRETE);
        }
        // Spawns.
        Build.fill(world, x0 - rx + 1, y0 - 1, z0 - 2, x0 - rx + 3, y0 - 1, z0 + 2, Blocks.LIGHT_BLUE_CONCRETE);
        Build.fill(world, x0 + rx - 3, y0 - 1, z0 - 2, x0 + rx - 1, y0 - 1, z0 + 2, Blocks.RED_TERRACOTTA);
    }

    public static BlockPos valSpike() {
        return new BlockPos(VAL_X + 13, VAL_Y, VAL_Z + 1);
    }

    public static BlockPos valPlayerSpawn() {
        return new BlockPos(VAL_X + 19, VAL_Y, VAL_Z + 6);
    }

    public static BlockPos valBossSpawn() {
        return new BlockPos(VAL_X - 21, VAL_Y, VAL_Z);
    }

    /**
     * Jardín de Plantas vs Zombies: césped a cuadros (9x5 casillas de 2x2), la casa a la izquierda con
     * los cortacéspedes delante, la calle a la derecha por donde llegan los Sualems y setos alrededor.
     */
    public static void buildLawn(ServerWorld world) {
        int lx = LAWN_X, ly = LAWN_Y, lz = LAWN_Z;
        int w = COLS * CELL, h = ROWS * CELL;
        for (int x = lx - 14; x <= lx + w + 12; x++) {
            for (int z = lz - 4; z <= lz + h + 4; z++) {
                Build.set(world, x, ly - 3, z, Blocks.DIRT);
                Build.set(world, x, ly - 2, z, Blocks.DIRT);
                Build.set(world, x, ly - 1, z, Blocks.GRASS_BLOCK);
                Build.clear(world, x, ly, z, x, ly + 10, z);
            }
        }
        // Césped a cuadros claro/oscuro.
        for (int c = 0; c < COLS; c++) {
            for (int r = 0; r < ROWS; r++) {
                Block b = (c + r) % 2 == 0 ? Blocks.LIME_CONCRETE : Blocks.GREEN_CONCRETE;
                Build.fill(world, lx + c * CELL, ly - 1, lz + r * CELL, lx + c * CELL + CELL - 1, ly - 1, lz + r * CELL + CELL - 1, b);
            }
        }
        // Calle a la derecha.
        for (int x = lx + w + 2; x <= lx + w + 12; x++) {
            for (int z = lz - 4; z <= lz + h + 4; z++) {
                Build.set(world, x, ly - 1, z, (x == lx + w + 7 && z % 3 != 0) ? Blocks.WHITE_CONCRETE : Blocks.GRAY_CONCRETE);
            }
        }
        Build.fill(world, lx + w, ly - 1, lz - 4, lx + w + 1, ly - 1, lz + h + 4, Blocks.SMOOTH_STONE);
        // Setos arriba y abajo.
        Build.fill(world, lx - 2, ly, lz - 2, lx + w + 1, ly, lz - 2, Blocks.OAK_LEAVES);
        Build.fill(world, lx - 2, ly, lz + h + 1, lx + w + 1, ly, lz + h + 1, Blocks.OAK_FENCE);
        // Casa a la izquierda.
        int hx = lx - 12;
        Build.fill(world, hx, ly, lz - 2, lx - 4, ly + 4, lz + h + 1, Blocks.WHITE_CONCRETE);
        Build.clear(world, hx + 1, ly, lz - 1, lx - 5, ly + 3, lz + h);
        Build.fill(world, lx - 4, ly, lz + h / 2 - 1, lx - 4, ly + 1, lz + h / 2, Blocks.AIR);
        for (int i = 0; i <= 3; i++) {
            Build.fill(world, hx - 1 + i, ly + 5 + i, lz - 3, lx - 3 - i, ly + 5 + i, lz + h + 2, Blocks.BLUE_CONCRETE);
        }
        Build.fill(world, lx - 4, ly + 2, lz, lx - 4, ly + 2, lz + 1, Blocks.GLASS);
        Build.fill(world, lx - 4, ly + 2, lz + h - 2, lx - 4, ly + 2, lz + h - 1, Blocks.GLASS);
        // Porche.
        Build.fill(world, lx - 3, ly - 1, lz - 1, lx - 2, ly - 1, lz + h, Blocks.OAK_PLANKS);
        // Cortacéspedes.
        for (int r = 0; r < ROWS; r++) {
            Build.set(world, lx - 1, ly, lz + r * CELL + 1, Blocks.RED_CONCRETE);
        }
        // Farolas.
        Build.fill(world, lx + w + 3, ly, lz - 3, lx + w + 3, ly + 3, lz - 3, Blocks.DARK_OAK_FENCE);
        Build.set(world, lx + w + 3, ly + 4, lz - 3, Blocks.SHROOMLIGHT);
        Build.fill(world, lx + w + 3, ly, lz + h + 3, lx + w + 3, ly + 3, lz + h + 3, Blocks.DARK_OAK_FENCE);
        Build.set(world, lx + w + 3, ly + 4, lz + h + 3, Blocks.SHROOMLIGHT);
    }

    public static double cellX(int col) {
        return LAWN_X + col * CELL + CELL / 2.0;
    }

    public static double rowZ(int row) {
        return LAWN_Z + row * CELL + CELL / 2.0;
    }

    public static void removeMower(ServerWorld world, int row) {
        Build.set(world, LAWN_X - 1, LAWN_Y, LAWN_Z + row * CELL + 1, Blocks.AIR);
    }

    public static void restoreMowers(ServerWorld world) {
        for (int r = 0; r < ROWS; r++) {
            Build.set(world, LAWN_X - 1, LAWN_Y, LAWN_Z + r * CELL + 1, Blocks.RED_CONCRETE);
        }
    }
}
