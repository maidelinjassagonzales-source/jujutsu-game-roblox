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
            for (int i = 0; i < 3; i++) {
                Build.spawn(can, ModEntities.COCOIDE, -3.5 + i * 2, SEA + 1, -3.5, 7);
            }
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
        if (!state.chapter1Done) {
            player.sendMessage(Text.literal("Los Cocoides hablan de una isla enorme muy lejos al ESTE (X " + CUBA_X + ")...")
                    .formatted(Formatting.AQUA), false);
        }
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

    /** La isla con forma de Cuba, lejos al este, con el edificio espectral del Chamán Cocoide. */
    public static final int CUBA_X = 640, CUBA_Z = 0;

    public static int cubaSpineZ(int x) {
        return CUBA_Z + (int) Math.round(Math.sin((x - CUBA_X) / 45.0) * 22);
    }

    /** Centro del templo (donde está el altar). */
    public static BlockPos templeCenter() {
        return new BlockPos(CUBA_X, SEA + 3, cubaSpineZ(CUBA_X));
    }

    /** Islas nuevas a medida que exploras. */
    public static void tick(ServerWorld world, ServerPlayerEntity player, TurboState state) {
        if (!state.cubaBuilt) {
            double cdx = player.getX() - CUBA_X, cdz = player.getZ() - CUBA_Z;
            if (cdx * cdx + cdz * cdz < 200 * 200) {
                buildCuba(world, Random.create(1959L));
                state.cubaBuilt = true;
                state.markDirty();
                player.sendMessage(Text.literal("Ves en el horizonte una isla larguísima... ¡parece Cuba! En el centro brilla un edificio fantasmal.")
                        .formatted(Formatting.AQUA, Formatting.BOLD), false);
            }
        }
        if (state.cubaBuilt && world.getTime() % 10 == 0) {
            BlockPos t = templeCenter();
            if (player.squaredDistanceTo(t.getX(), t.getY(), t.getZ()) < 40 * 40) {
                world.spawnParticles(net.minecraft.particle.ParticleTypes.SOUL, t.getX() + 0.5, t.getY() + 3, t.getZ() + 0.5, 6, 6, 3, 6, 0.01);
            }
        }
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
                if (Math.abs(x - CUBA_X) < 150 && Math.abs(z - CUBA_Z) < 60) {
                    continue; // ahí va Cuba
                }
                if (random.nextFloat() < 0.75f) {
                    int radius = 4 + random.nextInt(7);
                    island(world, x, z, radius, random);
                    int cocoides = 1 + random.nextInt(2);
                    for (int i = 0; i < cocoides; i++) {
                        Build.spawn(world, ModEntities.COCOIDE, x + 0.5 + i, Build.surface(world, x + i, z), z + 0.5, radius);
                    }
                }
            }
        }
    }

    /** Una isla larga y curvada como Cuba: playas, interior verde, muchas palmeras y el templo espectral. */
    private static void buildCuba(ServerWorld world, Random random) {
        int x1 = CUBA_X - 130, x2 = CUBA_X + 130;
        for (int x = x1; x <= x2; x++) {
            double t = (x - x1) / (double) (x2 - x1);
            // Más ancha al oeste (La Habana) y fina en la punta este.
            int half = (int) Math.round(4 + 14 * Math.sin(Math.PI * Math.pow(t, 0.8)));
            int cz = cubaSpineZ(x);
            for (int dz = -half - 2; dz <= half + 2; dz++) {
                double edge = Math.abs(dz) / (double) (half + 1);
                int top = SEA + (int) Math.round(Math.max(-1, 3.5 * (1 - edge * edge)));
                int z = cz + dz;
                Build.fill(world, x, SEA - 5, z, x, top, z, Blocks.SAND);
                if (top >= SEA + 2) {
                    Build.set(world, x, top, z, Blocks.GRASS_BLOCK);
                    if (random.nextInt(40) == 0) {
                        Build.set(world, x, top + 1, z, random.nextBoolean() ? Blocks.FERN : Blocks.SUGAR_CANE);
                    }
                }
            }
            if (random.nextInt(9) == 0) {
                BlockPos t2 = templeCenter();
                int pz = cz + random.nextInt(half * 2 + 1) - half;
                if (Math.abs(x - t2.getX()) > 12 || Math.abs(pz - t2.getZ()) > 12) {
                    palm(world, x, pz, random);
                }
            }
        }
        buildTemple(world);
        for (int i = 0; i < 6; i++) {
            int x = CUBA_X - 40 + random.nextInt(80);
            int z = cubaSpineZ(x) + random.nextInt(7) - 3;
            Build.spawn(world, ModEntities.COCOIDE, x + 0.5, Build.surface(world, x, z), z + 0.5, 20);
        }
    }

    /** El edificio espectral: cristal fantasmal, columnas de cuarzo, fuego de almas y el altar del ritual. */
    private static void buildTemple(ServerWorld world) {
        BlockPos c = templeCenter();
        int cx = c.getX(), cz = c.getZ(), y = c.getY();
        Build.fill(world, cx - 8, y - 4, cz - 8, cx + 8, y - 1, cz + 8, Blocks.SMOOTH_QUARTZ);
        Build.clear(world, cx - 8, y, cz - 8, cx + 8, y + 12, cz + 8);
        Build.fill(world, cx - 7, y - 1, cz - 7, cx + 7, y - 1, cz + 7, Blocks.WHITE_CONCRETE);
        for (int r = 0; r < 7; r++) {
            Build.fill(world, cx - 6 + r, y + 6 + r, cz - 6 + r, cx + 6 - r, y + 6 + r, cz + 6 - r,
                    r % 2 == 0 ? Blocks.WHITE_STAINED_GLASS : Blocks.LIGHT_BLUE_STAINED_GLASS);
        }
        for (int dx = -6; dx <= 6; dx++) {
            for (int dz = -6; dz <= 6; dz++) {
                boolean wall = Math.abs(dx) == 6 || Math.abs(dz) == 6;
                if (!wall) {
                    continue;
                }
                boolean pillar = Math.abs(dx) == 6 && Math.abs(dz) == 6;
                Build.fill(world, cx + dx, y, cz + dz, cx + dx, y + 5, cz + dz,
                        pillar ? Blocks.QUARTZ_PILLAR : Blocks.LIGHT_GRAY_STAINED_GLASS);
            }
        }
        // Puerta al oeste (por donde se llega desde la lata).
        Build.clear(world, cx - 6, y, cz - 1, cx - 6, y + 2, cz + 1);
        // Altar: lodestone rodeado de fuego de almas.
        Build.set(world, cx, y, cz, Blocks.LODESTONE);
        Build.set(world, cx - 2, y, cz - 2, Blocks.SOUL_CAMPFIRE);
        Build.set(world, cx + 2, y, cz - 2, Blocks.SOUL_CAMPFIRE);
        Build.set(world, cx - 2, y, cz + 2, Blocks.SOUL_CAMPFIRE);
        Build.set(world, cx + 2, y, cz + 2, Blocks.SOUL_CAMPFIRE);
        for (int[] l : new int[][]{{-5, -5}, {5, -5}, {-5, 5}, {5, 5}}) {
            Build.set(world, cx + l[0], y, cz + l[1], Blocks.SOUL_LANTERN);
        }
        Build.set(world, cx, y + 5, cz, Blocks.SEA_LANTERN);
        // El chamán, detrás del altar.
        Build.spawn(world, ModEntities.CHAMAN_COCOIDE, cx + 3.5, y, cz + 0.5, 3);
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
    static void palm(ServerWorld world, int x, int z, Random random) {
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
