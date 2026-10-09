package com.turbopapu.entity;

import com.turbopapu.world.TurboState;
import net.minecraft.entity.EntityData;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.SpawnReason;
import net.minecraft.entity.ai.goal.*;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.data.DataTracker;
import net.minecraft.entity.data.TrackedData;
import net.minecraft.entity.data.TrackedDataHandlerRegistry;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.mob.PathAwareEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.world.LocalDifficulty;
import net.minecraft.world.ServerWorldAccess;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

/**
 * Habitante del Planeta TurboPapu: igual que el planeta (bola naranja/azul con ojos, boca y cascos gamer) pero con patas.
 * Por culpa de Sualenidus la mayoría están dormidos; solo unos pocos aguantan despiertos.
 */
public class TurboPapuenseEntity extends PathAwareEntity {
    private static final TrackedData<Boolean> DORMIDO = DataTracker.registerData(TurboPapuenseEntity.class, TrackedDataHandlerRegistry.BOOLEAN);

    private static final String[] AWAKE_LINES = {
            "¡Viniste! ¡Leíste nuestra carta! Pensábamos que el meteorito iba a caer en el mar...",
            "Somos de los pocos que siguen despiertos. Los demás... huelen a lavanda y roncan.",
            "Sualenidus vive en su guarida al noreste. Pregúntale a Guinxu, tiene una brújula.",
            "Si te duerme, ¡bebe mate! Juanma tiene de sobra.",
            "Cuidado: Sualenidus habla de armas de Valorant sin parar. Es su forma de hipnotizar.",
            "¡Turbo! ¡Papu! ¡Turbo! ¡Papu!"
    };
    private static final String[] SLEEP_LINES = {
            "Zzz... la Vandal... es mejor... zzz...",
            "Zzz... huele... a lavanda... zzz...",
            "Zzz... cinco minutitos más... zzz...",
            "Zzz... JAJAJAJA... (se ríe en sueños como Sualenidus)..."
    };
    private static final String[] HAPPY_LINES = {
            "¡ESTAMOS DESPIERTOS! ¡GRACIAS, HÉROE!",
            "¡Fiesta en el planeta! ¿Alguien sabe dónde está el cohete? ¿Y por qué hay un tigre?",
            "¡Turbo! ¡Papu! ¡Turbo! ¡Papu! ¡Ganamos!"
    };

    public TurboPapuenseEntity(EntityType<? extends PathAwareEntity> type, World world) {
        super(type, world);
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return MobEntity.createMobAttributes()
                .add(EntityAttributes.GENERIC_MAX_HEALTH, 16.0)
                .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.28);
    }

    @Override
    protected void initDataTracker() {
        super.initDataTracker();
        this.dataTracker.startTracking(DORMIDO, false);
    }

    @Override
    protected void initGoals() {
        this.goalSelector.add(0, new SwimGoal(this));
        this.goalSelector.add(1, new EscapeDangerGoal(this, 1.4));
        this.goalSelector.add(5, new WanderAroundFarGoal(this, 0.8));
        this.goalSelector.add(6, new LookAtEntityGoal(this, PlayerEntity.class, 8.0f));
        this.goalSelector.add(7, new LookAroundGoal(this));
    }

    public boolean isDormido() {
        return this.dataTracker.get(DORMIDO);
    }

    public void setDormido(boolean dormido) {
        this.dataTracker.set(DORMIDO, dormido);
        this.setAiDisabled(dormido);
    }

    @Override
    public EntityData initialize(ServerWorldAccess world, LocalDifficulty difficulty, SpawnReason spawnReason,
                                 @Nullable EntityData entityData, @Nullable NbtCompound entityNbt) {
        if (spawnReason == SpawnReason.NATURAL || spawnReason == SpawnReason.CHUNK_GENERATION) {
            // Si Sualenidus ya fue derrotado, tick() los despierta enseguida.
            setDormido(random.nextFloat() < 0.8f);
        }
        return super.initialize(world, difficulty, spawnReason, entityData, entityNbt);
    }

    @Override
    public void tick() {
        super.tick();
        World world = getWorld();
        if (world.isClient) {
            if (isDormido() && age % 30 == 0) {
                world.addParticle(ParticleTypes.NOTE, getX(), getY() + 1.4, getZ(), 0.6, 0, 0);
            }
            return;
        }
        if (age % 40 == 0 && world instanceof ServerWorld serverWorld) {
            boolean defeated = TurboState.get(serverWorld.getServer()).sualenidusDefeated;
            if (defeated && isDormido()) {
                setDormido(false);
                serverWorld.spawnParticles(ParticleTypes.HAPPY_VILLAGER, getX(), getY() + 1, getZ(), 10, 0.5, 0.5, 0.5, 0.1);
            }
            // ¡Fiesta! Después de la victoria saltan de felicidad.
            if (defeated && isOnGround() && random.nextInt(3) == 0) {
                jump();
                serverWorld.spawnParticles(ParticleTypes.HEART, getX(), getY() + 1.3, getZ(), 1, 0.2, 0.2, 0.2, 0);
            }
        }
    }

    @Override
    protected ActionResult interactMob(PlayerEntity player, Hand hand) {
        if (hand != Hand.MAIN_HAND) {
            return ActionResult.PASS;
        }
        if (getWorld() instanceof ServerWorld serverWorld) {
            String key = isDormido() ? "turbopapuense_dormido"
                    : TurboState.get(serverWorld.getServer()).sualenidusDefeated ? "turbopapuense_feliz" : "turbopapuense_despierto";
            if (player instanceof net.minecraft.server.network.ServerPlayerEntity serverPlayer) {
                com.turbopapu.network.ModPackets.dialogue(serverPlayer, key, random.nextInt(100), getId());
            }
        }
        return ActionResult.success(getWorld().isClient);
    }

    @Override
    protected @Nullable SoundEvent getAmbientSound() {
        return isDormido() ? SoundEvents.ENTITY_FOX_SLEEP : SoundEvents.ENTITY_VILLAGER_AMBIENT;
    }

    @Override
    public float getSoundPitch() {
        return 1.6f;
    }

    @Override
    public void writeCustomDataToNbt(NbtCompound nbt) {
        super.writeCustomDataToNbt(nbt);
        nbt.putBoolean("Dormido", isDormido());
    }

    @Override
    public void readCustomDataFromNbt(NbtCompound nbt) {
        super.readCustomDataFromNbt(nbt);
        setDormido(nbt.getBoolean("Dormido"));
    }
}
