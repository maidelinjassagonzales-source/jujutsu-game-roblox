package com.turbopapu.fight;

import com.turbopapu.entity.PvzPlantEntity;
import com.turbopapu.entity.PvzProjectileEntity;
import com.turbopapu.entity.SualemMiniEntity;
import com.turbopapu.entity.SualenidusEntity;
import com.turbopapu.registry.ModEntities;
import com.turbopapu.registry.ModItems;
import net.minecraft.entity.EquipmentSlot;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.math.random.Random;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

/**
 * Plantas vs Zombies con los amigos como plantas y hordas de Sualems como zombies.
 * 3 oleadas; en la última llega Sualenidus en persona. Si un Sualem llega a la casa
 * y ya se gastó el cortacésped de esa fila, se pierde y se vuelve a empezar.
 */
public class PvzGame {
    public static final int START_SUN = 150;
    public static final int MAX_LEVEL = 5;
    /** true mientras el minijuego hace daño (los Sualems/zombies solo reciben daño de las plantas). */
    static boolean damaging;

    /** 0 = la batalla contra Sualenidus; 1..MAX_LEVEL = niveles del modo libre. */
    final int level;
    /** Modo libre después de vencer a Sualenidus: zombies normales en vez de Sualems. */
    final boolean zombiesMode;
    final int totalWaves;

    private final ServerWorld world;
    private final BossFight fight;
    private final Random random;
    final Map<Integer, PvzPlantEntity> plants = new HashMap<>();
    final List<SualemMiniEntity> zombies = new ArrayList<>();
    final List<PvzProjectileEntity> projectiles = new ArrayList<>();
    final int[] cooldowns = new int[PvzPlantType.values().length];
    final boolean[] mowerUsed = new boolean[Arenas.ROWS];

    int sun = START_SUN;
    int ticks;
    int wave;
    int spawnedInWave;
    int waveSize;
    int nextSpawn;
    boolean bossEntered;
    String message = "";
    int messageTicks;

    public PvzGame(ServerWorld world, BossFight fight) {
        this(world, fight, 0, false);
    }

    public PvzGame(ServerWorld world, BossFight fight, int level, boolean zombiesMode) {
        this.world = world;
        this.fight = fight;
        this.random = world.getRandom();
        this.level = level;
        this.zombiesMode = zombiesMode;
        this.totalWaves = level <= 0 ? 3 : new int[]{2, 3, 3, 4, 5}[Math.min(level, MAX_LEVEL) - 1];
    }

    public static boolean isDamaging() {
        return damaging;
    }

    private SualenidusEntity boss() {
        return fight == null ? null : boss();
    }

    private String enemies() {
        return zombiesMode ? "zombies" : "Sualems";
    }

    private int waveSize(int w) {
        if (level <= 0) {
            return w == 1 ? 7 : w == 2 ? 12 : 18;
        }
        int size = 4 + level * 2 + (w - 1) * (3 + level);
        return w == totalWaves ? size * 3 / 2 : size;
    }

    private int spawnInterval(int w) {
        if (level <= 0) {
            return w == 1 ? 150 : w == 2 ? 90 : 45;
        }
        return Math.max(25, 170 - level * 20 - w * 15);
    }

    /** 0 = enemigo normal, 1 = "caracono", 2 = "caracubo". */
    private int armorRoll(int roll) {
        if (level <= 0) {
            return wave >= 2 && roll < 3 ? 1 : wave >= 3 && roll < 5 ? 2 : 0;
        }
        boolean cone = level >= 2 && wave >= 2 && roll < 2 + level / 2;
        boolean bucket = level >= 3 && wave >= Math.max(2, 6 - level) && roll >= 7 - level / 2 && roll < 9;
        return cone ? 1 : bucket ? 2 : 0;
    }

    public void start() {
        clear();
        Arenas.restoreMowers(world);
        sun = START_SUN + (level >= 4 ? 50 : 0);
        ticks = 0;
        wave = 0;
        nextSpawn = 400; // 20 segundos para plantar antes de la primera oleada
        bossEntered = false;
        for (int i = 0; i < cooldowns.length; i++) {
            cooldowns[i] = 0;
        }
        for (int r = 0; r < mowerUsed.length; r++) {
            mowerUsed[r] = false;
        }
        say(level > 0 ? "Nivel " + level + ": ¡planta a tus amigos! Los " + enemies() + " llegan en 20 segundos..."
                : "¡Planta a tus amigos! Los Sualems llegan en 20 segundos...");
        SualenidusEntity boss = boss();
        if (boss != null) {
            boss.setHealth(boss.getMaxHealth() * 0.3f);
            fight.moveBoss(boss, Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 9, Arenas.LAWN_Y, Arenas.rowZ(2), 90);
            boss.getNavigation().stop();
        }
    }

    /** Cámara fija desde arriba del jardín (la que usa la pantalla del minijuego). */
    public static net.minecraft.entity.decoration.ArmorStandEntity spawnCamera(ServerWorld world) {
        net.minecraft.entity.decoration.ArmorStandEntity camera = new net.minecraft.entity.decoration.ArmorStandEntity(world,
                Arenas.LAWN_X + Arenas.COLS, Arenas.LAWN_Y + 12, Arenas.LAWN_Z + Arenas.ROWS * Arenas.CELL + 11);
        net.minecraft.nbt.NbtCompound tag = new net.minecraft.nbt.NbtCompound();
        camera.writeCustomDataToNbt(tag);
        tag.putBoolean("Marker", true);
        tag.putBoolean("Invisible", true);
        tag.putBoolean("NoGravity", true);
        camera.readCustomDataFromNbt(tag);
        camera.setInvisible(true);
        camera.setNoGravity(true);
        camera.setYaw(180);
        camera.setPitch(46);
        camera.setHeadYaw(180);
        camera.setBodyYaw(180);
        camera.addCommandTag("turbopapu_camara");
        world.spawnEntity(camera);
        return camera;
    }

    public void clear() {
        plants.values().forEach(p -> p.discard());
        plants.clear();
        zombies.forEach(z -> z.discard());
        zombies.clear();
        projectiles.forEach(p -> p.discard());
        projectiles.clear();
    }

    void say(String text) {
        message = text;
        messageTicks = 100;
    }

    private static int key(int col, int row) {
        return row * 100 + col;
    }

    // ------------------------------------------------------------ acciones del jugador

    public void place(ServerPlayerEntity player, int col, int row, int typeId) {
        if (col < 0 || col >= Arenas.COLS || row < 0 || row >= Arenas.ROWS) {
            return;
        }
        PvzPlantType type = PvzPlantType.byId(typeId);
        if (plants.containsKey(key(col, row)) || sun < type.cost || cooldowns[type.ordinal()] > 0) {
            world.playSound(null, player.getBlockPos(), SoundEvents.BLOCK_NOTE_BLOCK_BASS.value(), SoundCategory.PLAYERS, 1f, 0.5f);
            return;
        }
        PvzPlantEntity plant = ModEntities.PVZ_PLANT.create(world);
        if (plant == null) {
            return;
        }
        plant.setPlantType(type);
        plant.col = col;
        plant.row = row;
        plant.timer = type == PvzPlantType.ELINK_64 ? 25 : 20;
        plant.refreshPositionAndAngles(Arenas.cellX(col), Arenas.LAWN_Y, Arenas.rowZ(row), -90, 0);
        plant.setHeadYaw(-90);
        plant.setBodyYaw(-90);
        world.spawnEntity(plant);
        plants.put(key(col, row), plant);
        sun -= type.cost;
        cooldowns[type.ordinal()] = type.cooldown;
        world.playSound(null, plant.getBlockPos(), SoundEvents.BLOCK_GRASS_PLACE, SoundCategory.BLOCKS, 1.5f, 1f);
        world.spawnParticles(ParticleTypes.HAPPY_VILLAGER, plant.getX(), plant.getY() + 0.5, plant.getZ(), 8, 0.4, 0.4, 0.4, 0);
    }

    public void shovel(int col, int row) {
        PvzPlantEntity plant = plants.remove(key(col, row));
        if (plant != null) {
            world.playSound(null, plant.getBlockPos(), SoundEvents.ITEM_SHOVEL_FLATTEN, SoundCategory.BLOCKS, 1f, 1f);
            plant.discard();
        }
    }

    // ------------------------------------------------------------ bucle principal

    public void tick() {
        ticks++;
        if (messageTicks > 0) {
            messageTicks--;
        }
        for (int i = 0; i < cooldowns.length; i++) {
            if (cooldowns[i] > 0) {
                cooldowns[i]--;
            }
        }
        if (ticks % 200 == 0) {
            sun += 25; // sol que cae del cielo
        }
        tickWaves();
        tickPlants();
        tickProjectiles();
        tickZombies();
    }

    private void tickWaves() {
        if (wave > totalWaves) {
            if (fight == null && zombies.isEmpty()) {
                PvzArcade.won(this);
            }
            return;
        }
        if (--nextSpawn > 0) {
            return;
        }
        if (wave == 0 || (spawnedInWave >= waveSize && zombies.isEmpty())) {
            wave++;
            if (wave > totalWaves) {
                return;
            }
            spawnedInWave = 0;
            waveSize = waveSize(wave);
            say(wave == totalWaves ? "¡UNA ENORME OLEADA DE " + enemies().toUpperCase() + " SE ACERCA!" : "Oleada " + wave + " de " + totalWaves);
            world.playSound(null, Arenas.LAWN_X, Arenas.LAWN_Y, Arenas.LAWN_Z, SoundEvents.EVENT_RAID_HORN.value(), SoundCategory.HOSTILE, 2f, 1f);
            nextSpawn = 60;
            return;
        }
        if (spawnedInWave < waveSize) {
            spawnZombie();
            spawnedInWave++;
            nextSpawn = spawnInterval(wave);
            if (fight != null && wave == totalWaves && !bossEntered && spawnedInWave >= waveSize / 2) {
                bossEntered = true;
                say("¡SUALENIDUS EN PERSONA ENTRA AL JARDÍN!");
            }
        } else {
            nextSpawn = 20;
        }
    }

    private void spawnZombie() {
        SualemMiniEntity z = (zombiesMode ? ModEntities.ZOMBI_PVZ : ModEntities.SUALEM_MINI).create(world);
        if (z == null) {
            return;
        }
        int row = random.nextInt(Arenas.ROWS);
        z.row = row;
        int armor = armorRoll(random.nextInt(10));
        if (armor == 1) {
            // "Caracono": doble de vida.
            z.equipStack(EquipmentSlot.HEAD, new ItemStack(Items.ORANGE_CONCRETE));
            z.getAttributeInstance(EntityAttributes.GENERIC_MAX_HEALTH).setBaseValue(40);
            z.setHealth(40);
        } else if (armor == 2) {
            // "Caracubo": triple de vida.
            z.equipStack(EquipmentSlot.HEAD, new ItemStack(Items.CAULDRON));
            z.getAttributeInstance(EntityAttributes.GENERIC_MAX_HEALTH).setBaseValue(65);
            z.setHealth(65);
        }
        z.setEquipmentDropChance(EquipmentSlot.HEAD, 0f);
        z.refreshPositionAndAngles(Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 6, Arenas.LAWN_Y, Arenas.rowZ(row), 90, 0);
        world.spawnEntity(z);
        zombies.add(z);
    }

    private void shoot(PvzPlantEntity plant, ItemStack stack, float damage, boolean slows, double splash, double offset) {
        PvzProjectileEntity p = ModEntities.PVZ_PROJECTILE.create(world);
        if (p == null) {
            return;
        }
        p.setStack(stack);
        p.row = plant.row;
        p.damage = damage;
        p.slows = slows;
        p.splash = splash;
        p.refreshPositionAndAngles(plant.getX() + 0.6 - offset, plant.getY() + 1.0, plant.getZ(), 0, 0);
        world.spawnEntity(p);
        projectiles.add(p);
    }

    private boolean zombieAhead(PvzPlantEntity plant) {
        for (SualemMiniEntity z : zombies) {
            if (z.row == plant.row && z.getX() > plant.getX() && z.getX() < Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 3) {
                return true;
            }
        }
        SualenidusEntity boss = boss();
        return bossEntered && boss != null && boss.isAlive() && bossRow() == plant.row && boss.getX() > plant.getX();
    }

    private void tickPlants() {
        Iterator<Map.Entry<Integer, PvzPlantEntity>> it = plants.entrySet().iterator();
        while (it.hasNext()) {
            PvzPlantEntity plant = it.next().getValue();
            if (plant.isRemoved() || plant.hp <= 0) {
                plant.discard();
                it.remove();
                continue;
            }
            plant.timer--;
            switch (plant.getPlantType()) {
                case TURBOPAPUENSE -> {
                    if (plant.timer <= 0) {
                        plant.timer = 240;
                        sun += 25;
                        world.spawnParticles(ParticleTypes.GLOW, plant.getX(), plant.getY() + 1.4, plant.getZ(), 12, 0.3, 0.3, 0.3, 0.02);
                        world.playSound(null, plant.getBlockPos(), SoundEvents.ENTITY_EXPERIENCE_ORB_PICKUP, SoundCategory.PLAYERS, 0.6f, 1.4f);
                    }
                }
                case ALPHATEMP -> {
                    if (plant.timer <= 0 && zombieAhead(plant)) {
                        plant.timer = 30;
                        shoot(plant, new ItemStack(Items.PACKED_ICE), 3f, true, 0, 0);
                    }
                }
                case GUINXU -> {
                    if (plant.timer <= 0 && zombieAhead(plant)) {
                        plant.timer = 30;
                        shoot(plant, new ItemStack(Items.SLIME_BALL), 3f, false, 0, 0);
                        shoot(plant, new ItemStack(Items.SLIME_BALL), 3f, false, 0, 0.6);
                    }
                }
                case AROY -> {
                    if (plant.timer <= 0 && zombieAhead(plant)) {
                        plant.timer = 60;
                        shoot(plant, new ItemStack(ModItems.LECHE_DE_COCO), 12f, false, 0, 0);
                        world.playSound(null, plant.getBlockPos(), SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.BLOCKS, 0.4f, 1.8f);
                    }
                }
                case JUANMA -> {
                    if (plant.timer <= 0 && zombieAhead(plant)) {
                        plant.timer = 50;
                        shoot(plant, new ItemStack(ModItems.MATE), 5f, false, 1.6, 0);
                    }
                }
                case ELINK_64 -> {
                    if (plant.timer <= 0) {
                        explode(plant);
                        it.remove();
                    }
                }
                case VERITY_GORDA -> {
                    // Rueda hacia la derecha arrollando Sualems.
                    plant.setPosition(plant.getX() + 0.22, plant.getY(), plant.getZ());
                    for (SualemMiniEntity z : zombies) {
                        if (z.row == plant.row && Math.abs(z.getX() - plant.getX()) < 0.9 && plant.timer <= 0) {
                            hurt(z, 25f);
                            plant.timer = 10;
                            world.playSound(null, plant.getBlockPos(), SoundEvents.ENTITY_SLIME_SQUISH, SoundCategory.BLOCKS, 1.2f, 0.7f);
                        }
                    }
                    if (plant.getX() > Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 8) {
                        plant.discard();
                        it.remove();
                    }
                }
                case MUDOKON -> {
                }
                case MAGO_LARGUIRUCHO -> {
                    // Agujero mágico delante del mago: salen tres salchichas que ruedan por la fila.
                    if (plant.timer <= 0 && zombieAhead(plant)) {
                        plant.timer = 80;
                        world.spawnParticles(ParticleTypes.PORTAL, plant.getX() + 1, plant.getY() + 0.1, plant.getZ(), 30, 0.4, 0.1, 0.4, 0.3);
                        world.spawnParticles(ParticleTypes.WITCH, plant.getX(), plant.getY() + 2.2, plant.getZ(), 8, 0.2, 0.2, 0.2, 0.05);
                        world.playSound(null, plant.getBlockPos(), SoundEvents.ENTITY_EVOKER_CAST_SPELL, SoundCategory.BLOCKS, 0.8f, 1.3f);
                        for (int i = 0; i < 3; i++) {
                            shoot(plant, new ItemStack(ModItems.SALCHICHA), 6f, false, 0.9, -0.5 - i * 0.7);
                        }
                    }
                }
            }
        }
    }

    private void explode(PvzPlantEntity plant) {
        world.spawnParticles(ParticleTypes.EXPLOSION_EMITTER, plant.getX(), plant.getY() + 0.5, plant.getZ(), 1, 0, 0, 0, 0);
        world.spawnParticles(ParticleTypes.NOTE, plant.getX(), plant.getY() + 1.5, plant.getZ(), 12, 1.5, 0.5, 1.5, 1);
        world.playSound(null, plant.getBlockPos(), SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.BLOCKS, 2f, 1.2f);
        for (SualemMiniEntity z : new ArrayList<>(zombies)) {
            if (Math.abs(z.getX() - plant.getX()) < 3.2 && Math.abs(z.getZ() - plant.getZ()) < 3.2) {
                hurt(z, 90f);
            }
        }
        SualenidusEntity boss = boss();
        if (bossEntered && boss != null && Math.abs(boss.getX() - plant.getX()) < 3.5 && Math.abs(boss.getZ() - plant.getZ()) < 3.5) {
            hurtBoss(boss, 20f);
        }
        plant.discard();
    }

    private void tickProjectiles() {
        Iterator<PvzProjectileEntity> it = projectiles.iterator();
        SualenidusEntity boss = boss();
        while (it.hasNext()) {
            PvzProjectileEntity p = it.next();
            if (p.isRemoved() || p.getX() > Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 10) {
                p.discard();
                it.remove();
                continue;
            }
            SualemMiniEntity target = null;
            for (SualemMiniEntity z : zombies) {
                if (z.row == p.row && Math.abs(z.getX() - p.getX()) < 0.7) {
                    target = z;
                    break;
                }
            }
            boolean hitBoss = target == null && bossEntered && boss != null && boss.isAlive() && bossRow() == p.row
                    && Math.abs(boss.getX() - p.getX()) < 1.2;
            if (target == null && !hitBoss) {
                continue;
            }
            if (target != null) {
                hurt(target, p.damage);
                if (p.slows) {
                    target.slowTicks = 100;
                }
                if (p.splash > 0) {
                    for (SualemMiniEntity z : new ArrayList<>(zombies)) {
                        if (z != target && z.squaredDistanceTo(target) < p.splash * p.splash) {
                            hurt(z, p.damage * 0.5f);
                        }
                    }
                }
            } else {
                hurtBoss(boss, p.damage * 0.5f);
            }
            world.spawnParticles(p.slows ? ParticleTypes.SNOWFLAKE : ParticleTypes.ITEM_SLIME, p.getX(), p.getY(), p.getZ(), 5, 0.1, 0.1, 0.1, 0.05);
            p.discard();
            it.remove();
        }
    }

    private void hurt(LivingEntity z, float amount) {
        damaging = true;
        z.timeUntilRegen = 0;
        z.damage(world.getDamageSources().magic(), amount);
        damaging = false;
    }

    private void hurtBoss(SualenidusEntity boss, float amount) {
        hurt(boss, amount);
    }

    int bossRow() {
        return 2;
    }

    private void tickZombies() {
        Iterator<SualemMiniEntity> it = zombies.iterator();
        while (it.hasNext()) {
            SualemMiniEntity z = it.next();
            if (z.isRemoved() || !z.isAlive()) {
                it.remove();
                continue;
            }
            if (z.slowTicks > 0) {
                z.slowTicks--;
            }
            if (walkOrEat(z, z.row, z.slowTicks > 0 ? 0.5 : 1.0, 1.0)) {
                return; // se perdió la partida
            }
        }
        SualenidusEntity boss = boss();
        if (bossEntered && boss != null && boss.isAlive()) {
            walkOrEat(boss, bossRow(), 0.15, 2.0);
        }
    }

    /** Avanza hacia la casa o se come al amigo que tenga delante. Devuelve true si se perdió la partida. */
    private boolean walkOrEat(net.minecraft.entity.mob.MobEntity z, int row, double speed, double reach) {
        PvzPlantEntity food = null;
        for (PvzPlantEntity plant : plants.values()) {
            if (plant.row == row && plant.getPlantType() != PvzPlantType.VERITY_GORDA
                    && z.getX() - plant.getX() < reach && z.getX() - plant.getX() > -0.2) {
                food = plant;
                break;
            }
        }
        if (food != null) {
            z.getMoveControl().moveTo(z.getX(), z.getY(), z.getZ(), 0);
            z.setVelocity(0, z.getVelocity().y, 0);
            if (z.age % 10 == 0) {
                food.hp -= z instanceof SualenidusEntity ? 15 : 4;
                z.swingHand(net.minecraft.util.Hand.MAIN_HAND);
                world.playSound(null, food.getBlockPos(), SoundEvents.ENTITY_GENERIC_EAT, SoundCategory.HOSTILE, 1f, 0.8f);
            }
            return false;
        }
        z.getMoveControl().moveTo(Arenas.LAWN_X - 4, Arenas.LAWN_Y, Arenas.rowZ(row), speed);
        if (z.getX() < Arenas.LAWN_X + 0.2) {
            if (!mowerUsed[row]) {
                mowerUsed[row] = true;
                Arenas.removeMower(world, row);
                say("¡Cortacésped!");
                world.playSound(null, Arenas.LAWN_X, Arenas.LAWN_Y, Arenas.rowZ(row), SoundEvents.ENTITY_MINECART_RIDING, SoundCategory.BLOCKS, 2f, 1.5f);
                for (int x = 0; x < Arenas.COLS * Arenas.CELL + 6; x += 2) {
                    world.spawnParticles(ParticleTypes.CLOUD, Arenas.LAWN_X + x, Arenas.LAWN_Y + 0.5, Arenas.rowZ(row), 3, 0.3, 0.2, 0.3, 0.02);
                }
                for (SualemMiniEntity other : new ArrayList<>(zombies)) {
                    if (other.row == row) {
                        hurt(other, 999f);
                    }
                }
                if (z instanceof SualenidusEntity boss) {
                    hurtBoss(boss, 25f);
                    boss.refreshPositionAndAngles(Arenas.LAWN_X + Arenas.COLS * Arenas.CELL + 6, Arenas.LAWN_Y, Arenas.rowZ(row), 90, 0);
                }
                return false;
            }
            if (fight != null) {
                fight.pvzLost();
            } else {
                PvzArcade.lost(this);
            }
            return true;
        }
        return false;
    }

    public int sun() {
        return sun;
    }

    public String message() {
        return messageTicks > 0 ? message : "";
    }

    public int wave() {
        return Math.max(1, Math.min(wave, totalWaves));
    }

    public int totalWaves() {
        return totalWaves;
    }

    public int waveProgress() {
        if (wave == 0) {
            return 0;
        }
        int done = (wave - 1) * 100 + (waveSize == 0 ? 0 : spawnedInWave * 100 / waveSize);
        return Math.min(100, done / totalWaves);
    }

    public int cooldownPercent(int i) {
        PvzPlantType type = PvzPlantType.byId(i);
        return cooldowns[i] * 100 / Math.max(1, type.cooldown);
    }
}
