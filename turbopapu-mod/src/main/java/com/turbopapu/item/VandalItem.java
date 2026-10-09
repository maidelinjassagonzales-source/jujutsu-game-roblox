package com.turbopapu.item;

import com.turbopapu.fight.BossFight;
import net.minecraft.entity.Entity;
import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.entity.projectile.ProjectileUtil;
import net.minecraft.item.ItemStack;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.util.UseAction;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.EntityHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.RaycastContext;
import net.minecraft.world.World;

/**
 * La Vandal: arma automática que dispara mientras mantienes clic derecho.
 * 25 balas por cargador, recarga de 2 segundos (agáchate + clic para recargar antes),
 * headshot x3. Cuanto más rato disparas, más se abre el retroceso (spray), como en Valorant.
 */
public class VandalItem extends TooltipItem {
    public static final int MAG = 25;
    private static final int RELOAD_TICKS = 40;
    private static final int FIRE_INTERVAL = 3;

    public VandalItem(Settings settings) {
        super(settings, "vandal");
    }

    public static int getAmmo(ItemStack stack) {
        NbtCompound nbt = stack.getNbt();
        return nbt == null || !nbt.contains("Ammo") ? MAG : nbt.getInt("Ammo");
    }

    public static int getReload(ItemStack stack) {
        NbtCompound nbt = stack.getNbt();
        return nbt == null ? 0 : nbt.getInt("Reload");
    }

    private static void startReload(World world, LivingEntity user, ItemStack stack) {
        if (getReload(stack) > 0 || getAmmo(stack) >= MAG) {
            return;
        }
        stack.getOrCreateNbt().putInt("Reload", RELOAD_TICKS);
        world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ITEM_CROSSBOW_LOADING_START, SoundCategory.PLAYERS, 1f, 1.3f);
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        ItemStack stack = user.getStackInHand(hand);
        if (user.isSneaking()) {
            if (!world.isClient) {
                startReload(world, user, stack);
            }
            return TypedActionResult.success(stack, world.isClient);
        }
        if (getReload(stack) > 0) {
            return TypedActionResult.fail(stack);
        }
        user.setCurrentHand(hand);
        return TypedActionResult.consume(stack);
    }

    @Override
    public UseAction getUseAction(ItemStack stack) {
        return UseAction.NONE;
    }

    @Override
    public int getMaxUseTime(ItemStack stack) {
        return 72000;
    }

    @Override
    public void usageTick(World world, LivingEntity user, ItemStack stack, int remainingUseTicks) {
        int held = getMaxUseTime(stack) - remainingUseTicks;
        if (held % FIRE_INTERVAL != 0 || getReload(stack) > 0) {
            return;
        }
        if (getAmmo(stack) <= 0) {
            if (!world.isClient) {
                startReload(world, user, stack);
            }
            return;
        }
        if (world.isClient) {
            // Retroceso: la mira sube un poco con cada disparo.
            user.setPitch(user.getPitch() - 0.5f - Math.min(held, 30) * 0.02f);
            return;
        }
        stack.getOrCreateNbt().putInt("Ammo", getAmmo(stack) - 1);
        fire((ServerWorld) world, user, Math.min(held / FIRE_INTERVAL, 12));
    }

    private void fire(ServerWorld world, LivingEntity user, int sprayLevel) {
        float spread = 0.4f + sprayLevel * 0.35f;
        float yaw = user.getYaw() + (user.getRandom().nextFloat() - 0.5f) * spread;
        float pitch = user.getPitch() + (user.getRandom().nextFloat() - 0.5f) * spread;
        Vec3d dir = Vec3d.fromPolar(pitch, yaw);
        Vec3d start = user.getEyePos();
        Vec3d end = start.add(dir.multiply(64));

        BlockHitResult blockHit = world.raycast(new RaycastContext(start, end, RaycastContext.ShapeType.COLLIDER,
                RaycastContext.FluidHandling.NONE, user));
        if (blockHit.getType() != HitResult.Type.MISS) {
            end = blockHit.getPos();
        }
        Box box = user.getBoundingBox().stretch(end.subtract(start)).expand(1.0);
        EntityHitResult entityHit = ProjectileUtil.raycast(user, start, end, box,
                e -> e != user && !e.isSpectator() && e.canHit() && e instanceof LivingEntity, start.squaredDistanceTo(end));

        world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ENTITY_FIREWORK_ROCKET_BLAST, SoundCategory.PLAYERS, 1.2f, 1.8f);
        Vec3d hitPos = entityHit != null ? entityHit.getPos() : end;
        double len = hitPos.distanceTo(start);
        for (double d = 1.5; d < len; d += 1.5) {
            Vec3d p = start.add(dir.multiply(d));
            world.spawnParticles(ParticleTypes.CRIT, p.x, p.y - 0.1, p.z, 1, 0, 0, 0, 0);
        }
        if (entityHit != null && entityHit.getEntity() instanceof LivingEntity target) {
            boolean headshot = hitPos.y > target.getEyeY() - 0.3;
            float damage = headshot ? 13f : 4.5f;
            target.timeUntilRegen = 0;
            target.damage(user instanceof PlayerEntity p ? world.getDamageSources().playerAttack(p) : world.getDamageSources().mobAttack(user), damage);
            world.spawnParticles(ParticleTypes.DAMAGE_INDICATOR, hitPos.x, hitPos.y, hitPos.z, headshot ? 6 : 2, 0.1, 0.1, 0.1, 0.1);
            if (headshot) {
                world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ENTITY_ARROW_HIT_PLAYER, SoundCategory.PLAYERS, 1f, 1.6f);
                if (user instanceof PlayerEntity p) {
                    p.sendMessage(Text.literal("¡HEADSHOT!").formatted(Formatting.RED, Formatting.BOLD), true);
                }
            }
            BossFight.onShot(target);
        } else if (blockHit.getType() == HitResult.Type.BLOCK) {
            world.spawnParticles(ParticleTypes.SMOKE, end.x, end.y, end.z, 3, 0.05, 0.05, 0.05, 0.01);
        }
    }

    @Override
    public void inventoryTick(ItemStack stack, World world, Entity entity, int slot, boolean selected) {
        if (world.isClient) {
            return;
        }
        int reload = getReload(stack);
        if (reload > 0) {
            stack.getOrCreateNbt().putInt("Reload", reload - 1);
            if (reload - 1 == 0) {
                stack.getOrCreateNbt().putInt("Ammo", MAG);
                world.playSound(null, entity.getX(), entity.getY(), entity.getZ(), SoundEvents.ITEM_CROSSBOW_LOADING_END, SoundCategory.PLAYERS, 1f, 1.4f);
            }
        }
    }

    @Override
    public boolean allowNbtUpdateAnimation(PlayerEntity player, Hand hand, ItemStack oldStack, ItemStack newStack) {
        return false;
    }

    @Override
    public boolean isItemBarVisible(ItemStack stack) {
        return true;
    }

    @Override
    public int getItemBarStep(ItemStack stack) {
        return Math.round(13f * getAmmo(stack) / MAG);
    }

    @Override
    public int getItemBarColor(ItemStack stack) {
        return getReload(stack) > 0 ? 0xFFAA00 : MathHelper.hsvToRgb(0.0f, 0.75f, 1.0f);
    }
}
