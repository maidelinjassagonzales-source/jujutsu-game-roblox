package com.turbopapu.world;

import com.turbopapu.entity.PapuNpcEntity;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.*;
import com.turbopapu.block.DreamcatcherBlock;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;

/** Estructuras del Overworld: la choza Mudokon de Alphatemp y la balsa de William_Piraton. */
public final class OverworldBuilds {
    private OverworldBuilds() {}

    /**
     * Choza redonda de barro estilo Oddworld/Mudokon: paredes de barro, techo cónico de paja, huesos y calaveras.
     * Debajo hay un sótano oscuro donde Alphafaterfur sigue grabando su video de 2 horas.
     */
    public static void buildAlphatempHut(ServerWorld world, int cx, int cz) {
        int y0 = Math.max(Build.surface(world, cx, cz), world.getSeaLevel() + 1);
        int r = 6;

        // Plataforma de barro y limpiar el aire de encima.
        for (int dx = -r - 2; dx <= r + 2; dx++) {
            for (int dz = -r - 2; dz <= r + 2; dz++) {
                if (dx * dx + dz * dz > (r + 2) * (r + 2)) continue;
                Build.fill(world, cx + dx, y0 - 4, cz + dz, cx + dx, y0 - 1, cz + dz, Blocks.PACKED_MUD);
                Build.set(world, cx + dx, y0 - 1, cz + dz, dx * dx + dz * dz > r * r ? Blocks.COARSE_DIRT : Blocks.MUD_BRICKS);
                Build.clear(world, cx + dx, y0, cz + dz, cx + dx, y0 + 12, cz + dz);
            }
        }
        // Paredes redondas.
        for (int dy = 0; dy < 4; dy++) {
            for (int dx = -r; dx <= r; dx++) {
                for (int dz = -r; dz <= r; dz++) {
                    double d = Math.sqrt(dx * dx + dz * dz);
                    if (d <= r && d > r - 1.2) {
                        boolean door = dz > 0 && Math.abs(dx) <= 1 && dy < 3;
                        boolean window = dy == 2 && (dz == 0 || dx == 0) && !door;
                        if (door) continue;
                        Block wallBlock = dy == 0 ? Blocks.MUD_BRICKS
                                : (dy == 1 && (dx + dz) % 3 == 0) ? com.turbopapu.registry.ModBlocks.LADRILLO_MUDOKON : Blocks.PACKED_MUD;
                        Build.set(world, cx + dx, y0 + dy, cz + dz, window ? Blocks.AIR : wallBlock);
                    }
                }
            }
        }
        // Techo cónico de paja.
        for (int dy = 0; dy <= r; dy++) {
            double rr = r + 0.5 - dy;
            for (int dx = -r - 1; dx <= r + 1; dx++) {
                for (int dz = -r - 1; dz <= r + 1; dz++) {
                    double d = Math.sqrt(dx * dx + dz * dz);
                    if (d <= rr && d > rr - 1.3) {
                        Build.set(world, cx + dx, y0 + 4 + dy, cz + dz, dy == r ? Blocks.BONE_BLOCK : Blocks.HAY_BLOCK);
                    }
                }
            }
        }
        // Pilares de hueso con calaveras en la entrada.
        for (int side = -1; side <= 1; side += 2) {
            int x = cx + side * 2;
            int z = cz + r + 1;
            Build.fill(world, x, y0, z, x, y0 + 2, z, Blocks.BONE_BLOCK);
            Build.set(world, new BlockPos(x, y0 + 3, z), Blocks.SKELETON_SKULL.getDefaultState());
        }
        // Interior: fogata, alfombra, el "Freddy" de Alphatemp y un cartel.
        Build.set(world, new BlockPos(cx, y0, cz), Blocks.CAMPFIRE.getDefaultState());
        Build.set(world, new BlockPos(cx, y0 - 1, cz), Blocks.MUD_BRICKS.getDefaultState());
        buildFreddy(world, cx - 3, y0, cz - 2);
        // Cosas de Oddworld: atrapasueños en las paredes, vasijas, tótem y spooce.
        BlockState dream = com.turbopapu.registry.ModBlocks.ATRAPASUENOS.getDefaultState();
        Build.set(world, new BlockPos(cx, y0 + 3, cz - 4), dream.with(DreamcatcherBlock.FACING, Direction.SOUTH));
        Build.set(world, new BlockPos(cx - 4, y0 + 3, cz), dream.with(DreamcatcherBlock.FACING, Direction.EAST));
        Build.set(world, new BlockPos(cx + 4, y0 + 3, cz), dream.with(DreamcatcherBlock.FACING, Direction.WEST));
        Build.set(world, new BlockPos(cx + 2, y0 + 2, cz + 4), dream.with(DreamcatcherBlock.FACING, Direction.NORTH));
        Build.set(world, cx + 4, y0, cz + 1, com.turbopapu.registry.ModBlocks.VASIJA_MUDOKON);
        Build.set(world, cx - 4, y0, cz - 1, com.turbopapu.registry.ModBlocks.VASIJA_MUDOKON);
        Build.set(world, cx - 2, y0, cz + 4, com.turbopapu.registry.ModBlocks.VASIJA_MUDOKON);
        Build.set(world, new BlockPos(cx + 2, y0, cz - 4), com.turbopapu.registry.ModBlocks.TOTEM_MUDOKON.getDefaultState()
                .with(com.turbopapu.block.FacingDecorBlock.FACING, Direction.SOUTH));
        Build.set(world, new BlockPos(cx + 2, y0 + 1, cz - 4), com.turbopapu.registry.ModBlocks.TOTEM_MUDOKON.getDefaultState()
                .with(com.turbopapu.block.FacingDecorBlock.FACING, Direction.SOUTH));
        Build.set(world, new BlockPos(cx + 3, y0, cz - 3), Blocks.JUKEBOX.getDefaultState());
        Build.set(world, new BlockPos(cx + 4, y0, cz - 1), Blocks.LANTERN.getDefaultState());
        Build.set(world, new BlockPos(cx - 4, y0, cz + 2), Blocks.LANTERN.getDefaultState());

        // Sótano de Alphafaterfur.
        int by = y0 - 7;
        Build.fill(world, cx - 4, by - 1, cz - 4, cx + 4, by + 4, cz + 4, Blocks.BLACKSTONE);
        Build.clear(world, cx - 3, by, cz - 3, cx + 3, by + 3, cz + 3);
        Build.fill(world, cx - 3, by - 1, cz - 3, cx + 3, by - 1, cz + 3, Blocks.RED_WOOL);
        // "Monitor" y PC.
        Build.fill(world, cx - 1, by + 1, cz - 3, cx + 1, by + 2, cz - 3, Blocks.LIGHT_BLUE_STAINED_GLASS);
        Build.fill(world, cx - 1, by, cz - 2, cx + 1, by, cz - 2, Blocks.BLACK_CONCRETE);
        Build.set(world, cx + 2, by, cz - 2, Blocks.REDSTONE_LAMP);
        Build.set(world, cx + 2, by - 1, cz - 2, Blocks.REDSTONE_BLOCK);
        Build.set(world, cx - 3, by + 3, cz + 3, Blocks.SHROOMLIGHT);
        Build.set(world, cx + 3, by + 3, cz + 3, Blocks.CRYING_OBSIDIAN);
        // Escalera de bajada.
        int lx = cx + 3, lz = cz + 2;
        for (int y = by; y < y0; y++) {
            Build.set(world, new BlockPos(lx, y, lz + 1), Blocks.BLACKSTONE.getDefaultState());
            Build.set(world, new BlockPos(lx, y, lz), Blocks.LADDER.getDefaultState().with(LadderBlock.FACING, Direction.NORTH));
        }
        Build.set(world, new BlockPos(lx, y0 - 1, lz), Blocks.SPRUCE_TRAPDOOR.getDefaultState()
                .with(TrapdoorBlock.FACING, Direction.NORTH).with(TrapdoorBlock.HALF, net.minecraft.block.enums.BlockHalf.TOP));

        Build.spawn(world, ModEntities.ALPHATEMP, cx + 0.5, y0, cz + 2.5, 4);
        PapuNpcEntity evil = Build.spawn(world, ModEntities.ALPHAFATERFUR, cx + 0.5, by, cz - 0.5, 2);
        if (evil != null) {
            evil.setYaw(180);
        }
        MudokonVillage.build(world, cx, y0, cz);
        world.getPlayers(p -> p.getBlockPos().isWithinDistance(new BlockPos(cx, y0, cz), 100)).forEach(p ->
                p.sendMessage(Text.translatable("message.turbopapu.hut_found").formatted(Formatting.AQUA), false));
    }

    /** Estatua de Freddy Fazbear "hecha a mano" (Alphatemp es fan de FNAF). */
    private static void buildFreddy(ServerWorld world, int x, int y, int z) {
        Build.fill(world, x, y, z, x, y + 1, z, Blocks.BROWN_WOOL);
        Build.set(world, x, y + 2, z, Blocks.BROWN_TERRACOTTA);
        Build.set(world, x, y + 3, z, Blocks.BLACK_CARPET);
        Build.set(world, new BlockPos(x + 1, y + 1, z), Blocks.BROWN_WOOL.getDefaultState());
        Build.set(world, new BlockPos(x - 1, y + 1, z), Blocks.BROWN_WOOL.getDefaultState());
    }

    /** Balsa con vela y bandera pirata en el mar, con William_Piraton encima. */
    public static boolean spawnWilliamRaft(ServerWorld world, ServerPlayerEntity player) {
        Vec3d look = player.getRotationVec(1f);
        int x = MathHelper.floor(player.getX() + look.x * 18);
        int z = MathHelper.floor(player.getZ() + look.z * 18);
        int y = world.getSeaLevel();
        if (!world.getBlockState(new BlockPos(x, y - 1, z)).getFluidState().isStill()) {
            return false;
        }
        Build.fill(world, x - 2, y - 1, z - 3, x + 2, y - 1, z + 3, Blocks.OAK_PLANKS);
        Build.fill(world, x - 2, y, z - 3, x + 2, y + 6, z + 3, Blocks.AIR);
        Build.fill(world, x, y, z, x, y + 5, z, Blocks.OAK_FENCE);
        Build.fill(world, x - 2, y + 2, z + 1, x + 2, y + 4, z + 1, Blocks.WHITE_WOOL);
        Build.set(world, x, y + 6, z, Blocks.BLACK_WOOL);
        Build.set(world, x + 1, y + 6, z, Blocks.BLACK_WOOL);
        Build.set(world, x, y, z - 2, Blocks.BARREL);
        Build.set(world, new BlockPos(x - 2, y, z - 3), Blocks.LANTERN.getDefaultState());
        PapuNpcEntity william = Build.spawn(world, ModEntities.WILLIAM_PIRATON, x + 0.5, y, z - 0.5, 1);
        player.sendMessage(Text.translatable("message.turbopapu.william_found").formatted(Formatting.GOLD), false);
        return william != null;
    }
}
