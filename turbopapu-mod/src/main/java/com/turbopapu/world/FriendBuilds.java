package com.turbopapu.world;

import com.turbopapu.entity.PapuNpcEntity;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.block.StairsBlock;
import net.minecraft.block.WallSignBlock;
import net.minecraft.block.entity.SignBlockEntity;
import net.minecraft.block.entity.SignText;
import net.minecraft.block.CarvedPumpkinBlock;
import net.minecraft.block.JukeboxBlock;
import net.minecraft.entity.decoration.painting.PaintingEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.DyeColor;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;

/** Casas de los amigos en el Overworld: el estudio de Guinxu y el castillo de elink_64. */
public final class FriendBuilds {
    private FriendBuilds() {}

    private static int ground(ServerWorld world, int x, int z) {
        return Math.max(Build.surface(world, x, z), world.getSeaLevel() + 1);
    }

    private static void foundation(ServerWorld world, int cx, int y0, int cz, int rx, int rz, int height, Block floor) {
        for (int x = cx - rx - 1; x <= cx + rx + 1; x++) {
            for (int z = cz - rz - 1; z <= cz + rz + 1; z++) {
                Build.fill(world, x, y0 - 4, z, x, y0 - 2, z, Blocks.STONE);
                Build.set(world, x, y0 - 1, z, Math.abs(x - cx) <= rx && Math.abs(z - cz) <= rz ? floor : Blocks.GRASS_BLOCK);
                Build.clear(world, x, y0, z, x, y0 + height, z);
            }
        }
    }

    public static void sign(ServerWorld world, BlockPos pos, Direction facing, DyeColor color, String... lines) {
        Build.set(world, pos, Blocks.BIRCH_WALL_SIGN.getDefaultState().with(WallSignBlock.FACING, facing));
        if (world.getBlockEntity(pos) instanceof SignBlockEntity sign) {
            SignText text = new SignText().withColor(color).withGlowing(true);
            for (int i = 0; i < lines.length && i < 4; i++) {
                text = text.withMessage(i, Text.literal(lines[i]));
            }
            sign.setText(text, true);
            sign.markDirty();
        }
    }

    private static void painting(ServerWorld world, BlockPos pos, Direction facing) {
        PaintingEntity.placePainting(world, pos, facing).ifPresent(world::spawnEntity);
    }

    /**
     * El estudio de Guinxu, como en sus vídeos: paredes gris oscuro, el cartel "Guinxu" en la pared,
     * panel de listones de madera, estantería negra con consolas retro, la máscara de Majora,
     * placas de YouTube de oro y plata y su silla blanca.
     */
    public static void buildGuinxuStudio(ServerWorld world, int cx, int cz) {
        int y0 = ground(world, cx, cz);
        int rx = 6, rz = 5, h = 5;
        foundation(world, cx, y0, cz, rx, rz, h + 3, Blocks.DARK_OAK_PLANKS);

        // Paredes y techo.
        for (int y = 0; y <= h; y++) {
            for (int x = -rx; x <= rx; x++) {
                for (int z = -rz; z <= rz; z++) {
                    boolean wall = Math.abs(x) == rx || Math.abs(z) == rz;
                    if (y == h) {
                        Build.set(world, cx + x, y0 + y, cz + z, Blocks.BLACK_CONCRETE);
                    } else if (wall) {
                        Block b = Blocks.GRAY_CONCRETE;
                        if (x == -rx && z > -rz && z < rz) {
                            // Panel de listones de madera (izquierda).
                            b = (z % 2 == 0) ? Blocks.STRIPPED_OAK_LOG : Blocks.OAK_PLANKS;
                        }
                        Build.set(world, cx + x, y0 + y, cz + z, b);
                    }
                }
            }
        }
        // Puerta y ventanas.
        Build.clear(world, cx, y0, cz + rz, cx, y0 + 1, cz + rz);
        Build.set(world, cx + rx, y0 + 2, cz + 2, Blocks.GLASS);
        // Luz del techo.
        Build.set(world, cx - 2, y0 + h, cz, Blocks.SHROOMLIGHT);
        Build.set(world, cx + 2, y0 + h, cz, Blocks.SHROOMLIGHT);

        int back = cz - rz; // pared del fondo (norte)
        // Cartel "Guinxu" (blanco) con el rombo amarillo.
        Build.fill(world, cx - 4, y0 + 3, back, cx - 1, y0 + 3, back, Blocks.WHITE_CONCRETE);
        Build.set(world, cx - 2, y0 + 3, back, Blocks.YELLOW_CONCRETE);
        sign(world, new BlockPos(cx - 3, y0 + 3, back + 1), Direction.SOUTH, DyeColor.GRAY, "", "Guinxu");
        // Cable que baja del cartel.
        Build.fill(world, cx - 3, y0 + 1, back + 1, cx - 3, y0 + 2, back + 1, Blocks.AIR);

        // Mueble negro a la izquierda con la máscara de Majora y juegos encima.
        Build.fill(world, cx - 5, y0, back + 1, cx - 3, y0, back + 2, Blocks.BLACK_CONCRETE);
        Build.set(world, new BlockPos(cx - 4, y0 + 1, back + 2), Blocks.CARVED_PUMPKIN.getDefaultState()
                .with(CarvedPumpkinBlock.FACING, Direction.SOUTH)); // máscara de Majora
        Build.set(world, cx - 5, y0 + 1, back + 1, Blocks.RED_CONCRETE);      // caja de juego retro
        Build.set(world, cx - 3, y0 + 1, back + 1, Blocks.WHITE_CARPET);
        painting(world, new BlockPos(cx - 4, y0 + 2, back + 1), Direction.SOUTH);

        // Estantería metálica negra a la derecha con consolas.
        int sx = cx + 4;
        for (int y = 0; y < h; y++) {
            Build.set(world, sx - 1, y0 + y, back + 1, Blocks.IRON_BARS);
            Build.set(world, sx + 1, y0 + y, back + 1, Blocks.IRON_BARS);
        }
        Build.set(world, sx, y0, back + 1, Blocks.BLACK_CONCRETE);          // consola negra
        Build.set(world, sx, y0 + 1, back + 1, Blocks.LIGHT_GRAY_CONCRETE); // Game Boy / SNES
        Build.set(world, sx, y0 + 2, back + 1, Blocks.RED_TERRACOTTA);      // figura
        Build.set(world, sx, y0 + 3, back + 1, Blocks.ORANGE_CONCRETE);     // GameBoy Advance naranja
        // Placas de YouTube (oro y plata) en la pared derecha.
        Build.set(world, cx + rx, y0 + 3, back + 2, Blocks.GOLD_BLOCK);
        Build.set(world, cx + rx, y0 + 2, back + 3, Blocks.IRON_BLOCK);

        // Silla blanca y Guinxu delante.
        Build.set(world, new BlockPos(cx, y0, back + 2), Blocks.QUARTZ_STAIRS.getDefaultState().with(StairsBlock.FACING, Direction.NORTH));
        Build.set(world, cx, y0 + 1, back + 1, Blocks.QUARTZ_BLOCK);
        // Mesa con el PC.
        Build.fill(world, cx - 1, y0, back + 4, cx + 1, y0, back + 4, Blocks.DARK_OAK_PLANKS);
        Build.set(world, cx + 1, y0 + 1, back + 4, Blocks.BLACK_CONCRETE);

        sign(world, new BlockPos(cx + 2, y0 + 2, cz + rz + 1), Direction.SOUTH, DyeColor.BLACK, "Estudio de", "Guinxu", "¡Pasa!");

        PapuNpcEntity guinxu = Build.spawn(world, ModEntities.GUINXU, cx + 0.5, y0, back + 3.5, 3);
        if (guinxu != null) {
            guinxu.setYaw(0);
            guinxu.setHeadYaw(0);
            guinxu.setBodyYaw(0);
        }
        world.getPlayers(p -> p.getBlockPos().isWithinDistance(new BlockPos(cx, y0, cz), 100)).forEach(p ->
                p.sendMessage(Text.literal("Ves una casa gris con un cartel: \"Estudio de Guinxu\".").formatted(Formatting.YELLOW), false));
    }

    /**
     * El castillo de elink_64: un mini castillo de Peach de Super Mario 64 (paredes blancas, tejados rojos,
     * vidriera rosa y estrella) con una pista de baile iluminada de "Billie Jean" dentro.
     */
    public static void buildElinkCastle(ServerWorld world, int cx, int cz) {
        int y0 = ground(world, cx, cz);
        int rx = 8, rz = 6, h = 7;
        foundation(world, cx, y0, cz, rx, rz, h + 12, Blocks.STONE_BRICKS);

        for (int y = 0; y < h; y++) {
            for (int x = -rx; x <= rx; x++) {
                for (int z = -rz; z <= rz; z++) {
                    if (Math.abs(x) == rx || Math.abs(z) == rz) {
                        Build.set(world, cx + x, y0 + y, cz + z, y == 0 ? Blocks.STONE_BRICKS : Blocks.SMOOTH_QUARTZ);
                    }
                }
            }
        }
        // Almenas y techo plano.
        Build.fill(world, cx - rx, y0 + h, cz - rz, cx + rx, y0 + h, cz + rz, Blocks.SMOOTH_QUARTZ);
        // Torre central con tejado rojo en pirámide.
        int ty = y0 + h + 1;
        Build.fill(world, cx - 3, ty, cz - 3, cx + 3, ty + 3, cz + 3, Blocks.SMOOTH_QUARTZ);
        for (int i = 0; i <= 4; i++) {
            Build.fill(world, cx - 4 + i, ty + 4 + i, cz - 4 + i, cx + 4 - i, ty + 4 + i, cz + 4 - i, Blocks.RED_CONCRETE);
        }
        Build.set(world, cx, ty + 9, cz, Blocks.GOLD_BLOCK);
        // Torres de las esquinas delanteras.
        for (int side = -1; side <= 1; side += 2) {
            int tx = cx + side * rx;
            int tz = cz + rz;
            Build.fill(world, tx - 1, y0, tz - 1, tx + 1, y0 + h + 3, tz + 1, Blocks.SMOOTH_QUARTZ);
            for (int i = 0; i <= 2; i++) {
                Build.fill(world, tx - 2 + i, y0 + h + 4 + i, tz - 2 + i, tx + 2 - i, y0 + h + 4 + i, tz + 2 - i, Blocks.RED_CONCRETE);
            }
        }
        // Puerta, vidriera rosa (Peach) y estrella encima.
        int front = cz + rz;
        Build.clear(world, cx - 1, y0, front, cx + 1, y0 + 2, front);
        Build.fill(world, cx - 1, y0 + 4, front, cx + 1, y0 + 5, front, Blocks.PINK_STAINED_GLASS);
        Build.set(world, cx, y0 + 6, front, Blocks.GLOWSTONE);
        // Alfombra roja de la entrada.
        Build.fill(world, cx - 1, y0, front + 1, cx + 1, y0, front + 4, Blocks.RED_CARPET);
        sign(world, new BlockPos(cx + 2, y0 + 1, front + 1), Direction.SOUTH, DyeColor.RED, "Castillo de", "elink_64", "¡Here we go!");

        // Pista de baile de "Billie Jean": baldosas que se iluminan.
        for (int x = -3; x <= 3; x++) {
            for (int z = -3; z <= 2; z++) {
                Build.set(world, cx + x, y0 - 1, cz + z, (x + z) % 2 == 0 ? Blocks.GLOWSTONE : Blocks.WHITE_CONCRETE);
            }
        }
        Build.set(world, new BlockPos(cx - rx + 1, y0, cz - rz + 1), Blocks.JUKEBOX.getDefaultState().with(JukeboxBlock.HAS_RECORD, false));
        // Cuadros como los de Mario 64 (portales a los mundos).
        painting(world, new BlockPos(cx - 4, y0 + 2, cz - rz + 1), Direction.SOUTH);
        painting(world, new BlockPos(cx + 4, y0 + 2, cz - rz + 1), Direction.SOUTH);
        painting(world, new BlockPos(cx - rx + 1, y0 + 2, cz), Direction.EAST);
        painting(world, new BlockPos(cx + rx - 1, y0 + 2, cz), Direction.WEST);
        Build.set(world, cx - 6, y0 + h - 1, cz, Blocks.SHROOMLIGHT);
        Build.set(world, cx + 6, y0 + h - 1, cz, Blocks.SHROOMLIGHT);

        Build.spawn(world, ModEntities.ELINK_64, cx + 0.5, y0, cz + 0.5, 4);
        world.getPlayers(p -> p.getBlockPos().isWithinDistance(new BlockPos(cx, y0, cz), 100)).forEach(p ->
                p.sendMessage(Text.literal("¡Un castillo como el de Mario 64! Debe de ser el de elink_64.").formatted(Formatting.RED), false));
    }
}
