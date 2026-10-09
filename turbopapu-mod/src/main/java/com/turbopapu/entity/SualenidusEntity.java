package com.turbopapu.entity;

import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModEffects;
import com.turbopapu.world.Fireworks;
import com.turbopapu.world.TurboState;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.ai.goal.*;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.boss.BossBar;
import net.minecraft.entity.boss.ServerBossBar;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.data.DataTracker;
import net.minecraft.entity.data.TrackedData;
import net.minecraft.entity.data.TrackedDataHandlerRegistry;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.particle.DustParticleEffect;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;
import org.joml.Vector3f;

import java.util.List;

/**
 * El jefe final. Un gordo ENORME cuya barriga no para de crecer, que habla de armas de Valorant,
 * huele a lavanda y se ríe como un loco. Su nube de lavanda te deja DORMIDO y, mientras duermes,
 * sus golpes hacen el doble de daño.
 */
public class SualenidusEntity extends HostileEntity {
    private static final TrackedData<Float> BARRIGA = DataTracker.registerData(SualenidusEntity.class, TrackedDataHandlerRegistry.FLOAT);
    private static final DustParticleEffect LAVANDA = new DustParticleEffect(new Vector3f(0.71f, 0.49f, 0.86f), 1.6f);

    private static final String[] VALORANT = {
            "¡La Vandal es mejor que la Phantom! ¡NO HAY DEBATE! ¡JAJAJAJA!",
            "¿Me compras una Operator? Es para dormirte de un tiro. ¡JIJIJIJA!",
            "Eco round... Sheriff... headshot... ¡JUAJUAJUAJUA!",
            "Ghost en ronda de pistolas, clásico. ¡JEJEJEJEJE!",
            "Duerme, duerme... mientras planto la Spike en tu cama. ¡MUAJAJAJAJA!",
            "Huele a lavanda, ¿verdad? Es mi perfume: 'Eau de Spike'. ¡JAJAJAJAJA!",
            "Mi barriga sube más rápido que mi rango en Valorant. ¡JOJOJOJAJAJA!",
            "¿Odin? ¿Ares? ¡Yo soy el Odin! ¡RATATATA-JAJAJA!"
    };

    private final ServerBossBar bossBar = new ServerBossBar(Text.literal("Sualenidus").formatted(Formatting.LIGHT_PURPLE),
            BossBar.Color.PURPLE, BossBar.Style.NOTCHED_10);
    private int lavenderCooldown = 120;
    private int laughCooldown = 60;
    private int bellySlamCooldown = 60;

    public SualenidusEntity(EntityType<? extends HostileEntity> type, World world) {
        super(type, world);
        this.experiencePoints = 500;
        this.setCustomName(Text.literal("Sualenidus").formatted(Formatting.LIGHT_PURPLE, Formatting.BOLD));
        this.setPersistent();
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return HostileEntity.createHostileAttributes()
                .add(EntityAttributes.GENERIC_MAX_HEALTH, 400.0)
                .add(EntityAttributes.GENERIC_ATTACK_DAMAGE, 9.0)
                .add(EntityAttributes.GENERIC_ARMOR, 8.0)
                .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.23)
                .add(EntityAttributes.GENERIC_KNOCKBACK_RESISTANCE, 1.0)
                .add(EntityAttributes.GENERIC_FOLLOW_RANGE, 48.0);
    }

    @Override
    protected void initDataTracker() {
        super.initDataTracker();
        this.dataTracker.startTracking(BARRIGA, 1.0f);
    }

    @Override
    protected void initGoals() {
        this.goalSelector.add(0, new SwimGoal(this));
        this.goalSelector.add(2, new MeleeAttackGoal(this, 1.0, true));
        this.goalSelector.add(7, new WanderAroundFarGoal(this, 0.6));
        this.goalSelector.add(8, new LookAtEntityGoal(this, PlayerEntity.class, 16.0f));
        this.targetSelector.add(1, new RevengeGoal(this));
        this.targetSelector.add(2, new ActiveTargetGoal<>(this, PlayerEntity.class, true));
    }

    /** Tamaño de la barriga: crece cuanto más le pegas... y un poquito cada segundo. Nunca para. */
    public float getBarriga() {
        return this.dataTracker.get(BARRIGA);
    }

    public boolean isPhaseTwo() {
        return getHealth() < getMaxHealth() / 2;
    }

    @Override
    protected void mobTick() {
        super.mobTick();
        ServerWorld world = (ServerWorld) getWorld();
        bossBar.setPercent(getHealth() / getMaxHealth());

        float target = 1.0f + (1.0f - getHealth() / getMaxHealth()) * 0.9f + (age % 2400) / 2400f * 0.25f;
        this.dataTracker.set(BARRIGA, MathHelper.lerp(0.05f, getBarriga(), target));

        // Siempre huele a lavanda.
        if (age % 4 == 0) {
            world.spawnParticles(LAVANDA, getX(), getY() + 2.5, getZ(), 3, 1.2, 1.5, 1.2, 0);
        }

        LivingEntity target2 = getTarget();
        int speedUp = isPhaseTwo() ? 2 : 1;

        if ((laughCooldown -= speedUp) <= 0) {
            laughCooldown = 100 + random.nextInt(80);
            laugh(world);
        }
        com.turbopapu.fight.BossFight fight = com.turbopapu.fight.BossFight.forBoss(this);
        if (fight != null && fight.isScripted()) {
            return; // En Valorant / almas / PvZ los ataques los controla BossFight.
        }
        if (target2 != null && (lavenderCooldown -= speedUp) <= 0) {
            lavenderCooldown = 160 + random.nextInt(60);
            lavenderCloud(world);
        }
        if (target2 != null && (bellySlamCooldown -= speedUp) <= 0 && squaredDistanceTo(target2) < 36) {
            bellySlamCooldown = 70;
            bellySlam(world);
        }
    }

    private void laugh(ServerWorld world) {
        world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_WITCH_CELEBRATE, SoundCategory.HOSTILE, 3f, 0.5f);
        String line = VALORANT[random.nextInt(VALORANT.length)];
        Text text = Text.literal("<").append(Text.literal("Sualenidus").formatted(Formatting.LIGHT_PURPLE))
                .append(Text.literal("> " + line));
        for (ServerPlayerEntity player : world.getPlayers(p -> p.squaredDistanceTo(this) < 48 * 48)) {
            player.sendMessage(text, false);
        }
    }

    /** Nube de lavanda: duerme a todos en un radio de 7 bloques (salvo si han tomado mate). */
    private void lavenderCloud(ServerWorld world) {
        world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_PHANTOM_AMBIENT, SoundCategory.HOSTILE, 2f, 0.6f);
        double radius = isPhaseTwo() ? 9 : 7;
        for (int i = 0; i < 120; i++) {
            double a = random.nextDouble() * Math.PI * 2;
            double r = random.nextDouble() * radius;
            world.spawnParticles(LAVANDA, getX() + Math.cos(a) * r, getY() + 0.5 + random.nextDouble() * 2,
                    getZ() + Math.sin(a) * r, 1, 0, 0, 0, 0);
        }
        Box area = getBoundingBox().expand(radius);
        for (PlayerEntity player : world.getEntitiesByClass(PlayerEntity.class, area, p -> !p.isSpectator() && !p.isCreative())) {
            if (player.hasStatusEffect(ModEffects.DESPIERTO)) {
                player.sendMessage(Text.translatable("message.turbopapu.resist_sleep").formatted(Formatting.GREEN), true);
                continue;
            }
            player.addStatusEffect(new StatusEffectInstance(ModEffects.DORMIDO, isPhaseTwo() ? 100 : 70, 0));
            player.addStatusEffect(new StatusEffectInstance(StatusEffects.BLINDNESS, 40, 0));
            player.sendMessage(Text.translatable("message.turbopapu.asleep").formatted(Formatting.LIGHT_PURPLE), true);
        }
    }

    /** Barrigazo: empuja y golpea a todo lo que esté cerca. */
    private void bellySlam(ServerWorld world) {
        world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_PLAYER_BURP, SoundCategory.HOSTILE, 3f, 0.4f);
        world.spawnParticles(ParticleTypes.EXPLOSION, getX(), getY() + 1.5, getZ(), 3, 1, 0.5, 1, 0);
        Box area = getBoundingBox().expand(3.5);
        for (LivingEntity victim : world.getEntitiesByClass(LivingEntity.class, area, e -> e != this && !(e instanceof TurboPapuenseEntity))) {
            float damage = (float) getAttributeValue(EntityAttributes.GENERIC_ATTACK_DAMAGE);
            if (victim.hasStatusEffect(ModEffects.DORMIDO)) {
                damage *= 2;
            }
            victim.damage(getDamageSources().mobAttack(this), damage);
            Vec3d push = victim.getPos().subtract(getPos()).normalize().multiply(1.8);
            victim.addVelocity(push.x, 0.6, push.z);
            victim.velocityModified = true;
        }
    }

    @Override
    public boolean tryAttack(Entity target) {
        boolean hit = super.tryAttack(target);
        if (hit && target instanceof LivingEntity living && living.hasStatusEffect(ModEffects.DORMIDO)) {
            // Golpear a alguien dormido duele el doble.
            living.timeUntilRegen = 0;
            living.damage(getDamageSources().mobAttack(this), (float) getAttributeValue(EntityAttributes.GENERIC_ATTACK_DAMAGE));
        }
        return hit;
    }

    /** Activa/desactiva las IA normales (las fases guionizadas de la pelea mueven al jefe a mano). */
    public void setScriptedGoals(boolean scripted) {
        if (scripted) {
            this.goalSelector.disableControl(net.minecraft.entity.ai.goal.Goal.Control.MOVE);
            this.goalSelector.disableControl(net.minecraft.entity.ai.goal.Goal.Control.LOOK);
            this.targetSelector.disableControl(net.minecraft.entity.ai.goal.Goal.Control.TARGET);
            this.setTarget(null);
        } else {
            this.goalSelector.enableControl(net.minecraft.entity.ai.goal.Goal.Control.MOVE);
            this.goalSelector.enableControl(net.minecraft.entity.ai.goal.Goal.Control.LOOK);
            this.targetSelector.enableControl(net.minecraft.entity.ai.goal.Goal.Control.TARGET);
        }
    }

    @Override
    public boolean damage(DamageSource source, float amount) {
        if (!getWorld().isClient && source.getAttacker() instanceof PlayerEntity) {
            com.turbopapu.fight.BossFight.ensureFight(this);
        }
        com.turbopapu.fight.BossFight fight = com.turbopapu.fight.BossFight.forBoss(this);
        if (fight != null && !source.isOf(net.minecraft.entity.damage.DamageTypes.OUT_OF_WORLD)
                && !source.isOf(net.minecraft.entity.damage.DamageTypes.GENERIC_KILL)) {
            amount = fight.filterBossDamage(this, amount);
            if (amount <= 0) {
                return false;
            }
        }
        return super.damage(source, amount);
    }

    @Override
    public void onDeath(DamageSource damageSource) {
        super.onDeath(damageSource);
        com.turbopapu.fight.BossFight fight = com.turbopapu.fight.BossFight.forBoss(this);
        if (fight != null) {
            fight.onBossDeath(this);
        }
        if (getWorld() instanceof ServerWorld world) {
            TurboState state = TurboState.get(world.getServer());
            state.sualenidusDefeated = true;
            state.markDirty();
            world.getServer().getPlayerManager().broadcast(
                    Text.translatable("message.turbopapu.victory").formatted(Formatting.GOLD, Formatting.BOLD), false);
            Fireworks.celebrate(world, new net.minecraft.util.math.BlockPos(0, state.villageY, 0), 16);
            if (!state.friendsVillageBuilt) {
                com.turbopapu.world.FriendsVillage.build(world, state);
            }
            for (ServerPlayerEntity player : world.getPlayers()) {
                player.removeStatusEffect(ModEffects.DORMIDO);
                ModPackets.showEnding(player);
            }
        }
    }

    @Override
    public void onStartedTrackingBy(ServerPlayerEntity player) {
        super.onStartedTrackingBy(player);
        bossBar.addPlayer(player);
    }

    @Override
    public void onStoppedTrackingBy(ServerPlayerEntity player) {
        super.onStoppedTrackingBy(player);
        bossBar.removePlayer(player);
    }

    @Override
    public boolean cannotDespawn() {
        return true;
    }

    @Override
    public boolean isPushable() {
        return false;
    }

    @Override
    protected @Nullable SoundEvent getAmbientSound() {
        return SoundEvents.ENTITY_WITCH_AMBIENT;
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return SoundEvents.ENTITY_RAVAGER_HURT;
    }

    @Override
    protected SoundEvent getDeathSound() {
        return SoundEvents.ENTITY_WITCH_CELEBRATE;
    }

    @Override
    public float getSoundPitch() {
        return 0.6f;
    }

    @Override
    public void readCustomDataFromNbt(NbtCompound nbt) {
        super.readCustomDataFromNbt(nbt);
        if (hasCustomName()) {
            bossBar.setName(getDisplayName());
        }
    }

    /** Cuando le cae un iceberg encima. */
    public void hitByIceberg(ServerWorld world) {
        damage(getDamageSources().freeze(), 30f);
        addStatusEffect(new StatusEffectInstance(StatusEffects.SLOWNESS, 100, 3));
        world.getPlayers(p -> p.squaredDistanceTo(this) < 48 * 48).forEach(p -> p.sendMessage(
                Text.literal("<Sualenidus> ¡¿UN ICEBERG?! ¡ESO NO ESTÁ EN VALORANT! ¡JAJA... ay!").formatted(Formatting.LIGHT_PURPLE), false));
    }

    @Override
    protected boolean isDisallowedInPeaceful() {
        return false;
    }
}
