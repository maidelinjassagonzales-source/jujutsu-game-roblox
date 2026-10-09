package com.turbopapu.world;

import com.turbopapu.block.DreamcatcherBlock;
import com.turbopapu.entity.TurboPapuenseEntity;
import com.turbopapu.registry.ModBlocks;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.block.WallSignBlock;
import net.minecraft.block.entity.SignBlockEntity;
import net.minecraft.block.entity.SignText;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.DyeColor;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.MathHelper;

/**
 * El epílogo: después de vencer a Sualenidus, todos los amigos construyen juntos una aldea en el
 * Planeta TurboPapu y se van a vivir allí. Cada uno tiene su casa con su estilo.
 */
public final class FriendsVillage {
    public static final int CX = 110, CZ = 0;

    private record Home(String name, EntityType<? extends MobEntity> type, Block wall, Block roof, String style) {}

    private static final Home[] HOMES = {
            new Home("Alphatemp", ModEntities.ALPHATEMP, Blocks.MUD_BRICKS, Blocks.HAY_BLOCK, "mudokon"),
            new Home("Guinxu", ModEntities.GUINXU, Blocks.GRAY_CONCRETE, Blocks.BLACK_CONCRETE, "normal"),
            new Home("elink_64", ModEntities.ELINK_64, Blocks.SMOOTH_QUARTZ, Blocks.RED_CONCRETE, "normal"),
            new Home("Aroy", ModEntities.AROY, Blocks.BROWN_TERRACOTTA, Blocks.IRON_BLOCK, "lata"),
            new Home("Juanma", ModEntities.JUANMA, Blocks.WHITE_CONCRETE, Blocks.LIGHT_BLUE_CONCRETE, "normal"),
            new Home("Verity", ModEntities.VERITY_GORDA, Blocks.YELLOW_CONCRETE, Blocks.YELLOW_CONCRETE, "bola"),
            new Home("William", ModEntities.WILLIAM_PIRATON, Blocks.ORANGE_CONCRETE, Blocks.BLUE_CONCRETE, "normal"),
            new Home("Sualenidus", ModEntities.SUALENIDUS_AMIGO, Blocks.PURPLE_CONCRETE, Blocks.PURPUR_BLOCK, "normal"),
            new Home("Mudokons", ModEntities.MUDOKON, Blocks.PACKED_MUD, Blocks.HAY_BLOCK, "mudokon"),
    };

    private FriendsVillage() {}

    public static void build(ServerWorld world, TurboState state) {
        int y0 = Math.max(Build.surface(world, CX, CZ), world.getSeaLevel() + 1);
        // Plaza central con hoguera y cartel.
        for (int dx = -9; dx <= 9; dx++) {
            for (int dz = -9; dz <= 9; dz++) {
                if (dx * dx + dz * dz > 81) continue;
                Build.fill(world, CX + dx, y0 - 4, CZ + dz, CX + dx, y0 - 2, CZ + dz, ModBlocks.ROCA_PAPU);
                Build.set(world, CX + dx, y0 - 1, CZ + dz, (dx + dz) % 2 == 0 ? Blocks.ORANGE_TERRACOTTA : Blocks.PURPLE_TERRACOTTA);
                Build.clear(world, CX + dx, y0, CZ + dz, CX + dx, y0 + 10, CZ + dz);
            }
        }
        Build.set(world, CX, y0, CZ, Blocks.CAMPFIRE);
        Build.fill(world, CX + 3, y0, CZ - 3, CX + 3, y0 + 1, CZ - 3, Blocks.DARK_OAK_FENCE);
        Build.set(world, CX + 3, y0 + 2, CZ - 3, Blocks.OAK_PLANKS);
        sign(world, new BlockPos(CX + 3, y0 + 2, CZ - 2), Direction.SOUTH, "Aldea de", "los Amigos", "¡Bienvenido!");

        for (int i = 0; i < HOMES.length; i++) {
            double a = i * Math.PI * 2 / HOMES.length;
            int hx = CX + MathHelper.floor(Math.cos(a) * 24);
            int hz = CZ + MathHelper.floor(Math.sin(a) * 24);
            buildHome(world, HOMES[i], hx, hz);
        }
        for (int i = 0; i < 8; i++) {
            TurboPapuenseEntity papu = Build.spawn(world, ModEntities.TURBOPAPUENSE, CX + 0.5 + (i % 4) * 2 - 3, y0, CZ + 0.5 + (i / 4) * 4 - 2, 20);
            if (papu != null) {
                papu.setDormido(false);
            }
        }
        state.friendsVillageBuilt = true;
        state.markDirty();
    }

    private static void sign(ServerWorld world, BlockPos pos, Direction facing, String... lines) {
        Build.set(world, pos, Blocks.OAK_WALL_SIGN.getDefaultState().with(WallSignBlock.FACING, facing));
        if (world.getBlockEntity(pos) instanceof SignBlockEntity sign) {
            SignText text = new SignText().withColor(DyeColor.BLACK);
            for (int i = 0; i < lines.length && i < 4; i++) {
                text = text.withMessage(i, Text.literal(lines[i]));
            }
            sign.setText(text, true);
            sign.markDirty();
        }
    }

    private static void buildHome(ServerWorld world, Home home, int hx, int hz) {
        int y0 = Math.max(Build.surface(world, hx, hz), world.getSeaLevel() + 1);
        int r = 3;
        for (int dx = -r - 1; dx <= r + 1; dx++) {
            for (int dz = -r - 1; dz <= r + 1; dz++) {
                Build.fill(world, hx + dx, y0 - 4, hz + dz, hx + dx, y0 - 1, hz + dz, ModBlocks.ROCA_PAPU);
                Build.clear(world, hx + dx, y0, hz + dz, hx + dx, y0 + 9, hz + dz);
            }
        }
        Direction door = Direction.getFacing(CX - hx, 0, CZ - hz);
        switch (home.style()) {
            case "lata" -> {
                // Casa con forma de lata de leche de coco Aroy-D.
                for (int dy = 0; dy <= 6; dy++) {
                    for (int dx = -r; dx <= r; dx++) {
                        for (int dz = -r; dz <= r; dz++) {
                            double d = Math.sqrt(dx * dx + dz * dz);
                            if (d > r + 0.4) continue;
                            boolean shell = d > r - 0.7 || dy == 6;
                            if (!shell) continue;
                            Block b = dy == 6 || dy == 0 ? Blocks.IRON_BLOCK : dy == 3 ? Blocks.ORANGE_CONCRETE : dy == 4 ? Blocks.WHITE_CONCRETE : Blocks.BROWN_TERRACOTTA;
                            Build.set(world, hx + dx, y0 + dy, hz + dz, b);
                        }
                    }
                }
            }
            case "bola" -> {
                // Casa-pelota amarilla de Verity con su sonrisa.
                for (int dx = -r - 1; dx <= r + 1; dx++) {
                    for (int dy = 0; dy <= 2 * r + 1; dy++) {
                        for (int dz = -r - 1; dz <= r + 1; dz++) {
                            double d = Math.sqrt(dx * dx + (dy - r - 0.5) * (dy - r - 0.5) + dz * dz);
                            if (d <= r + 1.2 && d > r) {
                                Build.set(world, hx + dx, y0 + dy, hz + dz, Blocks.YELLOW_CONCRETE);
                            }
                        }
                    }
                }
            }
            default -> {
                for (int dy = 0; dy < 4; dy++) {
                    for (int dx = -r; dx <= r; dx++) {
                        for (int dz = -r; dz <= r; dz++) {
                            if (Math.abs(dx) == r || Math.abs(dz) == r) {
                                Build.set(world, hx + dx, y0 + dy, hz + dz, home.wall());
                            }
                        }
                    }
                }
                for (int i = 0; i <= r + 1; i++) {
                    Build.fill(world, hx - r - 1 + i, y0 + 4 + i, hz - r - 1 + i, hx + r + 1 - i, y0 + 4 + i, hz + r + 1 - i, home.roof());
                }
                if (home.style().equals("mudokon")) {
                    Build.set(world, new BlockPos(hx - door.getOffsetX() * (r - 1), y0 + 2, hz - door.getOffsetZ() * (r - 1)),
                            ModBlocks.ATRAPASUENOS.getDefaultState().with(DreamcatcherBlock.FACING, door));
                    Build.set(world, hx + door.getOffsetX() * (r + 1) + door.rotateYClockwise().getOffsetX(), y0,
                            hz + door.getOffsetZ() * (r + 1) + door.rotateYClockwise().getOffsetZ(), ModBlocks.ARBUSTO_SPOOCE);
                }
            }
        }
        // Puerta hacia la plaza, farol y cartel con el nombre.
        for (int step = r - 1; step <= r + 1; step++) {
            Build.clear(world, hx + door.getOffsetX() * step, y0, hz + door.getOffsetZ() * step,
                    hx + door.getOffsetX() * step, y0 + 1, hz + door.getOffsetZ() * step);
        }
        Build.set(world, hx, y0 + 3, hz, Blocks.LANTERN);
        BlockPos signPos = new BlockPos(hx + door.getOffsetX() * (r + 1) + door.rotateYCounterclockwise().getOffsetX(), y0 + 1,
                hz + door.getOffsetZ() * (r + 1) + door.rotateYCounterclockwise().getOffsetZ());
        Build.set(world, signPos.down(), Blocks.OAK_FENCE.getDefaultState());
        Build.set(world, signPos, Blocks.OAK_PLANKS.getDefaultState());
        sign(world, signPos.offset(door), door, "Casa de", home.name());

        Build.spawn(world, home.type(), hx + 0.5, y0, hz + 0.5, 7);
        if (home.type() == ModEntities.MUDOKON) {
            Build.spawn(world, ModEntities.MUDOKON, hx + 1.5, y0, hz + 0.5, 7);
            Build.spawn(world, ModEntities.ABE, hx - 0.5, y0, hz + 0.5, 7);
        }
        if (home.type() == ModEntities.ALPHATEMP) {
            Build.spawn(world, ModEntities.ALPHAFATERFUR, hx + 1.5, y0, hz - 1.5, 2);
        }
    }
}
