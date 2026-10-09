package com.turbopapu.entity;

import com.turbopapu.fight.BossFight;
import com.turbopapu.fight.PvzPlantType;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.data.DataTracker;
import net.minecraft.entity.data.TrackedData;
import net.minecraft.entity.data.TrackedDataHandlerRegistry;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.world.World;

/** Un amigo plantado en el césped. Se dibuja con el modelo del personaje (ver PvzPlantRenderer). */
public class PvzPlantEntity extends MobEntity {
    private static final TrackedData<Integer> TYPE = DataTracker.registerData(PvzPlantEntity.class, TrackedDataHandlerRegistry.INTEGER);

    public int col, row;
    public int hp;
    public int timer;

    public PvzPlantEntity(EntityType<? extends MobEntity> type, World world) {
        super(type, world);
        this.setPersistent();
        this.setAiDisabled(true);
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return MobEntity.createMobAttributes().add(EntityAttributes.GENERIC_MAX_HEALTH, 20.0);
    }

    @Override
    protected void initDataTracker() {
        super.initDataTracker();
        this.dataTracker.startTracking(TYPE, 0);
    }

    public PvzPlantType getPlantType() {
        return PvzPlantType.byId(this.dataTracker.get(TYPE));
    }

    public void setPlantType(PvzPlantType type) {
        this.dataTracker.set(TYPE, type.ordinal());
        this.hp = type.health;
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
        return false;
    }

    @Override
    public boolean isPushable() {
        return false;
    }

    @Override
    public boolean canImmediatelyDespawn(double distanceSquared) {
        return false;
    }
}
