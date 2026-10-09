package com.turbopapu.world;

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

    /** Aldea principal en (0,0), donde aterriza el cohete. */
    public static void buildVillage(ServerWorld world, TurboState state) {
        state.villageY = VillageBuilder.build(world, 0, 0, world.getRandom(), true, state.sualenidusDefeated);
        state.villageBuilt = true;
        state.markDirty();
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
                Build.set(world, cx + x, y0 - 1, cz + z, d2 > r * r ? Blocks.GRASS_BLOCK : Blocks.PURPLE_CONCRETE);
                Build.fill(world, cx + x, y0 - 4, cz + z, cx + x, y0 - 2, cz + z, d2 > r * r ? Blocks.DIRT : com.turbopapu.registry.ModBlocks.ROCA_PAPU);
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
            world.getPlayers(p -> p.getBlockPos().isWithinDistance(new BlockPos(cx, y0, cz), 140)).forEach(p -> {
                p.sendMessage(Text.translatable("message.turbopapu.lair_found").formatted(Formatting.LIGHT_PURPLE), false);
                com.turbopapu.network.ModPackets.dialogue(p, "sualenidus_intro", 0, -1);
            });
        }
        state.lairBuilt = true;
        state.markDirty();
    }
}
