package com.turbopapu.world;

import com.turbopapu.registry.ModBlocks;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.random.Random;

/**
 * Todo lo de Oddworld alrededor de la choza de Alphatemp: chozas Mudokon más pequeñas, tótems con caras
 * Mudokon, un portal de pájaros, el cartel de RuptureFarms, cajas de Mudokon Pops y los Mudokons (con Abe).
 */
public final class MudokonVillage {
    private MudokonVillage() {}

    public static void build(ServerWorld world, int cx, int y0, int cz) {
        Random random = Random.create(cx * 31L + cz);

        // Chozas Mudokon pequeñas alrededor.
        for (int i = 0; i < 5; i++) {
            double a = i * Math.PI * 2 / 5 + 0.4;
            int hx = cx + MathHelper.floor(Math.cos(a) * 17);
            int hz = cz + MathHelper.floor(Math.sin(a) * 17);
            smallHut(world, hx, hz, 3 + random.nextInt(2));
        }

        // Tótems con caras Mudokon a los lados de la entrada.
        totem(world, cx - 5, cz + 10);
        totem(world, cx + 5, cz + 10);
        totem(world, cx - 11, cz - 2);
        totem(world, cx + 11, cz - 2);

        // Portal de pájaros (anillo flotante como en Abe's Oddysee).
        birdPortal(world, cx, cz - 14);

        // Hoguera ceremonial con huesos.
        int fy = ground(world, cx - 8, cz + 12);
        Build.set(world, cx - 8, fy, cz + 12, Blocks.CAMPFIRE);
        for (int[] o : new int[][]{{-1, 0}, {1, 0}, {0, -1}, {0, 1}}) {
            Build.set(world, cx - 8 + o[0] * 2, ground(world, cx - 8 + o[0] * 2, cz + 12 + o[1] * 2), cz + 12 + o[1] * 2, Blocks.BONE_BLOCK);
        }

        // RuptureFarms: chimenea de fábrica y cajas de "Mudokon Pops".
        int rx = cx + 12, rz = cz + 12;
        int ry = ground(world, rx, rz);
        Build.fill(world, rx, ry, rz, rx + 2, ry + 9, rz + 2, Blocks.DEEPSLATE_BRICKS);
        Build.fill(world, rx + 1, ry + 1, rz + 1, rx + 1, ry + 10, rz + 1, Blocks.AIR);
        Build.set(world, rx + 1, ry, rz + 1, Blocks.CAMPFIRE);
        Build.fill(world, rx - 2, ry, rz, rx - 1, ry + 1, rz + 1, Blocks.BARREL);
        Build.set(world, rx + 3, ry, rz - 1, Blocks.BARREL);
        Build.fill(world, rx, ry + 10, rz, rx + 2, ry + 10, rz, Blocks.RED_CONCRETE);

        // Arbustos de spooce brillantes y vasijas por la aldea.
        for (int i = 0; i < 16; i++) {
            double a = random.nextDouble() * Math.PI * 2;
            double d = 8 + random.nextDouble() * 16;
            int x = cx + MathHelper.floor(Math.cos(a) * d), z = cz + MathHelper.floor(Math.sin(a) * d);
            int y = ground(world, x, z);
            if (world.getBlockState(new BlockPos(x, y, z)).isAir()) {
                Build.set(world, x, y, z, i % 3 == 0 ? ModBlocks.VASIJA_MUDOKON : ModBlocks.ARBUSTO_SPOOCE);
            }
        }

        // Los Mudokons y Abe.
        for (int i = 0; i < 5; i++) {
            double a = i * Math.PI * 2 / 5 + 0.4;
            int hx = cx + MathHelper.floor(Math.cos(a) * 17);
            int hz = cz + MathHelper.floor(Math.sin(a) * 17);
            Build.spawn(world, ModEntities.MUDOKON, hx + 0.5, ground(world, hx, hz), hz + 0.5, 10);
        }
        Build.spawn(world, ModEntities.ABE, cx + 0.5, ground(world, cx, cz + 11), cz + 11.5, 12);
    }

    private static int ground(ServerWorld world, int x, int z) {
        return Math.max(Build.surface(world, x, z), world.getSeaLevel() + 1);
    }

    /** Choza de barro con techo de paja en punta y un hueso en lo alto. */
    private static void smallHut(ServerWorld world, int hx, int hz, int r) {
        int y0 = ground(world, hx, hz);
        for (int dx = -r - 1; dx <= r + 1; dx++) {
            for (int dz = -r - 1; dz <= r + 1; dz++) {
                if (dx * dx + dz * dz > (r + 1) * (r + 1)) continue;
                Build.fill(world, hx + dx, y0 - 3, hz + dz, hx + dx, y0 - 1, hz + dz, Blocks.PACKED_MUD);
                Build.clear(world, hx + dx, y0, hz + dz, hx + dx, y0 + r + 5, hz + dz);
            }
        }
        for (int dy = 0; dy < 3; dy++) {
            for (int dx = -r; dx <= r; dx++) {
                for (int dz = -r; dz <= r; dz++) {
                    double d = Math.sqrt(dx * dx + dz * dz);
                    if (d > r || d <= r - 1.2) continue;
                    if (dz < 0 && Math.abs(dx) <= 0 && dy < 2) continue; // puerta
                    Build.set(world, hx + dx, y0 + dy, hz + dz, dy == 0 ? Blocks.MUD_BRICKS : Blocks.PACKED_MUD);
                }
            }
        }
        for (int dy = 0; dy <= r + 1; dy++) {
            double rr = r + 0.5 - dy * (r + 0.5) / (r + 1);
            for (int dx = -r - 1; dx <= r + 1; dx++) {
                for (int dz = -r - 1; dz <= r + 1; dz++) {
                    double d = Math.sqrt(dx * dx + dz * dz);
                    if (d <= rr && d > rr - 1.3) {
                        Build.set(world, hx + dx, y0 + 3 + dy, hz + dz, Blocks.HAY_BLOCK);
                    }
                }
            }
        }
        Build.set(world, hx, y0 + r + 5, hz, Blocks.BONE_BLOCK);
        Build.set(world, new BlockPos(hx, y0, hz), Blocks.LANTERN.getDefaultState());
        Build.set(world, new BlockPos(hx, y0 + 2, hz + r - 1), ModBlocks.ATRAPASUENOS.getDefaultState()
                .with(com.turbopapu.block.DreamcatcherBlock.FACING, net.minecraft.util.math.Direction.NORTH));
        Build.set(world, hx + 1, y0, hz - r - 1, ModBlocks.VASIJA_MUDOKON);
    }

    /** Tótem verde con cara Mudokon (ojos grandes naranjas y boca cosida). */
    private static void totem(ServerWorld world, int x, int z) {
        int y = ground(world, x, z);
        Build.fill(world, x, y, z, x, y + 3, z, Blocks.STRIPPED_DARK_OAK_LOG);
        net.minecraft.block.BlockState totem = ModBlocks.TOTEM_MUDOKON.getDefaultState()
                .with(com.turbopapu.block.FacingDecorBlock.FACING, net.minecraft.util.math.Direction.SOUTH);
        Build.set(world, new BlockPos(x, y + 4, z), totem);
        Build.set(world, new BlockPos(x, y + 5, z), totem);
        Build.set(world, new BlockPos(x, y + 6, z), totem);
        Build.set(world, x, y + 7, z, Blocks.SKELETON_SKULL);
        Build.set(world, new BlockPos(x, y + 3, z + 1), ModBlocks.ATRAPASUENOS.getDefaultState()
                .with(com.turbopapu.block.DreamcatcherBlock.FACING, net.minecraft.util.math.Direction.SOUTH));
    }

    /** Anillo de luz flotante: el portal de pájaros por el que escapan los Mudokons. */
    private static void birdPortal(ServerWorld world, int cx, int cz) {
        int y = ground(world, cx, cz) + 3;
        int r = 4;
        for (int i = 0; i < 64; i++) {
            double a = i * Math.PI * 2 / 64;
            int x = cx + (int) Math.round(Math.cos(a) * r);
            int yy = y + r + (int) Math.round(Math.sin(a) * r);
            Build.set(world, x, yy, cz, i % 4 == 0 ? Blocks.SEA_LANTERN : Blocks.WHITE_STAINED_GLASS);
        }
        Build.set(world, cx, y + r, cz, Blocks.END_ROD);
    }
}
