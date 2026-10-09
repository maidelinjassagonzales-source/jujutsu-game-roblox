package com.turbopapu.world;

import com.turbopapu.entity.TurboPapuenseEntity;
import com.turbopapu.registry.ModBlocks;
import com.turbopapu.registry.ModEntities;
import com.turbopapu.registry.ModItems;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.block.ChestBlock;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.random.Random;

/**
 * Aldeas de los Turbopapuenses: una plaza a cuadros con una estatua de TurboPapu en el centro,
 * caminos hacia un anillo de cúpulas (estilo base lunar) naranjas, azules y moradas, y farolas.
 * La aldea principal (0,0) es más grande y tiene a Juanma, Guinxu, elink_64 y Verity Gorda.
 */
public final class VillageBuilder {
    private static final Block[] DOME_COLORS = {Blocks.ORANGE_CONCRETE, Blocks.BLUE_CONCRETE, Blocks.PURPLE_CONCRETE, Blocks.YELLOW_CONCRETE};

    private VillageBuilder() {}

    /** Construye una aldea con centro en (cx, cz). Devuelve la altura de la plaza. */
    public static int build(ServerWorld world, int cx, int cz, Random random, boolean main, boolean defeated) {
        int y0 = Math.max(Build.surface(world, cx, cz), world.getSeaLevel() + 1);
        int plaza = main ? 13 : 10;

        // Plaza a cuadros.
        for (int dx = -plaza; dx <= plaza; dx++) {
            for (int dz = -plaza; dz <= plaza; dz++) {
                if (dx * dx + dz * dz > plaza * plaza) continue;
                int x = cx + dx, z = cz + dz;
                Build.fill(world, x, y0 - 6, z, x, y0 - 2, z, ModBlocks.ROCA_PAPU);
                boolean checker = ((dx >> 1) + (dz >> 1)) % 2 == 0;
                boolean border = dx * dx + dz * dz > (plaza - 1) * (plaza - 1);
                Build.set(world, x, y0 - 1, z, border ? Blocks.PURPLE_CONCRETE : checker ? Blocks.ORANGE_TERRACOTTA : Blocks.PURPLE_TERRACOTTA);
                Build.clear(world, x, y0, z, x, y0 + 20, z);
            }
        }
        buildStatue(world, cx, y0, cz, main ? 5 : 3);

        // Anillo de cúpulas.
        int domes = main ? 12 : 7 + random.nextInt(4);
        double offset = random.nextDouble() * Math.PI * 2;
        for (int i = 0; i < domes; i++) {
            double angle = offset + i * Math.PI * 2 / domes + (random.nextDouble() - 0.5) * 0.25;
            double dist = plaza + 10 + random.nextInt(main ? 12 : 9);
            int hx = cx + MathHelper.floor(Math.cos(angle) * dist);
            int hz = cz + MathHelper.floor(Math.sin(angle) * dist);
            int radius = 3 + random.nextInt(3);
            Block color = DOME_COLORS[random.nextInt(DOME_COLORS.length)];
            int hy = buildDome(world, hx, hz, radius, color, cx, cz, random);
            buildPath(world, cx, cz, hx, hz, plaza, radius);
            // Habitantes: la mayoría dormidos por culpa de Sualenidus.
            int papus = 1 + random.nextInt(2);
            for (int p = 0; p < papus; p++) {
                TurboPapuenseEntity papu = Build.spawn(world, ModEntities.TURBOPAPUENSE,
                        hx + 0.5 + random.nextInt(3) - 1, hy, hz + 0.5 + random.nextInt(3) - 1, radius + 6);
                if (papu != null) {
                    papu.setDormido(!defeated && random.nextFloat() < 0.75f);
                }
            }
        }

        // Farolas alrededor de la plaza.
        for (int i = 0; i < 6; i++) {
            double a = i * Math.PI / 3 + 0.3;
            int x = cx + MathHelper.floor(Math.cos(a) * (plaza - 2));
            int z = cz + MathHelper.floor(Math.sin(a) * (plaza - 2));
            Build.fill(world, x, y0, z, x, y0 + 2, z, Blocks.DARK_OAK_FENCE);
            Build.set(world, x, y0 + 3, z, Blocks.SHROOMLIGHT);
        }

        // Unos pocos despiertos en la plaza.
        int awake = main ? 4 : 1 + random.nextInt(2);
        for (int i = 0; i < awake; i++) {
            Build.spawn(world, ModEntities.TURBOPAPUENSE, cx + 0.5 + random.nextInt(plaza) - plaza / 2.0,
                    y0, cz + plaza - 3 + 0.5, plaza);
        }

        if (main) {
            Build.spawn(world, ModEntities.JUANMA, cx + 7.5, y0, cz + 5.5, 10);
            Build.spawn(world, ModEntities.VERITY_GORDA, cx - 8.5, y0, cz - 4.5, 8);
            Build.spawn(world, ModEntities.AROY, cx + 3.5, y0, cz + 9.5, 8);
            // Parrilla para el asado de Juanma.
            Build.set(world, cx + 9, y0, cz + 2, Blocks.CAMPFIRE);
            Build.set(world, cx + 9, y0, cz + 1, Blocks.SMOKER);
        }
        return y0;
    }

    /** Cúpula tipo base lunar con ventanas, puerta mirando a la plaza, farol y a veces un cofre. */
    private static int buildDome(ServerWorld world, int hx, int hz, int r, Block color, int cx, int cz, Random random) {
        int y0 = Math.max(Build.surface(world, hx, hz), world.getSeaLevel() + 1);
        for (int dx = -r - 1; dx <= r + 1; dx++) {
            for (int dz = -r - 1; dz <= r + 1; dz++) {
                if (dx * dx + dz * dz > (r + 1) * (r + 1)) continue;
                Build.fill(world, hx + dx, y0 - 4, hz + dz, hx + dx, y0 - 2, hz + dz, ModBlocks.ROCA_PAPU);
                Build.set(world, hx + dx, y0 - 1, hz + dz, dx * dx + dz * dz > r * r ? ModBlocks.REGOLITO_PAPU : Blocks.SMOOTH_STONE);
                Build.clear(world, hx + dx, y0, hz + dz, hx + dx, y0 + r + 2, hz + dz);
            }
        }
        for (int dx = -r; dx <= r; dx++) {
            for (int dy = 0; dy <= r; dy++) {
                for (int dz = -r; dz <= r; dz++) {
                    double d = Math.sqrt(dx * dx + dy * dy + dz * dz);
                    if (d > r + 0.4 || d <= r - 0.7) continue;
                    Block b = dy == 2 && (Math.abs(dx) <= 1 || Math.abs(dz) <= 1) ? Blocks.LIGHT_BLUE_STAINED_GLASS
                            : dy == r ? Blocks.WHITE_CONCRETE : color;
                    Build.set(world, hx + dx, y0 + dy, hz + dz, b);
                }
            }
        }
        // Puerta hacia la plaza.
        Direction door = Direction.getFacing(cx - hx, 0, cz - hz);
        for (int step = r - 1; step <= r + 1; step++) {
            for (int dy = 0; dy <= 1; dy++) {
                Build.set(world, new BlockPos(hx + door.getOffsetX() * step, y0 + dy, hz + door.getOffsetZ() * step), Blocks.AIR.getDefaultState());
            }
        }
        Build.set(world, new BlockPos(hx, y0 + r - 1, hz), Blocks.LANTERN.getDefaultState().with(net.minecraft.block.LanternBlock.HANGING, true));
        if (random.nextInt(3) == 0) {
            BlockPos chestPos = new BlockPos(hx - door.getOffsetX() * (r - 1), y0, hz - door.getOffsetZ() * (r - 1));
            Build.set(world, chestPos, Blocks.CHEST.getDefaultState().with(ChestBlock.FACING, door));
            if (world.getBlockEntity(chestPos) instanceof ChestBlockEntity chest) {
                chest.setStack(random.nextInt(9), new ItemStack(ModItems.MATE, 1 + random.nextInt(3)));
                chest.setStack(9 + random.nextInt(9), new ItemStack(Items.COOKED_BEEF, 2 + random.nextInt(5)));
                chest.setStack(18 + random.nextInt(9), new ItemStack(ModBlocks.FRAGMENTO_METEORITO, 1 + random.nextInt(4)));
                if (random.nextInt(4) == 0) {
                    chest.setStack(13, new ItemStack(ModItems.ESTRELLA_DE_PODER));
                }
            }
        } else {
            Build.set(world, new BlockPos(hx - door.getOffsetX() * (r - 1), y0, hz - door.getOffsetZ() * (r - 1)), Blocks.BARREL.getDefaultState());
        }
        return y0;
    }

    /** Camino de la plaza a la cúpula, siguiendo el terreno. */
    private static void buildPath(ServerWorld world, int cx, int cz, int hx, int hz, int plaza, int r) {
        double len = Math.sqrt((hx - cx) * (hx - cx) + (hz - cz) * (hz - cz));
        for (double t = plaza; t < len - r; t += 0.5) {
            int x = cx + MathHelper.floor((hx - cx) * t / len);
            int z = cz + MathHelper.floor((hz - cz) * t / len);
            for (int w = -1; w <= 0; w++) {
                int px = Math.abs(hx - cx) > Math.abs(hz - cz) ? x : x + w;
                int pz = Math.abs(hx - cx) > Math.abs(hz - cz) ? z + w : z;
                int y = Build.surface(world, px, pz);
                Build.set(world, px, y - 1, pz, Blocks.ORANGE_TERRACOTTA);
            }
        }
    }

    /** Estatua de TurboPapu: bola naranja/azul con ojos enfadados, boca, cascos gamer, patas y nubes. */
    public static void buildStatue(ServerWorld world, int cx, int y0, int cz, int r) {
        int legH = r - 1;
        int cy = y0 + legH + r;
        int legX = Math.max(1, r / 2);
        Build.fill(world, cx - legX - 1, y0, cz, cx - legX, y0 + legH, cz + 1, Blocks.ORANGE_CONCRETE);
        Build.fill(world, cx + legX, y0, cz, cx + legX + 1, y0 + legH, cz + 1, Blocks.ORANGE_CONCRETE);
        for (int dx = -r; dx <= r; dx++) {
            for (int dy = -r; dy <= r; dy++) {
                for (int dz = -r; dz <= r; dz++) {
                    if (dx * dx + dy * dy + dz * dz > r * r + 1) continue;
                    double t = (dy - dx) / (2.0 * r);
                    Block b = t > 0.35 ? Blocks.BLUE_CONCRETE : t > 0.05 ? Blocks.PURPLE_CONCRETE : t > -0.3 ? Blocks.ORANGE_CONCRETE : Blocks.YELLOW_CONCRETE;
                    Build.set(world, cx + dx, cy + dy, cz + dz, b);
                }
            }
        }
        int fz = cz + r; // la cara mira hacia +Z
        int eye = Math.max(1, r * 2 / 5);
        for (int side = -1; side <= 1; side += 2) {
            Build.fill(world, cx + side * eye, cy, fz, cx + side * eye, cy + 1, fz, Blocks.BLACK_CONCRETE);
            Build.set(world, cx + side * eye, cy + 1, fz, Blocks.WHITE_CONCRETE);
            Build.set(world, cx + side * (eye + 1), cy + 2, fz - 1, Blocks.BLACK_CONCRETE);
            Build.set(world, cx + side * Math.max(1, eye - 1), cy + 2, fz, Blocks.BLACK_CONCRETE);
        }
        Build.fill(world, cx - 1, cy - Math.max(2, r / 2 + 1), fz, cx + 1, cy - Math.max(1, r / 2), fz, Blocks.CYAN_CONCRETE);
        for (int dx = -r - 1; dx <= r + 1; dx++) {
            int dy = (int) Math.round(Math.sqrt(Math.max(0, (r + 1) * (r + 1) - dx * dx)));
            Build.set(world, cx + dx, cy + dy, cz, Blocks.BLACK_CONCRETE);
        }
        Build.fill(world, cx - r - 1, cy - 1, cz - 1, cx - r - 1, cy + 1, cz + 1, Blocks.GRAY_CONCRETE);
        Build.fill(world, cx + r + 1, cy - 1, cz - 1, cx + r + 1, cy + 1, cz + 1, Blocks.GRAY_CONCRETE);
        Build.fill(world, cx - r - 1, cy - 2, cz + 2, cx - r - 1, cy - 2, fz - 1, Blocks.BLACK_CONCRETE);
        Build.fill(world, cx - r - 5, cy + 2, cz, cx - r - 3, cy + 3, cz + 1, Blocks.WHITE_WOOL);
        Build.fill(world, cx + r + 3, cy - 1, cz, cx + r + 6, cy, cz + 1, Blocks.WHITE_WOOL);
    }
}
