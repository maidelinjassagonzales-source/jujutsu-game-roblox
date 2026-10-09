package com.turbopapu.world;

import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Blocks;
import net.minecraft.block.CocoaBlock;
import net.minecraft.block.LeavesBlock;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.registry.RegistryKey;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.ChunkPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.random.Random;
import net.minecraft.world.World;

import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * El mundo dentro de la lata de leche de coco de Aroy: un mar infinito de agua de coco con islitas de arena
 * y palmeras cocoteras. Se entra agachándose y haciendo clic derecho en Aroy; dentro, Aroy te saca.
 */
public final class CoconutWorld {
    /** Superficie del agua (bedrock + 3 arena + 30 agua). */
    private static final int SEA = 33;
    private static final int CELL = 96;
    private static final int MARGIN = 20;
    private static final int BUILD_DISTANCE = 80;

    /** De dónde vino cada jugador, para devolverlo al salir. */
    private static final Map<UUID, Object[]> RETURN = new HashMap<>();

    private CoconutWorld() {}

    public static void enter(ServerPlayerEntity player) {
        ServerWorld can = player.getServer().getWorld(ModDimensions.LATA_COCO);
        if (can == null || player.getWorld() == can) {
            return;
        }
        TurboState state = TurboState.get(player.getServer());
        if (!state.canWorldBuilt) {
            island(can, 0, 0, 9, Random.create(99L));
            Build.spawn(can, ModEntities.AROY, 3.5, SEA + 1, 0.5, 6);
            state.canWorldBuilt = true;
            state.builtCanIslands.add(ChunkPos.toLong(0, 0));
            state.markDirty();
        }
        RETURN.put(player.getUuid(), new Object[]{player.getWorld().getRegistryKey(), player.getX(), player.getY(), player.getZ()});
        player.getWorld().playSound(null, player.getBlockPos(), SoundEvents.ITEM_BUCKET_EMPTY, SoundCategory.PLAYERS, 1.5f, 0.6f);
        player.teleport(can, 0.5, SEA + 2, 0.5, 0, 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.WATER_BREATHING, 20 * 60 * 5, 0, false, true, true));
        player.sendMessage(Text.literal("¡Te has metido dentro de la lata de leche de coco de Aroy! Todo es agua de coco...")
                .formatted(Formatting.GOLD), false);
    }

    @SuppressWarnings("unchecked")
    public static void leave(ServerPlayerEntity player) {
        if (player.getWorld().getRegistryKey() != ModDimensions.LATA_COCO) {
            return;
        }
        Object[] back = RETURN.remove(player.getUuid());
        ServerWorld world = back == null ? null : player.getServer().getWorld((RegistryKey<World>) back[0]);
        if (world == null) {
            world = player.getServer().getOverworld();
            BlockPos spawn = world.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES, world.getSpawnPos());
            back = new Object[]{null, spawn.getX() + 0.5, (double) spawn.getY(), spawn.getZ() + 0.5};
        }
        player.teleport(world, (double) back[1], (double) back[2], (double) back[3], player.getYaw(), 0);
        world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_PLAYER_SPLASH, SoundCategory.PLAYERS, 1.2f, 1f);
        player.sendMessage(Text.literal("Sales de la lata empapado en leche de coco. Hueles de maravilla.").formatted(Formatting.YELLOW), false);
    }

    /** Islas nuevas a medida que exploras. */
    public static void tick(ServerWorld world, ServerPlayerEntity player, TurboState state) {
        int pcx = Math.floorDiv((int) player.getX(), CELL);
        int pcz = Math.floorDiv((int) player.getZ(), CELL);
        for (int cx = pcx - 1; cx <= pcx + 1; cx++) {
            for (int cz = pcz - 1; cz <= pcz + 1; cz++) {
                long key = ChunkPos.toLong(cx, cz);
                if (state.builtCanIslands.contains(key)) {
                    continue;
                }
                Random random = Random.create(world.getSeed() + cx * 31337L + cz * 7331L);
                int x = cx * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                int z = cz * CELL + MARGIN + random.nextInt(CELL - 2 * MARGIN);
                double dx = player.getX() - x, dz = player.getZ() - z;
                if (dx * dx + dz * dz > (double) BUILD_DISTANCE * BUILD_DISTANCE) {
                    continue;
                }
                state.builtCanIslands.add(key);
                state.markDirty();
                if (random.nextFloat() < 0.75f) {
                    island(world, x, z, 4 + random.nextInt(7), random);
                }
            }
        }
    }

    /** Isla redonda de arena con 1-3 palmeras cocoteras. */
    private static void island(ServerWorld world, int x, int z, int radius, Random random) {
        for (int dx = -radius - 2; dx <= radius + 2; dx++) {
            for (int dz = -radius - 2; dz <= radius + 2; dz++) {
                double d = Math.sqrt(dx * dx + dz * dz);
                if (d > radius + 1.5) {
                    continue;
                }
                // Cúpula: más alta en el centro y se hunde hacia la orilla.
                int top = SEA + (int) Math.round(Math.max(-1, 2.5 * (1 - d / (radius + 1))));
                Build.fill(world, x + dx, 4, z + dz, x + dx, top, z + dz, Blocks.SAND);
            }
        }
        int palms = 1 + random.nextInt(Math.max(1, Math.min(3, radius / 3)));
        for (int i = 0; i < palms; i++) {
            int px = x + random.nextInt(radius) - radius / 2, pz = z + random.nextInt(radius) - radius / 2;
            palm(world, px, pz, random);
        }
    }

    /** Palmera: tronco que se inclina un poco, copa en estrella y cocos (cacao maduro) colgando. */
    private static void palm(ServerWorld world, int x, int z, Random random) {
        int y = Build.surface(world, x, z);
        int height = 6 + random.nextInt(3);
        Direction lean = Direction.Type.HORIZONTAL.random(random);
        int tx = x, tz = z;
        for (int i = 0; i < height; i++) {
            if (i == height / 2) {
                tx += lean.getOffsetX();
                tz += lean.getOffsetZ();
            }
            Build.set(world, tx, y + i, tz, Blocks.JUNGLE_LOG);
        }
        int top = y + height;
        var leaves = Blocks.JUNGLE_LEAVES.getDefaultState().with(LeavesBlock.PERSISTENT, true);
        Build.set(world, new BlockPos(tx, top, tz), leaves);
        for (Direction dir : Direction.Type.HORIZONTAL) {
            for (int r = 1; r <= 3; r++) {
                int lx = tx + dir.getOffsetX() * r, lz = tz + dir.getOffsetZ() * r;
                Build.set(world, new BlockPos(lx, r == 3 ? top - 1 : top, lz), leaves);
            }
            int dx = dir.getOffsetX() + dir.rotateYClockwise().getOffsetX(), dz = dir.getOffsetZ() + dir.rotateYClockwise().getOffsetZ();
            Build.set(world, new BlockPos(tx + dx, top, tz + dz), leaves);
            Build.set(world, new BlockPos(tx + dx * 2, top - 1, tz + dz * 2), leaves);
            // Cocos colgando del tronco, debajo de la copa.
            if (random.nextInt(3) != 0) {
                BlockPos coco = new BlockPos(tx + dir.getOffsetX(), top - 2, tz + dir.getOffsetZ());
                Build.set(world, coco, Blocks.COCOA.getDefaultState().with(CocoaBlock.FACING, dir.getOpposite()).with(CocoaBlock.AGE, 2));
            }
        }
    }
}
