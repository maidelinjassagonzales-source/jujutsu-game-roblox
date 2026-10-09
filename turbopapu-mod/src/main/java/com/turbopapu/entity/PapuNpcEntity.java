package com.turbopapu.entity;

import com.turbopapu.world.IcebergBuilder;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.ItemEntity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.ai.goal.*;
import net.minecraft.entity.attribute.DefaultAttributeContainer;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.damage.DamageSource;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.entity.mob.PathAwareEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtElement;
import net.minecraft.nbt.NbtList;
import net.minecraft.nbt.NbtString;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.ActionResult;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

import java.util.HashSet;
import java.util.Set;

/** Personajes con diálogo: Alphatemp, Alphafaterfur, William_Piraton, Juanma, Guinxu, elink_64 y Verity Gorda. */
public class PapuNpcEntity extends PathAwareEntity {
    private final Set<String> giftedPlayers = new HashSet<>();
    private int lineIndex;
    private int moonwalkTicks;
    private int icebergCooldown = 200;

    public PapuNpcEntity(EntityType<? extends PathAwareEntity> type, World world) {
        super(type, world);
        this.setCustomName(Text.literal(getProfile().displayName).formatted(getProfile().color));
        this.setCustomNameVisible(true);
        this.setInvulnerable(getProfile().invulnerable);
    }

    public static DefaultAttributeContainer.Builder createAttributes() {
        return MobEntity.createMobAttributes()
                .add(EntityAttributes.GENERIC_MAX_HEALTH, 40.0)
                .add(EntityAttributes.GENERIC_MOVEMENT_SPEED, 0.25)
                .add(EntityAttributes.GENERIC_ATTACK_DAMAGE, 5.0)
                .add(EntityAttributes.GENERIC_FOLLOW_RANGE, 24.0);
    }

    public NpcProfile getProfile() {
        return NpcProfile.of(getType());
    }

    @Override
    protected void initGoals() {
        NpcProfile profile = getProfile();
        this.goalSelector.add(0, new SwimGoal(this));
        if (profile.hostileWhenHit) {
            this.goalSelector.add(1, new MeleeAttackGoal(this, 1.2, true));
            this.targetSelector.add(1, new RevengeGoal(this));
        }
        if (profile.wanders) {
            this.goalSelector.add(5, new WanderAroundFarGoal(this, 0.6));
        }
        this.goalSelector.add(6, new LookAtEntityGoal(this, PlayerEntity.class, 8.0f));
        this.goalSelector.add(7, new LookAroundGoal(this));
    }

    @Override
    protected ActionResult interactMob(PlayerEntity player, Hand hand) {
        if (hand != Hand.MAIN_HAND) {
            return ActionResult.PASS;
        }
        if (getWorld() instanceof ServerWorld world) {
            NpcProfile profile = getProfile();
            this.getLookControl().lookAt(player);
            String id = player.getUuidAsString();
            boolean firstTime = !giftedPlayers.contains(id);
            String base = profile.textureName();
            if (player instanceof net.minecraft.server.network.ServerPlayerEntity serverPlayer) {
                if (firstTime) {
                    com.turbopapu.network.ModPackets.dialogue(serverPlayer, base + "_intro", 0, getId());
                } else {
                    com.turbopapu.network.ModPackets.dialogue(serverPlayer, base + "_charla", lineIndex++, getId());
                }
            }
            if (firstTime) {
                giftedPlayers.add(id);
                ItemStack[] gifts = profile.gifts(world);
                if (gifts.length > 0) {
                    for (ItemStack gift : gifts) {
                        if (!player.giveItemStack(gift.copy())) {
                            player.dropItem(gift.copy(), false);
                        }
                        player.sendMessage(Text.translatable("message.turbopapu.gift", profile.displayName, gift.getName())
                                .formatted(Formatting.GREEN), false);
                    }
                    world.playSound(null, getBlockPos(), SoundEvents.ENTITY_ITEM_PICKUP, SoundCategory.NEUTRAL, 1f, 1f);
                }
            }

            if (profile == NpcProfile.ALPHATEMP && icebergCooldown <= 0 && !firstTime) {
                // Alphatemp puede invocar icebergs enormes sobre cualquier juego... incluido este.
                Vec3d look = player.getRotationVec(1f).multiply(16);
                BlockPos target = BlockPos.ofFloored(player.getX() + look.x, getY(), player.getZ() + look.z);
                summonIceberg(world, target, "¡ICEBERG DE " + randomGame() + "! ¡Nivel máximo!");
            }
            if (profile == NpcProfile.ELINK_64) {
                moonwalkTicks = 40;
            }
        }
        return ActionResult.success(getWorld().isClient);
    }

    private String randomGame() {
        String[] games = {"FIVE NIGHTS AT FREDDY'S", "MINECRAFT", "MARIO 64", "VALORANT", "ODDWORLD", "TURBOPAPU"};
        return games[random.nextInt(games.length)];
    }

    private void say(PlayerEntity player, String line) {
        NpcProfile profile = getProfile();
        player.sendMessage(Text.literal("<").append(Text.literal(profile.displayName).formatted(profile.color))
                .append(Text.literal("> " + line)), false);
    }

    private void summonIceberg(ServerWorld world, BlockPos near, String shout) {
        BlockPos target = world.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES, near);
        world.getPlayers(p -> p.squaredDistanceTo(this) < 48 * 48).forEach(p -> say(p, shout));
        swingHand(Hand.MAIN_HAND);
        IcebergBuilder.summon(world, target, random);
        icebergCooldown = 200;
    }

    /** Alphatemp: defiende la aldea Mudokon con icebergs y, de vez en cuando, invoca uno por diversión. */
    private void alphatempTick(ServerWorld world) {
        if (--icebergCooldown > 0 || age % 20 != 0) {
            return;
        }
        net.minecraft.entity.mob.HostileEntity enemy = world.getClosestEntity(net.minecraft.entity.mob.HostileEntity.class,
                net.minecraft.entity.ai.TargetPredicate.DEFAULT, this, getX(), getY(), getZ(), getBoundingBox().expand(20));
        if (enemy != null) {
            summonIceberg(world, enemy.getBlockPos(), "¡Fuera de mi choza! ¡ICEBERG!");
            return;
        }
        PlayerEntity player = world.getClosestPlayer(this, 24);
        if (player != null && random.nextInt(60) == 0) {
            double a = random.nextDouble() * Math.PI * 2;
            BlockPos target = BlockPos.ofFloored(getX() + Math.cos(a) * 28, getY(), getZ() + Math.sin(a) * 28);
            summonIceberg(world, target, "Nivel " + (1 + random.nextInt(9)) + " del iceberg de " + randomGame() + ": ¡ESTE ICEBERG!");
        }
    }

    @Override
    public void tick() {
        super.tick();
        if (getWorld() instanceof ServerWorld world && getProfile() == NpcProfile.ALPHATEMP) {
            alphatempTick(world);
        }
        if (!getWorld().isClient && moonwalkTicks > 0) {
            // elink_64 hace el moonwalk: camina hacia atrás deslizándose.
            moonwalkTicks--;
            Vec3d back = Vec3d.fromPolar(0, getYaw()).multiply(-0.08);
            setVelocity(back.x, getVelocity().y, back.z);
            velocityDirty = true;
        }
    }

    @Override
    public boolean damage(DamageSource source, float amount) {
        boolean hurt = super.damage(source, amount);
        if (hurt && getProfile() == NpcProfile.ALPHAFATERFUR && source.getAttacker() instanceof PlayerEntity player
                && getWorld() instanceof ServerWorld) {
            say(player, "¡¿ME HAS INTERRUMPIDO?! ¡AHORA TENGO QUE EMPEZAR EL VIDEO DE CERO!");
        }
        return hurt;
    }

    @Override
    public boolean tryAttack(net.minecraft.entity.Entity target) {
        boolean hit = super.tryAttack(target);
        if (hit && target instanceof LivingEntity living) {
            living.addVelocity(0, 0.3, 0);
        }
        return hit;
    }

    @Override
    protected void dropLoot(DamageSource source, boolean causedByPlayer) {
        if (getProfile() == NpcProfile.ALPHAFATERFUR && getWorld() instanceof ServerWorld world) {
            ItemEntity drop = new ItemEntity(world, getX(), getY(), getZ(),
                    new ItemStack(net.minecraft.item.Items.MUSIC_DISC_11));
            drop.getStack().setCustomName(Text.literal("Video de 2 horas (sin terminar)"));
            world.spawnEntity(drop);
        }
    }

    @Override
    public boolean canImmediatelyDespawn(double distanceSquared) {
        return false;
    }

    @Override
    public void writeCustomDataToNbt(NbtCompound nbt) {
        super.writeCustomDataToNbt(nbt);
        NbtList list = new NbtList();
        for (String id : giftedPlayers) {
            list.add(NbtString.of(id));
        }
        nbt.put("GiftedPlayers", list);
        nbt.putInt("LineIndex", lineIndex);
    }

    @Override
    public void readCustomDataFromNbt(NbtCompound nbt) {
        super.readCustomDataFromNbt(nbt);
        giftedPlayers.clear();
        NbtList list = nbt.getList("GiftedPlayers", NbtElement.STRING_TYPE);
        for (int i = 0; i < list.size(); i++) {
            giftedPlayers.add(list.getString(i));
        }
        lineIndex = nbt.getInt("LineIndex");
    }
}
