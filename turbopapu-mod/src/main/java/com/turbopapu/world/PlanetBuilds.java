package com.turbopapu.world;

import com.turbopapu.entity.SualenidusEntity;
import com.turbopapu.entity.TurboPapuenseEntity;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;

/** Estructuras del Planeta TurboPapu: la aldea de los Turbopapuenses y la guarida de Sualenidus. */
public final class PlanetBuilds {
    private PlanetBuilds() {}

    /** Aldea en (0,0): suelo a cuadros, chozas naranjas/azules, estatua gigante de TurboPapu y los personajes. */
    public static void buildVillage(ServerWorld world, TurboState state) {
        int y0 = Math.max(Build.surface(world, 0, 0), world.getSeaLevel() + 1);
        int r = 22;

        for (int x = -r; x <= r; x++) {
            for (int z = -r; z <= r; z++) {
                Build.fill(world, x, y0 - 5, z, x, y0 - 2, z, Blocks.DIRT);
                boolean checker = ((x >> 1) + (z >> 1)) % 2 == 0;
                Build.set(world, x, y0 - 1, z, checker ? Blocks.ORANGE_TERRACOTTA : Blocks.PURPLE_TERRACOTTA);
                Build.clear(world, x, y0, z, x, y0 + 18, z);
            }
        }
        buildStatue(world, 0, y0, -13);
        buildHut(world, -14, y0, -8, Blocks.ORANGE_CONCRETE);
        buildHut(world, 14, y0, -8, Blocks.BLUE_CONCRETE);
        buildHut(world, -14, y0, 10, Blocks.BLUE_CONCRETE);
        buildHut(world, 14, y0, 10, Blocks.ORANGE_CONCRETE);
        // Parrilla para el asado de Juanma.
        Build.set(world, 6, y0, 4, Blocks.CAMPFIRE);
        Build.set(world, 6, y0, 3, Blocks.SMOKER);
        // Faroles.
        for (int[] p : new int[][]{{-8, -8}, {8, -8}, {-8, 8}, {8, 8}}) {
            Build.fill(world, p[0], y0, p[1], p[0], y0 + 2, p[1], Blocks.DARK_OAK_FENCE);
            Build.set(world, p[0], y0 + 3, p[1], Blocks.SHROOMLIGHT);
        }

        // Los pocos que siguen despiertos...
        Build.spawn(world, ModEntities.JUANMA, 5.5, y0, 5.5, 8);
        Build.spawn(world, ModEntities.GUINXU, -5.5, y0, 5.5, 8);
        Build.spawn(world, ModEntities.ELINK_64, 0.5, y0, -6.5, 8);
        Build.spawn(world, ModEntities.VERITY_GORDA, -6.5, y0, -2.5, 6);
        for (int i = 0; i < 4; i++) {
            Build.spawn(world, ModEntities.TURBOPAPUENSE, -3 + i * 2 + 0.5, y0, 1.5, 10);
        }
        // ...y los que se quedaron dormidos.
        int[][] sleepers = {{-14, -8}, {14, -8}, {-14, 10}, {14, 10}, {-10, 16}, {10, 16}, {-17, 0}, {17, 0}};
        for (int[] s : sleepers) {
            TurboPapuenseEntity papu = Build.spawn(world, ModEntities.TURBOPAPUENSE, s[0] + 0.5, y0, s[1] + 0.5, 0);
            if (papu != null && !state.sualenidusDefeated) {
                papu.setDormido(true);
            }
        }

        state.villageBuilt = true;
        state.villageY = y0;
        state.markDirty();
    }

    /** Estatua de TurboPapu: una bola naranja/azul con ojos enfadados, boca, cascos gamer y patas. */
    private static void buildStatue(ServerWorld world, int cx, int y0, int cz) {
        int r = 5;
        int cy = y0 + 4 + r;
        // Patas.
        Build.fill(world, cx - 3, y0, cz, cx - 2, y0 + 4, cz + 1, Blocks.ORANGE_CONCRETE);
        Build.fill(world, cx + 2, y0, cz, cx + 3, y0 + 4, cz + 1, Blocks.ORANGE_CONCRETE);
        for (int dx = -r; dx <= r; dx++) {
            for (int dy = -r; dy <= r; dy++) {
                for (int dz = -r; dz <= r; dz++) {
                    if (dx * dx + dy * dy + dz * dz > r * r + 1) continue;
                    // Degradado: arriba-izquierda azul/morado, abajo-derecha naranja (como el icono de TurboPapu).
                    double t = (dy - dx) / (2.0 * r);
                    Block b = t > 0.35 ? Blocks.BLUE_CONCRETE : t > 0.05 ? Blocks.PURPLE_CONCRETE : t > -0.3 ? Blocks.ORANGE_CONCRETE : Blocks.YELLOW_CONCRETE;
                    Build.set(world, cx + dx, cy + dy, cz + dz, b);
                }
            }
        }
        int fz = cz + r; // la cara mira hacia la aldea (+Z)
        // Ojos.
        for (int side = -1; side <= 1; side += 2) {
            Build.fill(world, cx + side * 2, cy, fz, cx + side * 2, cy + 1, fz, Blocks.BLACK_CONCRETE);
            Build.set(world, cx + side * 2, cy + 1, fz, Blocks.WHITE_CONCRETE);
            // Cejas enfadadas.
            Build.set(world, cx + side * 3, cy + 3, fz - 1, Blocks.BLACK_CONCRETE);
            Build.set(world, cx + side, cy + 2, fz, Blocks.BLACK_CONCRETE);
        }
        // Boca abierta (turquesa).
        Build.fill(world, cx - 1, cy - 3, fz, cx + 1, cy - 2, fz, Blocks.CYAN_CONCRETE);
        Build.set(world, cx, cy - 3, fz, Blocks.LIGHT_BLUE_CONCRETE);
        // Cascos gamer con micrófono.
        for (int dx = -r - 1; dx <= r + 1; dx++) {
            int dy = (int) Math.round(Math.sqrt(Math.max(0, (r + 1) * (r + 1) - dx * dx)));
            Build.set(world, cx + dx, cy + dy, cz, Blocks.BLACK_CONCRETE);
        }
        Build.fill(world, cx - r - 1, cy - 1, cz - 1, cx - r - 1, cy + 1, cz + 1, Blocks.GRAY_CONCRETE);
        Build.fill(world, cx + r + 1, cy - 1, cz - 1, cx + r + 1, cy + 1, cz + 1, Blocks.GRAY_CONCRETE);
        Build.fill(world, cx - r - 1, cy - 2, cz + 2, cx - r - 1, cy - 2, fz - 1, Blocks.BLACK_CONCRETE);
        Build.set(world, cx - r, cy - 2, fz - 1, Blocks.BLACK_CONCRETE);
        // Nubes alrededor.
        Build.fill(world, cx - r - 6, cy + 2, cz, cx - r - 3, cy + 3, cz + 1, Blocks.WHITE_WOOL);
        Build.fill(world, cx + r + 3, cy - 1, cz, cx + r + 7, cy, cz + 1, Blocks.WHITE_WOOL);
    }

    private static void buildHut(ServerWorld world, int cx, int y0, int cz, Block wall) {
        Build.fill(world, cx - 3, y0, cz - 3, cx + 3, y0 + 3, cz + 3, wall);
        Build.clear(world, cx - 2, y0, cz - 2, cx + 2, y0 + 3, cz + 2);
        Build.clear(world, cx, y0, cz + 3, cx, y0 + 1, cz + 3);
        Build.set(world, cx - 3, y0 + 2, cz, Blocks.GLASS);
        Build.set(world, cx + 3, y0 + 2, cz, Blocks.GLASS);
        for (int i = 0; i <= 3; i++) {
            Build.fill(world, cx - 3 + i, y0 + 4 + i, cz - 3 + i, cx + 3 - i, y0 + 4 + i, cz + 3 - i, Blocks.PURPLE_CONCRETE);
        }
        Build.set(world, cx + 2, y0, cz - 2, Blocks.LANTERN);
        Build.set(world, cx - 2, y0, cz - 2, Blocks.PURPLE_WOOL);
    }

    /** Guarida de Sualenidus: cúpula de purpur y cristal morado rodeada de lavanda, con su setup gamer dentro. */
    public static void buildLair(ServerWorld world, TurboState state) {
        int cx = TurboState.LAIR_X, cz = TurboState.LAIR_Z;
        int y0 = Math.max(Build.surface(world, cx, cz), world.getSeaLevel() + 1);
        int r = 14;

        for (int x = -r - 5; x <= r + 5; x++) {
            for (int z = -r - 5; z <= r + 5; z++) {
                int d2 = x * x + z * z;
                if (d2 > (r + 5) * (r + 5)) continue;
                Build.fill(world, cx + x, y0 - 4, cz + z, cx + x, y0 - 2, cz + z, Blocks.DIRT);
                Build.set(world, cx + x, y0 - 1, cz + z, d2 > r * r ? Blocks.GRASS_BLOCK : Blocks.PURPLE_CONCRETE);
                Build.clear(world, cx + x, y0, cz + z, cx + x, y0 + r + 2, cz + z);
                // Campo de lavanda (alliums) alrededor.
                if (d2 > (r + 1) * (r + 1) && world.random.nextInt(3) > 0) {
                    Build.set(world, cx + x, y0, cz + z, world.random.nextBoolean() ? Blocks.ALLIUM : Blocks.AZURE_BLUET);
                }
            }
        }
        // Cúpula.
        for (int x = -r; x <= r; x++) {
            for (int y = 0; y <= r; y++) {
                for (int z = -r; z <= r; z++) {
                    double d = Math.sqrt(x * x + y * y + z * z);
                    if (d > r || d <= r - 1.3) continue;
                    boolean entrance = z > 0 && Math.abs(x) <= 2 && y <= 4;
                    if (entrance) continue;
                    Block b = world.random.nextInt(5) == 0 ? Blocks.PURPLE_STAINED_GLASS : (y % 4 == 0 ? Blocks.PURPUR_PILLAR : Blocks.PURPUR_BLOCK);
                    Build.set(world, cx + x, y0 + y, cz + z, b);
                }
            }
        }
        // Setup gamer de Valorant: pantallas rojas, "Spike" y silla.
        Build.fill(world, cx - 3, y0, cz - 10, cx + 3, y0, cz - 10, Blocks.BLACK_CONCRETE);
        Build.fill(world, cx - 3, y0 + 1, cz - 11, cx + 3, y0 + 3, cz - 11, Blocks.RED_STAINED_GLASS);
        Build.set(world, cx, y0, cz - 8, Blocks.RED_CONCRETE);
        Build.set(world, cx, y0 + 1, cz - 8, Blocks.RED_CONCRETE);
        Build.set(world, cx + 6, y0, cz - 6, Blocks.RESPAWN_ANCHOR);
        Build.set(world, cx - 6, y0, cz - 6, Blocks.TARGET);
        Build.set(world, cx - 6, y0 + 1, cz - 6, Blocks.TARGET);
        for (int[] p : new int[][]{{-8, 0}, {8, 0}, {0, 0}}) {
            Build.set(world, cx + p[0], y0 + 9, cz + p[1], Blocks.SHROOMLIGHT);
        }
        // Algunos Turbopapuenses dormidos (víctimas de la lavanda).
        for (int i = 0; i < 3; i++) {
            TurboPapuenseEntity papu = Build.spawn(world, ModEntities.TURBOPAPUENSE, cx - 8 + i * 8 + 0.5, y0, cz + 6.5, 0);
            if (papu != null) {
                papu.setDormido(!state.sualenidusDefeated);
            }
        }
        if (!state.sualenidusDefeated) {
            Build.spawn(world, ModEntities.SUALENIDUS, cx + 0.5, y0, cz - 3.5, 0);
            world.getPlayers(p -> p.getBlockPos().isWithinDistance(new BlockPos(cx, y0, cz), 140)).forEach(p ->
                    p.sendMessage(Text.translatable("message.turbopapu.lair_found").formatted(Formatting.LIGHT_PURPLE), false));
        }
        state.lairBuilt = true;
        state.markDirty();
    }
}
