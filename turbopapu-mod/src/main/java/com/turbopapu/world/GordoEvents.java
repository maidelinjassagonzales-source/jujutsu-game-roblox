package com.turbopapu.world;

import com.turbopapu.fight.BossFight;
import com.turbopapu.fight.PvzArcade;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Block;
import net.minecraft.block.Blocks;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.random.Random;
import net.minecraft.world.World;

import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.UUID;

/**
 * El Gordo Pañales: hay que darle mantequilla cada día de Minecraft. El día que no se la das,
 * screamer, te come y apareces en su mundo estomacal. Se sale subiendo hasta la garganta.
 */
public final class GordoEvents {
    /** Centro del estómago, radios, nivel del ácido y plataforma de la garganta. */
    private static final int SX = 0, SZ = 0, CY = 70;
    private static final int RX = 15, RY = 12, RZ = 20;
    private static final int FLOOR = CY - 6;
    private static final int THROAT_Y = CY + 8, THROAT_Z = SZ + 4;
    private static final double ARRIVAL_Z = SZ - 9.5;
    private static final int SCREAMER_TICKS = 50;

    /** Jugadores con el screamer en pantalla, esperando a ser tragados (ticks restantes). */
    private static final Map<UUID, Integer> SWALLOWING = new HashMap<>();

    private GordoEvents() {}

    public static long today(MinecraftServer server) {
        return server.getOverworld().getTimeOfDay() / 24000L;
    }

    /** Al hablar por primera vez: empieza a contar desde hoy. */
    public static void meet(ServerPlayerEntity player) {
        TurboState state = TurboState.get(player.getServer());
        state.gordoFedDay.putIfAbsent(player.getUuid(), today(player.getServer()));
        state.markDirty();
    }

    /** Devuelve true si se la ha comido (false si ya comió hoy). */
    public static boolean feed(ServerPlayerEntity player) {
        TurboState state = TurboState.get(player.getServer());
        long day = today(player.getServer());
        Long last = state.gordoFedDay.get(player.getUuid());
        if (last != null && last >= day) {
            return false;
        }
        state.gordoFedDay.put(player.getUuid(), day);
        state.markDirty();
        return true;
    }

    public static void tick(MinecraftServer server) {
        TurboState state = TurboState.get(server);
        tickSwallowing(server, state);
        ServerWorld stomach = server.getWorld(ModDimensions.ESTOMAGO);
        if (stomach != null) {
            for (ServerPlayerEntity player : stomach.getPlayers()) {
                tickInStomach(server, stomach, player, state);
            }
        }
        if (server.getTicks() % 100 != 0 || state.gordoFedDay.isEmpty()) {
            return;
        }
        long day = today(server);
        for (ServerPlayerEntity player : server.getPlayerManager().getPlayerList()) {
            Long last = state.gordoFedDay.get(player.getUuid());
            if (last == null || last >= day - 1 || SWALLOWING.containsKey(player.getUuid())
                    || player.getWorld().getRegistryKey() == ModDimensions.ESTOMAGO || player.isSpectator()
                    || BossFight.current() != null || PvzArcade.isActive()) {
                continue;
            }
            // Ayer no hubo mantequilla.
            state.gordoFedDay.put(player.getUuid(), day - 1);
            state.markDirty();
            scream(player);
        }
    }

    private static void scream(ServerPlayerEntity player) {
        SWALLOWING.put(player.getUuid(), SCREAMER_TICKS);
        ModPackets.screamer(player);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.SLOWNESS, SCREAMER_TICKS + 10, 9, false, false));
    }

    private static void tickSwallowing(MinecraftServer server, TurboState state) {
        Iterator<Map.Entry<UUID, Integer>> it = SWALLOWING.entrySet().iterator();
        while (it.hasNext()) {
            Map.Entry<UUID, Integer> e = it.next();
            ServerPlayerEntity player = server.getPlayerManager().getPlayer(e.getKey());
            if (player == null) {
                it.remove();
                continue;
            }
            int left = e.getValue() - 1;
            if (left > 0) {
                e.setValue(left);
                continue;
            }
            it.remove();
            swallow(server, player, state);
        }
    }

    private static void swallow(MinecraftServer server, ServerPlayerEntity player, TurboState state) {
        ServerWorld stomach = server.getWorld(ModDimensions.ESTOMAGO);
        if (stomach == null) {
            return;
        }
        if (!state.stomachBuilt) {
            buildStomach(stomach);
            state.stomachBuilt = true;
            state.markDirty();
        }
        player.getWorld().playSound(null, player.getBlockPos(), SoundEvents.ENTITY_GENERIC_EAT, SoundCategory.HOSTILE, 3f, 0.4f);
        player.teleport(stomach, SX + 0.5, FLOOR + 1, ARRIVAL_Z, 0, 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.NAUSEA, 200, 0, false, false));
        stomach.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_PLAYER_BURP, SoundCategory.HOSTILE, 3f, 0.3f);
        ModPackets.dialogue(player, "estomago_llegada", 0, -1);
    }

    private static void tickInStomach(MinecraftServer server, ServerWorld stomach, ServerPlayerEntity player, TurboState state) {
        if (player.isSpectator()) {
            return;
        }
        // Ácido gástrico.
        if (player.isTouchingWater() && player.age % 20 == 0) {
            player.addStatusEffect(new StatusEffectInstance(StatusEffects.POISON, 60, 0));
        }
        if (stomach.getTime() % 160 == 0) {
            stomach.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_GHAST_HURT, SoundCategory.AMBIENT, 0.6f, 0.2f);
        }
        // La garganta: al llegar arriba, el gordo te vomita.
        double dx = player.getX() - (SX + 0.5), dz = player.getZ() - (THROAT_Z + 0.5);
        if (player.getY() >= THROAT_Y - 0.5 && dx * dx + dz * dz < 9) {
            vomit(server, player, state);
        }
        // Por si alguien se sale del estómago.
        if (player.getY() < FLOOR - 20) {
            player.teleport(stomach, SX + 0.5, FLOOR + 1, ARRIVAL_Z, 0, 0);
        }
    }

    private static void vomit(MinecraftServer server, ServerPlayerEntity player, TurboState state) {
        ServerWorld overworld = server.getOverworld();
        BlockPos target;
        if (state.gordoSpawned) {
            target = overworld.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES,
                    new BlockPos(state.gordoX + 3, 64, state.gordoZ + 3));
        } else {
            target = overworld.getSpawnPos();
        }
        player.teleport(overworld, target.getX() + 0.5, target.getY() + 1, target.getZ() + 0.5, player.getYaw(), 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.NAUSEA, 160, 0, false, false));
        overworld.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_PLAYER_BURP, SoundCategory.HOSTILE, 2f, 0.5f);
        overworld.spawnParticles(net.minecraft.particle.ParticleTypes.ITEM_SLIME, player.getX(), player.getY() + 1, player.getZ(), 40, 0.6, 0.6, 0.6, 0.2);
        player.sendMessage(Text.literal("¡BUAAARGH! El Gordo Pañales te ha vomitado. Mañana no te olvides de la mantequilla...")
                .formatted(Formatting.GOLD), false);
    }

    /** Estómago: una gran cueva de carne con ácido en el fondo, costillas para escalar y la garganta arriba. */
    private static void buildStomach(ServerWorld world) {
        Random random = Random.create(1234L);
        Block[] flesh = {Blocks.PINK_TERRACOTTA, Blocks.RED_TERRACOTTA, Blocks.PINK_WOOL, Blocks.NETHER_WART_BLOCK, Blocks.PINK_CONCRETE};
        for (int x = -RX - 1; x <= RX + 1; x++) {
            for (int y = -RY - 1; y <= RY + 1; y++) {
                for (int z = -RZ - 1; z <= RZ + 1; z++) {
                    double d = sq(x, RX) + sq(y, RY) + sq(z, RZ);
                    double inner = sq(x, RX - 1.2) + sq(y, RY - 1.2) + sq(z, RZ - 1.2);
                    BlockPos pos = new BlockPos(SX + x, CY + y, SZ + z);
                    if (d <= 1.0 && inner > 1.0) {
                        Block b = random.nextInt(14) == 0 ? Blocks.SHROOMLIGHT : flesh[random.nextInt(flesh.length)];
                        Build.set(world, pos, b.getDefaultState());
                    } else if (inner <= 1.0) {
                        Build.set(world, pos, (CY + y <= FLOOR ? Blocks.WATER : Blocks.AIR).getDefaultState());
                    }
                }
            }
        }
        // Isla de llegada y cosas que se ha tragado.
        int az = (int) Math.floor(ARRIVAL_Z);
        Build.fill(world, SX - 3, FLOOR - 6, az - 2, SX + 3, FLOOR, az + 2, Blocks.PINK_TERRACOTTA);
        Build.fill(world, SX - 3, FLOOR + 1, az - 2, SX - 2, FLOOR + 2, az - 1, Blocks.YELLOW_CONCRETE);
        Build.set(world, SX + 3, FLOOR + 1, az - 2, Blocks.BONE_BLOCK);
        Build.set(world, SX + 3, FLOOR + 2, az - 2, Blocks.BONE_BLOCK);
        for (int i = 0; i < 12; i++) {
            int x = SX - 8 + random.nextInt(17), z = SZ - 6 + random.nextInt(17);
            Build.set(world, x, FLOOR, z, random.nextBoolean() ? Blocks.YELLOW_CONCRETE : Blocks.BONE_BLOCK);
        }
        // Costillas: escalones de hueso que suben en zigzag desde la isla hasta la garganta.
        int steps = THROAT_Y - FLOOR - 1;
        for (int i = 0; i < steps; i++) {
            int y = FLOOR + 1 + i;
            int z = az + 3 + i * (THROAT_Z - 2 - az - 3) / steps;
            int x = SX + (i % 2 == 0 ? -1 : 1);
            Build.fill(world, x - 1, y, z - 1, x + 1, y, z + 1, Blocks.BONE_BLOCK);
        }
        // Garganta: plataforma con luz y un agujero hacia arriba.
        Build.fill(world, SX - 2, THROAT_Y - 1, THROAT_Z - 2, SX + 2, THROAT_Y - 1, THROAT_Z + 2, Blocks.BONE_BLOCK);
        Build.set(world, SX, THROAT_Y - 1, THROAT_Z, Blocks.SHROOMLIGHT);
        Build.fill(world, SX - 1, THROAT_Y, THROAT_Z - 1, SX + 1, CY + RY + 2, THROAT_Z + 1, Blocks.AIR);
        Build.fill(world, SX - 2, CY + RY + 3, THROAT_Z - 2, SX + 2, CY + RY + 3, THROAT_Z + 2, Blocks.RED_TERRACOTTA);
        // Unas salchichas que también se tragó.
        for (int i = 0; i < 4; i++) {
            Build.spawn(world, ModEntities.SALCHICHA, SX - 1.5 + i, FLOOR + 1, ARRIVAL_Z, 0);
        }
    }

    private static final Map<UUID, Long> POOP_COOLDOWN = new HashMap<>();

    /** Con el pañal puesto (tecla G): te cagas encima. Asquea a los de alrededor y sales disparado. */
    public static void poop(ServerPlayerEntity player) {
        net.minecraft.item.ItemStack legs = player.getEquippedStack(net.minecraft.entity.EquipmentSlot.LEGS);
        if (!legs.isOf(com.turbopapu.registry.ModItems.PANAL) || player.isSpectator()) {
            return;
        }
        ServerWorld world = player.getServerWorld();
        long now = world.getTime();
        Long last = POOP_COOLDOWN.get(player.getUuid());
        if (last != null && now - last < 100) {
            return;
        }
        POOP_COOLDOWN.put(player.getUuid(), now);
        net.minecraft.particle.DustParticleEffect brown = new net.minecraft.particle.DustParticleEffect(new org.joml.Vector3f(0.4f, 0.25f, 0.1f), 2f);
        world.spawnParticles(brown, player.getX(), player.getY() + 0.5, player.getZ(), 60, 0.5, 0.3, 0.5, 0);
        world.spawnParticles(net.minecraft.particle.ParticleTypes.SNEEZE, player.getX(), player.getY() + 0.4, player.getZ(), 30, 1.2, 0.3, 1.2, 0.02);
        world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_SLIME_SQUISH, SoundCategory.PLAYERS, 1.5f, 0.5f);
        world.playSound(null, player.getBlockPos(), SoundEvents.BLOCK_HONEY_BLOCK_BREAK, SoundCategory.PLAYERS, 1.5f, 0.6f);
        for (net.minecraft.entity.LivingEntity near : world.getEntitiesByClass(net.minecraft.entity.LivingEntity.class,
                player.getBoundingBox().expand(6), e -> e != player)) {
            near.addStatusEffect(new StatusEffectInstance(StatusEffects.NAUSEA, 200, 0));
            near.addStatusEffect(new StatusEffectInstance(StatusEffects.SLOWNESS, 120, 2));
            near.addStatusEffect(new StatusEffectInstance(StatusEffects.WEAKNESS, 200, 1));
            if (near instanceof net.minecraft.entity.mob.MobEntity mob) {
                net.minecraft.util.math.Vec3d away = near.getPos().subtract(player.getPos()).normalize().multiply(0.8);
                mob.addVelocity(away.x, 0.3, away.z);
            }
        }
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.SPEED, 100, 2, false, false, true));
        player.sendMessage(Text.literal("💩 ¡Te has cagado encima! Todos huyen del olor...").formatted(Formatting.GOLD), true);
        legs.damage(1, player, p -> p.sendEquipmentBreakStatus(net.minecraft.entity.EquipmentSlot.LEGS));
    }

    private static double sq(double v, double r) {
        return (v * v) / (r * r);
    }
}
