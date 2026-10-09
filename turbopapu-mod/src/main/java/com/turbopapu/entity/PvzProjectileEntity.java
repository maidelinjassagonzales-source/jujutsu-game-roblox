package com.turbopapu.entity;

import com.turbopapu.fight.BossFight;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.data.DataTracker;
import net.minecraft.entity.data.TrackedData;
import net.minecraft.entity.data.TrackedDataHandlerRegistry;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.listener.ClientPlayPacketListener;
import net.minecraft.network.packet.Packet;
import net.minecraft.network.packet.s2c.play.EntitySpawnS2CPacket;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

/** Proyectil del Plantas vs Zombies (hielo, guisante, coco, mate). Avanza recto por su fila. */
public class PvzProjectileEntity extends Entity implements net.minecraft.entity.FlyingItemEntity {
    private static final TrackedData<ItemStack> STACK = DataTracker.registerData(PvzProjectileEntity.class, TrackedDataHandlerRegistry.ITEM_STACK);

    public int row;
    public float damage;
    public boolean slows;
    public double splash;

    public PvzProjectileEntity(EntityType<?> type, World world) {
        super(type, world);
        this.noClip = true;
        this.setVelocity(new Vec3d(0.5, 0, 0));
    }

    @Override
    protected void initDataTracker() {
        this.dataTracker.startTracking(STACK, new ItemStack(Items.SLIME_BALL));
    }

    public void setStack(ItemStack stack) {
        this.dataTracker.set(STACK, stack);
    }

    @Override
    public ItemStack getStack() {
        return this.dataTracker.get(STACK);
    }

    @Override
    public void tick() {
        super.tick();
        Vec3d v = getVelocity();
        setPosition(getX() + v.x, getY() + v.y, getZ() + v.z);
        if (!getWorld().isClient && (age > 200 || (age > 40 && !BossFight.isPvzActive()))) {
            discard();
        }
    }

    @Override
    protected void readCustomDataFromNbt(NbtCompound nbt) {
    }

    @Override
    protected void writeCustomDataToNbt(NbtCompound nbt) {
    }

    @Override
    public boolean shouldSave() {
        return false;
    }

    @Override
    public Packet<ClientPlayPacketListener> createSpawnPacket() {
        return new EntitySpawnS2CPacket(this);
    }
}
