package com.turbopapu.entity;

import com.turbopapu.world.MeteorEvent;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.listener.ClientPlayPacketListener;
import net.minecraft.network.packet.Packet;
import net.minecraft.network.packet.s2c.play.EntitySpawnS2CPacket;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

/** El meteorito que mandan los Turbopapuenses. Cae en línea recta hacia su objetivo dejando fuego y humo. */
public class MeteorEntity extends Entity {
    private BlockPos target = BlockPos.ORIGIN;
    private boolean loadedFromDisk;
    private int impactTicks = -1;

    public MeteorEntity(EntityType<?> type, World world) {
        super(type, world);
        this.noClip = true;
    }

    public void setTarget(BlockPos target) {
        this.target = target;
    }

    @Override
    protected void initDataTracker() {
    }

    @Override
    public void tick() {
        super.tick();
        World world = getWorld();
        if (impactTicks >= 0) {
            // Ya cayó: espera un poco antes de mostrar la carta y desaparecer.
            if (!world.isClient && ++impactTicks >= 50) {
                MeteorEvent.afterImpact((ServerWorld) world, target);
                discard();
            }
            return;
        }
        Vec3d vel = getVelocity();
        setPosition(getX() + vel.x, getY() + vel.y, getZ() + vel.z);

        if (world.isClient) {
            for (int i = 0; i < 6; i++) {
                world.addParticle(ParticleTypes.FLAME, getX() + random.nextGaussian(), getY() + random.nextGaussian(),
                        getZ() + random.nextGaussian(), -vel.x * 0.2, -vel.y * 0.2, -vel.z * 0.2);
                world.addParticle(ParticleTypes.LARGE_SMOKE, getX() + random.nextGaussian() * 1.5, getY() + 1 + random.nextGaussian(),
                        getZ() + random.nextGaussian() * 1.5, 0, 0.05, 0);
            }
            world.addParticle(ParticleTypes.LAVA, getX(), getY(), getZ(), 0, 0, 0);
            return;
        }

        if (loadedFromDisk) {
            discard();
            return;
        }
        if (age % 10 == 0) {
            world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_BLAZE_SHOOT, SoundCategory.AMBIENT, 6f, 0.4f);
        }
        if (getY() <= target.getY() + 1 || age > 400) {
            impactTicks = 0;
            setVelocity(Vec3d.ZERO);
            setInvisible(true);
            MeteorEvent.impact((ServerWorld) world, target);
        }
    }

    @Override
    public boolean shouldRender(double distance) {
        return true;
    }

    @Override
    protected void readCustomDataFromNbt(NbtCompound nbt) {
        loadedFromDisk = true;
    }

    @Override
    protected void writeCustomDataToNbt(NbtCompound nbt) {
    }

    @Override
    public Packet<ClientPlayPacketListener> createSpawnPacket() {
        return new EntitySpawnS2CPacket(this);
    }
}
