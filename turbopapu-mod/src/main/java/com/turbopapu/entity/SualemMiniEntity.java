package com.turbopapu.entity;

import com.turbopapu.fight.BossFight;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.mob.HostileEntity;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

/** Los "zombies" del Plantas vs Zombies: Sualems pequeños que avanzan por las filas. Los controla PvzGame. */
public class SualemMiniEntity extends HostileEntity {
    public int row;
    public int slowTicks;
    public int eatCooldown;

    public SualemMiniEntity(EntityType<? extends HostileEntity> type, World world) {
        super(type, world);
        this.setPersistent();
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return HostileEntity.createHostileAttributes()
                .add(EntityAttributes.GENERIC_MAX_HEALTH, 20.0)
                .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.1)
                .add(EntityAttributes.GENERIC_KNOCKBACK_RESISTANCE, 1.0);
    }

    @Override
    protected void initGoals() {
        // Sin IA propia: PvzGame los hace avanzar.
    }

    @Override
    public void tick() {
        super.tick();
        if (!getWorld().isClient && age > 40 && !BossFight.isPvzActive()) {
            discard();
        }
    }

    @Override
    public boolean damage(DamageSource source, float amount) {
        if (!BossFight.isPvzDamage()) {
            return false;
        }
        return super.damage(source, amount);
    }

    @Override
    protected void dropLoot(DamageSource source, boolean causedByPlayer) {
    }

    @Override
    protected boolean isDisallowedInPeaceful() {
        // Si no, en Pacífico desaparecen nada más salir y no hay oleadas.
        return false;
    }

    @Override
    public boolean isPushable() {
        return false;
    }

    @Override
    protected @Nullable SoundEvent getAmbientSound() {
        return SoundEvents.ENTITY_ZOMBIE_AMBIENT;
    }

    @Override
    public float getSoundPitch() {
        return 1.4f;
    }
}
