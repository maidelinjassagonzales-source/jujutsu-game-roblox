package com.turbopapu.entity;

import com.turbopapu.registry.ModItems;
import com.turbopapu.world.Travel;
import net.minecraft.entity.Entity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.MovementType;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.data.DataTracker;
import net.minecraft.entity.data.TrackedData;
import net.minecraft.entity.data.TrackedDataHandlerRegistry;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.network.listener.ClientPlayPacketListener;
import net.minecraft.network.packet.Packet;
import net.minecraft.network.packet.s2c.play.EntitySpawnS2CPacket;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

/** La nave para ir al Planeta TurboPapu (y volver). Súbete con clic derecho: cuenta atrás y ¡despegue! */
public class RocketEntity extends Entity {
    private static final TrackedData<Integer> FLIGHT = DataTracker.registerData(RocketEntity.class, TrackedDataHandlerRegistry.INTEGER);
    private static final int COUNTDOWN = 60;
    private static final int FLIGHT_TIME = COUNTDOWN + 110;

    public RocketEntity(EntityType<?> type, World world) {
        super(type, world);
    }

    @Override
    protected void initDataTracker() {
        this.dataTracker.startTracking(FLIGHT, -1);
    }

    /** -1 = en tierra, 0..COUNTDOWN = cuenta atrás, más = volando. */
    public int getFlight() {
        return this.dataTracker.get(FLIGHT);
    }

    public boolean isFlying() {
        return getFlight() > COUNTDOWN;
    }

    @Override
    public ActionResult interact(PlayerEntity player, Hand hand) {
        if (getFlight() >= 0 || hasPassengers()) {
            return ActionResult.PASS;
        }
        if (!getWorld().isClient) {
            player.startRiding(this);
            this.dataTracker.set(FLIGHT, 0);
        }
        return ActionResult.success(getWorld().isClient);
    }

    @Override
    public void tick() {
        super.tick();
        World world = getWorld();
        int flight = getFlight();

        if (flight < 0) {
            // Gravedad normal mientras está aparcado.
            if (!isOnGround()) {
                setVelocity(getVelocity().add(0, -0.04, 0));
            } else {
                setVelocity(Vec3d.ZERO);
            }
            move(MovementType.SELF, getVelocity());
            return;
        }

        if (world.isClient) {
            int n = flight > COUNTDOWN ? 8 : 2;
            for (int i = 0; i < n; i++) {
                world.addParticle(flight > COUNTDOWN ? ParticleTypes.FLAME : ParticleTypes.SMOKE,
                        getX() + random.nextGaussian() * 0.3, getY() - 0.2, getZ() + random.nextGaussian() * 0.3,
                        random.nextGaussian() * 0.05, -0.4, random.nextGaussian() * 0.05);
                world.addParticle(ParticleTypes.CLOUD, getX() + random.nextGaussian() * 0.6, getY() - 0.5,
                        getZ() + random.nextGaussian() * 0.6, 0, -0.1, 0);
            }
        }
        if (flight > COUNTDOWN) {
            double speed = Math.min(0.05 + (flight - COUNTDOWN) * 0.02, 2.5);
            setPosition(getX(), getY() + speed, getZ());
        }
        if (world.isClient) {
            return;
        }

        if (!hasPassengers() && flight <= COUNTDOWN) {
            // Se bajaron durante la cuenta atrás: cancelar.
            this.dataTracker.set(FLIGHT, -1);
            return;
        }
        if (flight % 20 == 0 && flight < COUNTDOWN) {
            int secs = 3 - flight / 20;
            for (Entity e : getPassengerList()) {
                if (e instanceof PlayerEntity p) {
                    p.sendMessage(Text.literal(secs + "...").formatted(Formatting.GOLD, Formatting.BOLD), true);
                }
            }
            world.playSound(null, getX(), getY(), getZ(), SoundEvents.UI_BUTTON_CLICK.value(), SoundCategory.NEUTRAL, 1f, 0.5f + flight / 60f);
        }
        if (flight == COUNTDOWN) {
            for (Entity e : getPassengerList()) {
                if (e instanceof PlayerEntity p) {
                    p.sendMessage(Text.translatable("message.turbopapu.liftoff").formatted(Formatting.GOLD, Formatting.BOLD), true);
                }
            }
            world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_FIREWORK_ROCKET_LAUNCH, SoundCategory.NEUTRAL, 4f, 0.5f);
        }
        if (flight > COUNTDOWN && flight % 8 == 0) {
            world.playSound(null, getX(), getY(), getZ(), SoundEvents.ENTITY_BLAZE_SHOOT, SoundCategory.NEUTRAL, 2f, 0.3f);
        }
        if (flight >= FLIGHT_TIME || getY() > world.getTopY() + 64) {
            for (Entity e : getPassengerList()) {
                if (e instanceof ServerPlayerEntity player) {
                    e.stopRiding();
                    Travel.travel(player, (ServerWorld) world);
                }
            }
            discard();
            return;
        }
        this.dataTracker.set(FLIGHT, flight + 1);
    }

    @Override
    public boolean damage(DamageSource source, float amount) {
        if (isInvulnerableTo(source)) {
            return false;
        }
        if (!getWorld().isClient && getFlight() < 0 && !isRemoved()) {
            if (!(source.getAttacker() instanceof PlayerEntity p && p.getAbilities().creativeMode)) {
                dropItem(ModItems.COHETE);
            }
            discard();
        }
        return true;
    }

    @Override
    public boolean canHit() {
        return !isRemoved();
    }

    @Override
    public boolean isCollidable() {
        return true;
    }

    @Override
    public double getMountedHeightOffset() {
        return 1.2;
    }

    @Override
    public boolean shouldRender(double distance) {
        return distance < 256 * 256;
    }

    @Override
    protected void readCustomDataFromNbt(NbtCompound nbt) {
    }

    @Override
    protected void writeCustomDataToNbt(NbtCompound nbt) {
    }

    @Override
    public Packet<ClientPlayPacketListener> createSpawnPacket() {
        return new EntitySpawnS2CPacket(this);
    }
}
