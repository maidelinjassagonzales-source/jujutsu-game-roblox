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
    // Mago Larguirucho: el agujero de las salchichas.
    private int spellCooldown = 100;
    private int holeTicks = -1;
    private BlockPos holeCenter;
    private final java.util.Map<BlockPos, net.minecraft.block.BlockState> holeBlocks = new java.util.LinkedHashMap<>();

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
            if (profile == NpcProfile.MAGO_LARGUIRUCHO && !firstTime && holeTicks < 0 && spellCooldown <= 400) {
                openSausageHole(world, player);
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

    /** El Mago Larguirucho agita la varita, abre un agujero en el suelo y de él salen salchichas saltando. */
    private void openSausageHole(ServerWorld world, PlayerEntity near) {
        Vec3d dir = near != null ? near.getPos().subtract(getPos()).multiply(1, 0, 1) : Vec3d.fromPolar(0, getYaw());
        dir = dir.lengthSquared() < 0.01 ? new Vec3d(0, 0, 1) : dir.normalize();
        double dist = near != null ? Math.min(3.5, Math.max(2.0, near.distanceTo(this) / 2)) : 3.0;
        BlockPos top = world.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES,
                BlockPos.ofFloored(getX() + dir.x * dist, getY(), getZ() + dir.z * dist));
        holeCenter = top.down();
        holeBlocks.clear();
        for (int dx = -1; dx <= 1; dx++) {
            for (int dz = -1; dz <= 1; dz++) {
                for (int dy = 0; dy >= -1; dy--) {
                    BlockPos pos = holeCenter.add(dx, dy, dz);
                    net.minecraft.block.BlockState state = world.getBlockState(pos);
                    if (state.isAir() || !state.getFluidState().isEmpty() || state.hasBlockEntity()
                            || state.getHardness(world, pos) < 0) {
                        continue;
                    }
                    holeBlocks.put(pos.toImmutable(), state);
                    world.setBlockState(pos, net.minecraft.block.Blocks.AIR.getDefaultState(), 2);
                }
            }
        }
        swingHand(Hand.MAIN_HAND);
        world.playSound(null, holeCenter, SoundEvents.ENTITY_EVOKER_CAST_SPELL, SoundCategory.NEUTRAL, 1.5f, 1.2f);
        world.spawnParticles(net.minecraft.particle.ParticleTypes.WITCH, getX(), getY() + 2.6, getZ(), 20, 0.3, 0.3, 0.3, 0.1);
        world.spawnParticles(net.minecraft.particle.ParticleTypes.PORTAL, holeCenter.getX() + 0.5, holeCenter.getY() + 1,
                holeCenter.getZ() + 0.5, 80, 1.2, 0.3, 1.2, 0.4);
        String[] shouts = {"¡Abracadabra... SALCHICHA!", "¡Por las barbas de Merlín, que salgan las salchichas!",
                "¡Agujerus salchichus!", "¡Hechizo de la parrillada eterna!"};
        String shout = shouts[random.nextInt(shouts.length)];
        world.getPlayers(p -> p.squaredDistanceTo(this) < 32 * 32).forEach(p -> say(p, shout));
        holeTicks = 0;
        spellCooldown = 600;
    }

    private void sausageHoleTick(ServerWorld world) {
        if (holeTicks < 0 || holeCenter == null) {
            return;
        }
        holeTicks++;
        double cx = holeCenter.getX() + 0.5, cz = holeCenter.getZ() + 0.5;
        double bottom = holeCenter.getY() - 1;
        if (holeTicks % 4 == 0 && holeTicks < 60) {
            world.spawnParticles(net.minecraft.particle.ParticleTypes.LARGE_SMOKE, cx, bottom + 0.5, cz, 4, 0.6, 0.2, 0.6, 0.01);
        }
        if (holeTicks >= 10 && holeTicks <= 50 && holeTicks % 6 == 4) {
            SalchichaEntity sausage = com.turbopapu.registry.ModEntities.SALCHICHA.create(world);
            if (sausage != null) {
                sausage.refreshPositionAndAngles(cx + (random.nextDouble() - 0.5), bottom + 0.2, cz + (random.nextDouble() - 0.5),
                        random.nextFloat() * 360f, 0);
                sausage.setVelocity((random.nextDouble() - 0.5) * 0.5, 0.75 + random.nextDouble() * 0.3, (random.nextDouble() - 0.5) * 0.5);
                world.spawnEntity(sausage);
                world.playSound(null, holeCenter, SoundEvents.ENTITY_SLIME_JUMP_SMALL, SoundCategory.NEUTRAL, 1f, 1.4f + random.nextFloat() * 0.4f);
            }
        }
        if (holeTicks >= 100) {
            closeSausageHole(world, false);
        }
    }

    /** Tapa el agujero dejando el suelo como estaba. */
    private void closeSausageHole(ServerWorld world, boolean force) {
        java.util.Iterator<java.util.Map.Entry<BlockPos, net.minecraft.block.BlockState>> it = holeBlocks.entrySet().iterator();
        while (it.hasNext()) {
            java.util.Map.Entry<BlockPos, net.minecraft.block.BlockState> e = it.next();
            BlockPos pos = e.getKey();
            if (!world.isChunkLoaded(pos)) {
                continue;
            }
            // Lo que siga dentro del agujero sube a la superficie antes de taparlo.
            for (net.minecraft.entity.Entity inside : world.getOtherEntities(null, new net.minecraft.util.math.Box(pos))) {
                inside.requestTeleport(inside.getX(), holeCenter.getY() + 1.0, inside.getZ());
            }
            if (world.getBlockState(pos).isAir()) {
                world.setBlockState(pos, e.getValue(), 3);
            }
            it.remove();
        }
        if (holeBlocks.isEmpty() || force || holeTicks > 400) {
            holeBlocks.clear();
            holeTicks = -1;
            holeCenter = null;
        }
    }

    private void magoTick(ServerWorld world) {
        if (spellCooldown > 0) {
            spellCooldown--;
        }
        sausageHoleTick(world);
        if (holeTicks < 0 && spellCooldown <= 0 && age % 20 == 0 && random.nextInt(15) == 0) {
            PlayerEntity player = world.getClosestPlayer(this, 12);
            if (player != null && !player.isSpectator()) {
                openSausageHole(world, player);
            }
        }
    }

    @Override
    public void remove(RemovalReason reason) {
        if (getWorld() instanceof ServerWorld world && !holeBlocks.isEmpty()) {
            closeSausageHole(world, true);
        }
        super.remove(reason);
    }

    @Override
    public void tick() {
        super.tick();
        if (getWorld() instanceof ServerWorld world && getProfile() == NpcProfile.ALPHATEMP) {
            alphatempTick(world);
        }
        if (getWorld() instanceof ServerWorld world && getProfile() == NpcProfile.MAGO_LARGUIRUCHO) {
            magoTick(world);
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
