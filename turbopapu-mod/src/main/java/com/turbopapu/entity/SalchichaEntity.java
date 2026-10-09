package com.turbopapu.entity;

import com.turbopapu.registry.ModItems;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.ai.goal.EscapeDangerGoal;
import net.minecraft.entity.ai.goal.LookAroundGoal;
import net.minecraft.entity.ai.goal.SwimGoal;
import net.minecraft.entity.ai.goal.WanderAroundGoal;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.mob.PathAwareEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

/** Salchichas vivas que salen del agujero del Mago Larguirucho: dan saltitos y al rato desaparecen con un "puf". */
public class SalchichaEntity extends PathAwareEntity {
    private static final int LIFETIME = 20 * 60;
    private int life;

    public SalchichaEntity(EntityType<? extends PathAwareEntity> type, World world) {
        super(type, world);
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return MobEntity.createMobAttributes()
                .add(EntityAttributes.GENERIC_MAX_HEALTH, 4.0)
                .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.3);
    }

    @Override
    protected void initGoals() {
        this.goalSelector.add(0, new SwimGoal(this));
        this.goalSelector.add(1, new EscapeDangerGoal(this, 1.6));
        this.goalSelector.add(2, new WanderAroundGoal(this, 1.0, 20));
        this.goalSelector.add(3, new LookAroundGoal(this));
    }

    @Override
    public void tick() {
        super.tick();
        if (getWorld().isClient) {
            return;
        }
        // Van dando saltitos.
        if (isOnGround() && random.nextInt(30) == 0) {
            addVelocity((random.nextDouble() - 0.5) * 0.3, 0.42, (random.nextDouble() - 0.5) * 0.3);
            velocityDirty = true;
        }
        if (++life > LIFETIME && getWorld() instanceof ServerWorld world) {
            world.spawnParticles(ParticleTypes.POOF, getX(), getY() + 0.2, getZ(), 8, 0.2, 0.1, 0.2, 0.02);
            world.playSound(null, getBlockPos(), SoundEvents.ENTITY_CHICKEN_EGG, SoundCategory.NEUTRAL, 0.8f, 1.6f);
            discard();
        }
    }

    @Override
    protected void dropLoot(DamageSource source, boolean causedByPlayer) {
        dropStack(new ItemStack(ModItems.SALCHICHA));
    }

    @Override
    public boolean canImmediatelyDespawn(double distanceSquared) {
        return false;
    }

    @Override
    protected @Nullable SoundEvent getAmbientSound() {
        return SoundEvents.ENTITY_SLIME_SQUISH_SMALL;
    }

    @Override
    protected SoundEvent getHurtSound(DamageSource source) {
        return SoundEvents.ENTITY_SLIME_HURT_SMALL;
    }

    @Override
    protected SoundEvent getDeathSound() {
        return SoundEvents.ENTITY_SLIME_DEATH_SMALL;
    }

    @Override
    public float getSoundPitch() {
        return 1.5f + random.nextFloat() * 0.3f;
    }

    @Override
    public void writeCustomDataToNbt(NbtCompound nbt) {
        super.writeCustomDataToNbt(nbt);
        nbt.putInt("Life", life);
    }

    @Override
    public void readCustomDataFromNbt(NbtCompound nbt) {
        super.readCustomDataFromNbt(nbt);
        life = nbt.getInt("Life");
    }
}
