package com.turbopapu.fight;

import com.turbopapu.entity.PapuNpcEntity;
import com.turbopapu.entity.SualenidusEntity;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModEntities;
import com.turbopapu.registry.ModItems;
import com.turbopapu.world.TurboState;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.decoration.ArmorStandEntity;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.item.ItemStack;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.packet.s2c.play.SubtitleS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleFadeS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleS2CPacket;
import net.minecraft.particle.DustParticleEffect;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.Vec3d;
import org.joml.Vector3f;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.UUID;

/**
 * La pelea final contra Sualenidus, por fases:
 * <ol>
 *   <li>RING: combate normal de Minecraft en un ring de boxeo.</li>
 *   <li>VALORANT: "¡ESTE NO ES MI JUEGO!" — te lleva a un mapa de Valorant con una Vandal.
 *       La Spike está plantada: impide que Sualenidus la desactive hasta que explote.</li>
 *   <li>ALMAS: se enfada otra vez y, como en Deltarune, aparecen todos los amigos a tu alrededor
 *       y te prestan su poder.</li>
 *   <li>PVZ: Plantas vs Zombies con los amigos como plantas contra hordas de Sualems.</li>
 * </ol>
 */
public class BossFight {
    public enum Phase { RING, TO_VALORANT, VALORANT_PREP, VALORANT, SOULS, PVZ }

    public static final int SPIKE_TICKS = 45 * 20;
    public static final int DEFUSE_TICKS = 7 * 20;

    private static BossFight current;
    private static boolean pvzDamageFlag;

    private final ServerWorld world;
    private UUID bossId;
    private int missingBossTicks;
    /** Mantiene cargadas las arenas lejanas mientras Sualenidus está en ellas (si no, se pierde al teletransportarlo). */
    private static final net.minecraft.server.world.ChunkTicketType<net.minecraft.util.math.ChunkPos> FIGHT_TICKET =
            net.minecraft.server.world.ChunkTicketType.create("turbopapu_pelea", java.util.Comparator.comparingLong(net.minecraft.util.math.ChunkPos::toLong), 20 * 30);
    private final Set<UUID> players = new LinkedHashSet<>();
    private Phase phase = Phase.RING;
    private int phaseTicks;
    private int ringY;

    // Valorant
    private int spikeTicks;
    private int defuse;
    private int round = 1;
    private int stunTicks;
    private int punchCooldown;

    // Almas
    private final List<Entity> souls = new ArrayList<>();
    private boolean soulsReady;

    // PvZ
    private PvzGame pvz;
    private ArmorStandEntity camera;

    private int absentTicks;

    private BossFight(ServerWorld world, SualenidusEntity boss, int ringY) {
        this.world = world;
        this.bossId = boss.getUuid();
        this.ringY = ringY;
    }

    // ------------------------------------------------------------ API estática

    public static BossFight current() {
        return current;
    }

    public static boolean isPvzActive() {
        return (current != null && current.phase == Phase.PVZ) || PvzArcade.isActive();
    }

    public static boolean isPvzDamage() {
        return PvzGame.isDamaging();
    }

    public static BossFight forBoss(SualenidusEntity boss) {
        return current != null && current.bossId.equals(boss.getUuid()) ? current : null;
    }

    /** ¿Está este jugador protegido de morir? (en Valorant reaparece, en las almas y PvZ no puede morir). */
    public static boolean protects(ServerPlayerEntity player) {
        return current != null && current.players.contains(player.getUuid()) && current.phase != Phase.RING;
    }

    public static void onPlayerSaved(ServerPlayerEntity player) {
        if (current == null) {
            return;
        }
        player.setHealth(player.getMaxHealth());
        player.clearStatusEffects();
        if (current.phase == Phase.VALORANT || current.phase == Phase.VALORANT_PREP) {
            BlockPos spawn = Arenas.valPlayerSpawn();
            player.teleport(current.world, spawn.getX() + 0.5, spawn.getY(), spawn.getZ() + 0.5, 90, 0);
            current.defuse = Math.min(DEFUSE_TICKS - 1, current.defuse + 40);
            player.sendMessage(Text.literal("¡Te han eliminado! Reapareces... y Sualenidus avanza con la Spike.").formatted(Formatting.RED), false);
        }
    }

    /** Llamado por la Vandal al acertar. Interrumpe el desactivado. */
    public static void onShot(LivingEntity target) {
        if (current != null && target instanceof SualenidusEntity boss && boss.getUuid().equals(current.bossId)) {
            current.interruptDefuse();
        }
    }

    public static void onDialogueAction(ServerPlayerEntity player, String action) {
        if ("almas_listas".equals(action) && current != null && current.phase == Phase.SOULS) {
            current.soulsReady = true;
        }
    }

    public static void pvzPlace(ServerPlayerEntity player, int col, int row, int type) {
        if (current != null && current.pvz != null && current.phase == Phase.PVZ) {
            current.pvz.place(player, col, row, type);
        } else {
            PvzArcade.place(player, col, row, type);
        }
    }

    public static void pvzShovel(ServerPlayerEntity player, int col, int row) {
        if (current != null && current.pvz != null && current.phase == Phase.PVZ) {
            current.pvz.shovel(col, row);
        } else {
            PvzArcade.shovel(player, col, row);
        }
    }

    // ------------------------------------------------------------ daño al jefe

    /** Ajusta el daño que recibe el jefe según la fase. Devuelve el daño final (0 = ignorar). */
    public float filterBossDamage(SualenidusEntity boss, float amount) {
        float max = boss.getMaxHealth();
        switch (phase) {
            case RING -> {
                float floor = max * 0.66f;
                if (boss.getHealth() - amount <= floor) {
                    amount = Math.max(0, boss.getHealth() - floor);
                    startToValorant(boss);
                }
                return amount;
            }
            case VALORANT -> {
                interruptDefuse();
                float floor = max * 0.34f;
                return Math.max(0, Math.min(amount, boss.getHealth() - floor));
            }
            case PVZ -> {
                return PvzGame.isDamaging() ? amount : 0;
            }
            default -> {
                return 0;
            }
        }
    }

    public void onBossDeath(SualenidusEntity boss) {
        endPvzForClients();
        TurboState state = TurboState.get(world.getServer());
        for (ServerPlayerEntity p : participants()) {
            p.teleport(world, 0.5, state.villageY + 1, 6.5, 180, 0);
        }
        if (pvz != null) {
            pvz.clear();
        }
        clearSouls();
        current = null;
    }

    // ------------------------------------------------------------ tick

    public static void tick(MinecraftServer server) {
        ServerWorld planet = server.getWorld(ModDimensions.PLANETA);
        if (planet == null) {
            return;
        }
        TurboState state = TurboState.get(server);
        if (current == null) {
            if (!state.lairBuilt || state.sualenidusDefeated || planet.getTime() % 10 != 0) {
                return;
            }
            tryStart(planet, state);
            return;
        }
        current.tickFight();
    }

    /** Si alguien pega al jefe antes de entrar al ring, la pelea empieza igualmente. */
    public static void ensureFight(SualenidusEntity boss) {
        if (current != null || !(boss.getWorld() instanceof ServerWorld world) || world.getRegistryKey() != ModDimensions.PLANETA) {
            return;
        }
        TurboState state = TurboState.get(world.getServer());
        if (!state.ringBuilt) {
            return;
        }
        current = new BossFight(world, boss, state.ringY);
        current.begin();
    }

    private static void tryStart(ServerWorld planet, TurboState state) {
        for (ServerPlayerEntity player : planet.getPlayers()) {
            double dx = player.getX() - TurboState.LAIR_X, dz = player.getZ() - TurboState.LAIR_Z;
            if (dx * dx + dz * dz > 80 * 80) {
                continue;
            }
            if (!state.ringBuilt) {
                state.ringY = Arenas.buildRing(planet, Arenas.lairFloor(planet));
                state.ringBuilt = true;
                state.markDirty();
            }
            List<SualenidusEntity> bosses = planet.getEntitiesByClass(SualenidusEntity.class,
                    new Box(player.getBlockPos()).expand(4000, 200, 4000), e -> e.isAlive());
            if (bosses.isEmpty()) {
                return;
            }
            SualenidusEntity boss = bosses.get(0);
            if (boss.squaredDistanceTo(TurboState.LAIR_X, state.ringY, TurboState.LAIR_Z) > 12 * 12) {
                // Vuelve a su ring (por ejemplo, tras reiniciar el servidor a mitad de pelea).
                boss.refreshPositionAndAngles(TurboState.LAIR_X + 0.5, state.ringY, TurboState.LAIR_Z - 2.5, 0, 0);
                boss.setHealth(boss.getMaxHealth());
                setScripted(boss, false);
                boss.setAiDisabled(false);
            }
            if (Arenas.insideRing(player.getX(), player.getY(), player.getZ(), state.ringY)) {
                current = new BossFight(planet, boss, state.ringY);
                current.begin();
                return;
            }
        }
    }

    private void begin() {
        for (ServerPlayerEntity p : world.getPlayers(p -> p.squaredDistanceTo(TurboState.LAIR_X, ringY, TurboState.LAIR_Z) < 40 * 40)) {
            players.add(p.getUuid());
        }
        SualenidusEntity boss = boss();
        if (boss != null) {
            boss.setInvulnerable(false);
            setScripted(boss, false);
        }
        title("ROUND 1", "¡FIGHT!", Formatting.GOLD);
        world.playSound(null, TurboState.LAIR_X, ringY, TurboState.LAIR_Z, SoundEvents.BLOCK_BELL_USE, SoundCategory.HOSTILE, 3f, 1f);
        world.playSound(null, TurboState.LAIR_X, ringY, TurboState.LAIR_Z, SoundEvents.BLOCK_BELL_USE, SoundCategory.HOSTILE, 3f, 1f);
        broadcast(Text.literal("¡Damas y caballeros! En la esquina roja... ¡el terrícola! En la esquina azul... ¡SUALENIDUS!").formatted(Formatting.GOLD));
    }

    private void keepLoaded(double x, double z) {
        net.minecraft.util.math.ChunkPos cp = new net.minecraft.util.math.ChunkPos(BlockPos.ofFloored(x, 0, z));
        world.getChunkManager().addTicket(FIGHT_TICKET, cp, 3, cp);
        world.getChunk(cp.x, cp.z);
    }

    /** Teletransporta a Sualenidus cargando antes el sitio de destino. */
    void moveBoss(SualenidusEntity boss, double x, double y, double z, float yaw) {
        keepLoaded(x, z);
        boss.refreshPositionAndAngles(x, y, z, yaw, 0);
        boss.setHeadYaw(yaw);
        boss.setBodyYaw(yaw);
        boss.getNavigation().stop();
    }

    private SualenidusEntity respawnBoss() {
        SualenidusEntity boss = ModEntities.SUALENIDUS.create(world);
        if (boss == null) {
            return null;
        }
        double x, y, z;
        float yaw;
        switch (phase) {
            case SOULS, PVZ -> {
                x = Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 7;
                y = Arenas.LAWN_Y;
                z = Arenas.rowZ(2);
                yaw = 90;
            }
            case VALORANT, VALORANT_PREP -> {
                BlockPos b = Arenas.valBossSpawn();
                x = b.getX() + 0.5;
                y = b.getY();
                z = b.getZ() + 0.5;
                yaw = -90;
            }
            default -> {
                x = TurboState.LAIR_X + 0.5;
                y = ringY;
                z = TurboState.LAIR_Z - 2.5;
                yaw = 0;
            }
        }
        keepLoaded(x, z);
        boss.refreshPositionAndAngles(x, y, z, yaw, 0);
        boss.setPersistent();
        world.spawnEntity(boss);
        if (phase != Phase.RING) {
            boss.setHealth(boss.getMaxHealth() * 0.3f);
            setScripted(boss, true);
        }
        bossId = boss.getUuid();
        return boss;
    }

    public SualenidusEntity boss() {
        return world.getEntity(bossId) instanceof SualenidusEntity b ? b : null;
    }

    public List<ServerPlayerEntity> participants() {
        List<ServerPlayerEntity> list = new ArrayList<>();
        for (UUID id : players) {
            if (world.getPlayerByUuid(id) instanceof ServerPlayerEntity p && p.isAlive()) {
                list.add(p);
            }
        }
        return list;
    }

    private void tickFight() {
        phaseTicks++;
        SualenidusEntity boss = boss();
        List<ServerPlayerEntity> ps = participants();
        if (ps.isEmpty()) {
            if (++absentTicks > 200) {
                cancel(boss);
            }
            return;
        }
        absentTicks = 0;
        if (boss == null) {
            // Si Sualenidus se perdió por el camino (chunk sin cargar), vuelve a aparecer donde toca.
            if (phase != Phase.RING && ++missingBossTicks > 40) {
                boss = respawnBoss();
            }
            if (boss == null) {
                return;
            }
        }
        missingBossTicks = 0;
        if (phase != Phase.RING && world.getTime() % 100 == 0) {
            keepLoaded(boss.getX(), boss.getZ());
        }
        switch (phase) {
            case RING -> {
                // Combate normal. El cambio de fase lo dispara filterBossDamage.
            }
            case TO_VALORANT -> tickToValorant(boss, ps);
            case VALORANT_PREP -> {
                if (phaseTicks >= 100) {
                    phase = Phase.VALORANT;
                    phaseTicks = 0;
                    setScripted(boss, true);
                    title("RONDA " + round, "¡Defiende la Spike!", Formatting.RED);
                }
            }
            case VALORANT -> tickValorant(boss, ps);
            case SOULS -> tickSouls(boss, ps);
            case PVZ -> {
                pvz.tick();
                boss.setAiDisabled(false);
            }
        }
        if (world.getTime() % 4 == 0) {
            for (ServerPlayerEntity p : ps) {
                ModPackets.fightState(p, this);
            }
        }
    }

    private void cancel(SualenidusEntity boss) {
        if (boss != null) {
            boss.setHealth(boss.getMaxHealth());
            setScripted(boss, false);
            boss.setAiDisabled(false);
            moveBoss(boss, TurboState.LAIR_X + 0.5, ringY, TurboState.LAIR_Z - 2.5, 0);
        }
        if (pvz != null) {
            pvz.clear();
        }
        endPvzForClients();
        clearSouls();
        current = null;
    }

    // ------------------------------------------------------------ fase 2: Valorant

    private void startToValorant(SualenidusEntity boss) {
        phase = Phase.TO_VALORANT;
        phaseTicks = 0;
        setScripted(boss, true);
        for (ServerPlayerEntity p : participants()) {
            ModPackets.dialogue(p, "sualenidus_fase2", 0, boss.getId());
            ModPackets.glitch(p);
        }
        world.playSound(null, boss.getX(), boss.getY(), boss.getZ(), SoundEvents.ENTITY_WITHER_SPAWN, SoundCategory.HOSTILE, 2f, 1.5f);
    }

    private void tickToValorant(SualenidusEntity boss, List<ServerPlayerEntity> ps) {
        boss.getNavigation().stop();
        world.spawnParticles(new DustParticleEffect(new Vector3f(1f, 0.27f, 0.33f), 2f), boss.getX(), boss.getY() + 3, boss.getZ(), 10, 2, 2, 2, 0);
        if (phaseTicks == 60) {
            for (ServerPlayerEntity p : ps) {
                ModPackets.glitch(p);
            }
        }
        if (phaseTicks < 80) {
            return;
        }
        TurboState state = TurboState.get(world.getServer());
        if (!state.valorantBuilt) {
            Arenas.buildValorant(world);
            state.valorantBuilt = true;
            state.markDirty();
        }
        BlockPos spawn = Arenas.valPlayerSpawn();
        for (ServerPlayerEntity p : ps) {
            p.teleport(world, spawn.getX() + 0.5, spawn.getY(), spawn.getZ() + 0.5, 90, 0);
            p.setHealth(p.getMaxHealth());
            if (!p.getInventory().containsAny(s -> s.isOf(ModItems.VANDAL))) {
                p.giveItemStack(new ItemStack(ModItems.VANDAL));
            }
            ModPackets.dialogue(p, "valorant_intro", 0, -1);
        }
        placeSpike();
        resetRound(boss);
        phase = Phase.VALORANT_PREP;
        phaseTicks = 0;
    }

    private void placeSpike() {
        BlockPos spike = Arenas.valSpike();
        world.setBlockState(spike, net.minecraft.block.Blocks.RESPAWN_ANCHOR.getDefaultState()
                .with(net.minecraft.block.RespawnAnchorBlock.CHARGES, 4));
    }

    private void resetRound(SualenidusEntity boss) {
        BlockPos b = Arenas.valBossSpawn();
        moveBoss(boss, b.getX() + 0.5, b.getY(), b.getZ() + 0.5, -90);
        boss.getNavigation().stop();
        spikeTicks = SPIKE_TICKS;
        defuse = 0;
        stunTicks = 0;
    }

    private void interruptDefuse() {
        if (phase != Phase.VALORANT || defuse <= 0) {
            return;
        }
        defuse = defuse >= DEFUSE_TICKS / 2 ? DEFUSE_TICKS / 2 : 0;
        stunTicks = 15;
        SualenidusEntity boss = boss();
        if (boss != null) {
            world.playSound(null, boss.getX(), boss.getY(), boss.getZ(), SoundEvents.ENTITY_RAVAGER_STUNNED, SoundCategory.HOSTILE, 1.5f, 1.2f);
        }
    }

    private void tickValorant(SualenidusEntity boss, List<ServerPlayerEntity> ps) {
        BlockPos spike = Arenas.valSpike();
        // La Spike pita cada vez más rápido.
        int beep = spikeTicks > 400 ? 20 : spikeTicks > 200 ? 10 : 5;
        if (spikeTicks % beep == 0) {
            world.playSound(null, spike, SoundEvents.BLOCK_NOTE_BLOCK_PLING.value(), SoundCategory.BLOCKS, 2f, 2f);
            world.spawnParticles(new DustParticleEffect(new Vector3f(1f, 0.1f, 0.1f), 1.5f), spike.getX() + 0.5, spike.getY() + 1.2, spike.getZ() + 0.5, 5, 0.2, 0.2, 0.2, 0);
        }
        if (--spikeTicks <= 0) {
            detonate(boss, spike);
            return;
        }
        if (stunTicks > 0) {
            stunTicks--;
            boss.getNavigation().stop();
            return;
        }
        double dist = boss.squaredDistanceTo(Vec3d.ofBottomCenter(spike));
        if (dist < 3.5 * 3.5) {
            boss.getNavigation().stop();
            boss.getLookControl().lookAt(Vec3d.ofCenter(spike));
            defuse++;
            if (defuse % 20 == 0) {
                world.playSound(null, spike, SoundEvents.BLOCK_BEACON_AMBIENT, SoundCategory.HOSTILE, 2f, 1.6f);
            }
            world.spawnParticles(ParticleTypes.ELECTRIC_SPARK, spike.getX() + 0.5, spike.getY() + 1, spike.getZ() + 0.5, 3, 0.3, 0.3, 0.3, 0.05);
            if (defuse >= DEFUSE_TICKS) {
                // Ronda perdida: Sualenidus desactiva la Spike.
                for (ServerPlayerEntity p : ps) {
                    ModPackets.dialogue(p, "valorant_defused", 0, -1);
                }
                boss.heal(30);
                round++;
                resetRound(boss);
                placeSpike();
                phase = Phase.VALORANT_PREP;
                phaseTicks = 0;
            }
        } else if (boss.age % 10 == 0) {
            boss.getNavigation().startMovingTo(spike.getX() + 0.5, spike.getY(), spike.getZ() + 0.5, 1.25);
        }
        // Puñetazos si alguien se pone delante.
        if (--punchCooldown <= 0) {
            for (ServerPlayerEntity p : ps) {
                if (p.squaredDistanceTo(boss) < 3.5 * 3.5) {
                    boss.tryAttack(p);
                    boss.swingHand(net.minecraft.util.Hand.MAIN_HAND);
                    punchCooldown = 25;
                    break;
                }
            }
        }
    }

    private void detonate(SualenidusEntity boss, BlockPos spike) {
        world.setBlockState(spike, net.minecraft.block.Blocks.AIR.getDefaultState());
        world.spawnParticles(ParticleTypes.EXPLOSION_EMITTER, spike.getX() + 0.5, spike.getY() + 1, spike.getZ() + 0.5, 6, 3, 2, 3, 0);
        world.spawnParticles(ParticleTypes.FLASH, spike.getX() + 0.5, spike.getY() + 1, spike.getZ() + 0.5, 3, 0, 0, 0, 0);
        world.playSound(null, spike, SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.HOSTILE, 6f, 0.6f);
        world.playSound(null, spike, SoundEvents.ENTITY_LIGHTNING_BOLT_THUNDER, SoundCategory.HOSTILE, 4f, 0.8f);
        boss.setHealth(boss.getMaxHealth() * 0.3f);
        title("¡SPIKE DETONADA!", "Sualenidus ha caído... ¿o no?", Formatting.RED);
        startSouls(boss);
    }

    // ------------------------------------------------------------ fase 3: almas (Deltarune)

    private static final EntityType<?>[] FRIENDS = {
            ModEntities.TURBOPAPUENSE, ModEntities.ALPHATEMP, ModEntities.GUINXU, ModEntities.MUDOKON, ModEntities.ABE,
            ModEntities.AROY, ModEntities.JUANMA, ModEntities.ELINK_64, ModEntities.VERITY_GORDA, ModEntities.WILLIAM_PIRATON
    };

    private void startSouls(SualenidusEntity boss) {
        phase = Phase.SOULS;
        phaseTicks = 0;
        soulsReady = false;
        TurboState state = TurboState.get(world.getServer());
        if (!state.lawnBuilt) {
            Arenas.buildLawn(world);
            state.lawnBuilt = true;
            state.markDirty();
        }
        double cx = Arenas.LAWN_X + 8, cz = Arenas.rowZ(2);
        for (ServerPlayerEntity p : participants()) {
            p.teleport(world, cx + 0.5, Arenas.LAWN_Y, cz, -90, 0);
            ModPackets.dialogue(p, "sualenidus_fase3", 0, boss.getId());
        }
        moveBoss(boss, Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 7, Arenas.LAWN_Y, cz, 90);
        boss.getNavigation().stop();
    }

    private void tickSouls(SualenidusEntity boss, List<ServerPlayerEntity> ps) {
        boss.getNavigation().stop();
        boss.getLookControl().lookAt(ps.get(0));
        double cx = Arenas.LAWN_X + 8.5, cz = Arenas.rowZ(2);
        int start = 80;
        int i = (phaseTicks - start) / 14;
        if (phaseTicks >= start && (phaseTicks - start) % 14 == 0 && i < FRIENDS.length) {
            double a = i * Math.PI * 2 / FRIENDS.length;
            double x = cx + Math.cos(a) * 4.5, z = cz + Math.sin(a) * 4.5;
            Entity friend = FRIENDS[i].create(world);
            if (friend instanceof net.minecraft.entity.mob.MobEntity mob) {
                mob.refreshPositionAndAngles(x, Arenas.LAWN_Y, z, 0, 0);
                mob.setAiDisabled(true);
                mob.setInvulnerable(true);
                mob.setGlowing(true);
                mob.setPersistent();
                Vec3d look = new Vec3d(cx - x, 0, cz - z);
                float yaw = (float) (Math.atan2(look.z, look.x) * 180 / Math.PI) - 90f;
                mob.setYaw(yaw);
                mob.setHeadYaw(yaw);
                mob.setBodyYaw(yaw);
                mob.addCommandTag("turbopapu_alma");
                world.spawnEntity(mob);
                souls.add(mob);
                world.spawnParticles(ParticleTypes.END_ROD, x, Arenas.LAWN_Y + 1, z, 30, 0.2, 1.5, 0.2, 0.05);
                world.spawnParticles(ParticleTypes.HEART, x, Arenas.LAWN_Y + 2.2, z, 3, 0.3, 0.2, 0.3, 0);
                world.playSound(null, x, Arenas.LAWN_Y, z, SoundEvents.BLOCK_BEACON_ACTIVATE, SoundCategory.PLAYERS, 1.5f, 1f + i * 0.08f);
            }
        }
        if (phaseTicks % 6 == 0) {
            for (Entity s : souls) {
                world.spawnParticles(ParticleTypes.END_ROD, s.getX(), s.getY() + 1, s.getZ(), 1, 0.3, 0.6, 0.3, 0.02);
            }
            world.spawnParticles(ParticleTypes.HEART, cx, Arenas.LAWN_Y + 2.5, cz, 1, 0.4, 0.3, 0.4, 0);
        }
        int allIn = start + FRIENDS.length * 14 + 20;
        if (phaseTicks == allIn) {
            for (ServerPlayerEntity p : ps) {
                ModPackets.dialogue(p, "almas", 0, -1);
            }
        }
        if ((soulsReady && phaseTicks > allIn) || phaseTicks > allIn + 20 * 90) {
            startPvz(boss, ps);
        }
    }

    private void clearSouls() {
        souls.forEach(Entity::discard);
        souls.clear();
    }

    // ------------------------------------------------------------ fase 4: Plantas vs Zombies

    private void startPvz(SualenidusEntity boss, List<ServerPlayerEntity> ps) {
        clearSouls();
        phase = Phase.PVZ;
        phaseTicks = 0;
        for (ServerPlayerEntity p : ps) {
            p.teleport(world, Arenas.LAWN_X - 2.5, Arenas.LAWN_Y, Arenas.rowZ(2), -90, 0);
            p.addStatusEffect(new StatusEffectInstance(StatusEffects.RESISTANCE, 20 * 60 * 10, 4, false, false));
        }
        if (camera != null) {
            camera.discard();
        }
        camera = PvzGame.spawnCamera(world);
        pvz = new PvzGame(world, this);
        pvz.start();
        for (ServerPlayerEntity p : ps) {
            ModPackets.pvzStart(p, camera.getId());
        }
    }

    void pvzLost() {
        for (ServerPlayerEntity p : participants()) {
            p.sendMessage(Text.literal("¡Los Sualems llegaron a la casa! Inténtalo otra vez.").formatted(Formatting.RED), false);
        }
        world.playSound(null, Arenas.LAWN_X, Arenas.LAWN_Y, Arenas.LAWN_Z, SoundEvents.ENTITY_WITCH_CELEBRATE, SoundCategory.HOSTILE, 3f, 0.5f);
        pvz.start();
        pvz.say("Los Sualems se comieron tus cerebros... ¡Otra vez!");
    }

    private void endPvzForClients() {
        for (ServerPlayerEntity p : participants()) {
            ModPackets.pvzEnd(p);
            ModPackets.fightEnded(p);
            p.removeStatusEffect(StatusEffects.RESISTANCE);
        }
        if (camera != null) {
            camera.discard();
            camera = null;
        }
    }

    // ------------------------------------------------------------ utilidades

    /** Activa o desactiva el control de las IA del jefe (para las fases guionizadas). */
    public static void setScripted(SualenidusEntity boss, boolean scripted) {
        boss.setScriptedGoals(scripted);
    }

    public boolean isScripted() {
        return phase != Phase.RING;
    }

    private void title(String title, String subtitle, Formatting color) {
        for (ServerPlayerEntity p : participants()) {
            p.networkHandler.sendPacket(new TitleFadeS2CPacket(5, 50, 15));
            p.networkHandler.sendPacket(new TitleS2CPacket(Text.literal(title).formatted(color, Formatting.BOLD)));
            p.networkHandler.sendPacket(new SubtitleS2CPacket(Text.literal(subtitle).formatted(Formatting.WHITE)));
        }
    }

    private void broadcast(Text text) {
        for (ServerPlayerEntity p : participants()) {
            p.sendMessage(text, false);
        }
    }

    // Datos para el HUD del cliente.
    public Phase phase() { return phase; }
    public int round() { return round; }
    public int spikeTicks() { return spikeTicks; }
    public int defuse() { return defuse; }
    public PvzGame pvz() { return pvz; }
}
