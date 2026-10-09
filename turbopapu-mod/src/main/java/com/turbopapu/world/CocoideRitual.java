package com.turbopapu.world;

import com.turbopapu.entity.PapuNpcEntity;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModEntities;
import com.turbopapu.registry.ModItems;
import net.minecraft.entity.ItemEntity;
import net.minecraft.entity.LightningEntity;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.network.packet.s2c.play.SubtitleS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleFadeS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleS2CPacket;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Vec3d;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Capítulo 1: el ritual del Chamán Cocoide. Con plátanos de Canarias, un aguacate cubano, un mate argentino y
 * mantequilla del Gordo se completa el ritual... y aparece el Gordo Pañales, que se come el mundo cocoide.
 */
public final class CocoideRitual {
    public static final Item[] OFFERINGS = {ModItems.PLATANO_CANARIAS, ModItems.AGUACATE, ModItems.MATE, ModItems.MANTEQUILLA};
    private static final String[] OFFERING_NAMES = {"Plátanos de Canarias", "Aguacate cubano", "Mate argentino", "Mantequilla del Gordo"};

    private static CocoideRitual current;

    private final ServerWorld world;
    private final UUID playerId;
    private final BlockPos altar;
    private final List<ItemEntity> floating = new ArrayList<>();
    private PapuNpcEntity gordo;
    private int t;

    private CocoideRitual(ServerWorld world, ServerPlayerEntity player) {
        this.world = world;
        this.playerId = player.getUuid();
        this.altar = CoconutWorld.templeCenter();
    }

    public static boolean isBusy(ServerPlayerEntity player) {
        return (current != null && current.playerId.equals(player.getUuid())) || GordoBoss.isFighting(player);
    }

    public static boolean hasOfferings(ServerPlayerEntity player) {
        for (Item item : OFFERINGS) {
            if (!player.getInventory().containsAny(s -> s.isOf(item))) {
                return false;
            }
        }
        return true;
    }

    /** Lista de lo que falta, para que el chamán te lo diga. */
    public static String missing(ServerPlayerEntity player) {
        List<String> out = new ArrayList<>();
        for (int i = 0; i < OFFERINGS.length; i++) {
            Item item = OFFERINGS[i];
            if (!player.getInventory().containsAny(s -> s.isOf(item))) {
                out.add(OFFERING_NAMES[i]);
            }
        }
        return String.join(", ", out);
    }

    /** Acción del diálogo: entregar las ofrendas y empezar. */
    public static void tryStart(ServerPlayerEntity player) {
        TurboState state = TurboState.get(player.getServer());
        if (current != null || GordoBoss.isActive() || state.chapter1Done
                || player.getWorld().getRegistryKey() != ModDimensions.LATA_COCO) {
            return;
        }
        if (!state.ritualPaid) {
            if (!hasOfferings(player)) {
                player.sendMessage(Text.literal("Te falta: " + missing(player)).formatted(Formatting.RED), false);
                return;
            }
            for (Item item : OFFERINGS) {
                var inv = player.getInventory();
                for (int slot = 0; slot < inv.size(); slot++) {
                    if (inv.getStack(slot).isOf(item)) {
                        inv.removeStack(slot, 1);
                        break;
                    }
                }
            }
            state.ritualPaid = true;
            state.markDirty();
        }
        current = new CocoideRitual((ServerWorld) player.getWorld(), player);
        current.begin(player);
    }

    public static void tick(MinecraftServer server) {
        GordoBoss.tick(server);
        if (current == null) {
            return;
        }
        ServerPlayerEntity player = server.getPlayerManager().getPlayer(current.playerId);
        if (player == null || player.getWorld() != current.world) {
            current.cleanup();
            current = null;
            return;
        }
        current.step(player);
    }

    private void begin(ServerPlayerEntity player) {
        ModPackets.dialogue(player, "chaman_asere", 0, -1);
        double cx = altar.getX() + 0.5, cy = altar.getY() + 1.5, cz = altar.getZ() + 0.5;
        for (int i = 0; i < OFFERINGS.length; i++) {
            double a = i * Math.PI / 2;
            ItemEntity item = new ItemEntity(world, cx + Math.cos(a) * 2, cy, cz + Math.sin(a) * 2, new ItemStack(OFFERINGS[i]));
            item.setNoGravity(true);
            item.setPickupDelayInfinite();
            item.setNeverDespawn();
            item.setVelocity(Vec3d.ZERO);
            world.spawnEntity(item);
            floating.add(item);
        }
        world.playSound(null, altar, SoundEvents.BLOCK_BEACON_ACTIVATE, SoundCategory.PLAYERS, 2f, 0.6f);
    }

    private void step(ServerPlayerEntity player) {
        t++;
        double cx = altar.getX() + 0.5, cy = altar.getY() + 1.5, cz = altar.getZ() + 0.5;
        if (t < 100) {
            // Las ofrendas giran y suben sobre el altar.
            double r = 2.0 * (1 - t / 110.0);
            for (int i = 0; i < floating.size(); i++) {
                double a = i * Math.PI / 2 + t * 0.12;
                floating.get(i).setPosition(cx + Math.cos(a) * r, cy + t * 0.03, cz + Math.sin(a) * r);
                floating.get(i).setVelocity(Vec3d.ZERO);
            }
            if (t % 2 == 0) {
                double a = t * 0.3;
                world.spawnParticles(ParticleTypes.SOUL_FIRE_FLAME, cx + Math.cos(a) * 3, altar.getY() + 0.2 + t * 0.04, cz + Math.sin(a) * 3, 2, 0.05, 0.05, 0.05, 0.01);
                world.spawnParticles(ParticleTypes.ENCHANT, cx, cy + 1, cz, 10, 1, 1, 1, 0.5);
            }
            if (t % 20 == 0) {
                world.playSound(null, altar, SoundEvents.BLOCK_AMETHYST_BLOCK_CHIME, SoundCategory.PLAYERS, 2f, 0.5f + t / 100f);
            }
            player.addStatusEffect(new StatusEffectInstance(StatusEffects.SLOWNESS, 20, 4, false, false));
        } else if (t == 100) {
            floating.forEach(ItemEntity::discard);
            floating.clear();
            world.spawnParticles(ParticleTypes.FLASH, cx, cy + 3, cz, 3, 0, 0, 0, 0);
            world.spawnParticles(ParticleTypes.SOUL, cx, cy + 3, cz, 80, 2, 2, 2, 0.1);
            for (int i = 0; i < 3; i++) {
                LightningEntity bolt = EntityType.LIGHTNING_BOLT.create(world);
                if (bolt != null) {
                    bolt.refreshPositionAfterTeleport(cx + (i - 1) * 6, altar.getY(), cz + 12);
                    bolt.setCosmetic(true);
                    world.spawnEntity(bolt);
                }
            }
            title(player, Text.literal("¡RITUAL COMPLETADO!").formatted(Formatting.AQUA, Formatting.BOLD),
                    Text.literal("Algo enorme se acerca...").formatted(Formatting.GRAY));
        } else if (t == 120) {
            gordo = ModEntities.GORDO_JEFE.create(world);
            if (gordo != null) {
                gordo.refreshPositionAndAngles(cx, altar.getY() + 45, cz + 34, 180, 0);
                gordo.setAiDisabled(true);
                gordo.setNoGravity(true);
                gordo.setInvulnerable(true);
                gordo.setPersistent();
                world.spawnEntity(gordo);
                ModPackets.startCinematic(player, gordo.getId(), 270, "¡El Gordo Pañales ha venido a por el mundo cocoide!");
            }
            world.playSound(null, altar, SoundEvents.ENTITY_WARDEN_EMERGE, SoundCategory.HOSTILE, 4f, 0.6f);
        } else if (t < 220) {
            if (gordo != null) {
                gordo.setPosition(gordo.getX(), Math.max(altar.getY() - 4, gordo.getY() - 0.5), gordo.getZ());
                if (t % 10 == 0) {
                    world.spawnParticles(ParticleTypes.CLOUD, gordo.getX(), gordo.getY(), gordo.getZ(), 30, 4, 1, 4, 0.1);
                }
            }
            if (t == 219) {
                world.spawnParticles(ParticleTypes.SPLASH, cx, altar.getY(), cz + 34, 300, 8, 1, 8, 0.5);
                world.playSound(null, altar, SoundEvents.ENTITY_GENERIC_SPLASH, SoundCategory.HOSTILE, 4f, 0.5f);
            }
        } else if (t == 230) {
            ModPackets.dialogue(player, "gordo_jefe_reproche", 0, gordo == null ? -1 : gordo.getId());
        } else if (t > 330 && t < 380) {
            // Abre la boca y se lo traga todo.
            if (gordo != null) {
                Vec3d to = player.getPos().subtract(gordo.getPos()).multiply(0.03);
                gordo.setPosition(gordo.getPos().add(to.x, 0, to.z));
                world.spawnParticles(ParticleTypes.SWEEP_ATTACK, gordo.getX(), gordo.getY() + 8, gordo.getZ(), 6, 3, 2, 3, 0);
            }
            if (t % 8 == 0) {
                world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_GENERIC_EAT, SoundCategory.HOSTILE, 4f, 0.3f);
            }
            if (t == 360) {
                player.addStatusEffect(new StatusEffectInstance(StatusEffects.DARKNESS, 80, 0, false, false));
                player.addStatusEffect(new StatusEffectInstance(StatusEffects.BLINDNESS, 60, 0, false, false));
                title(player, Text.literal("¡ÑAAAAM!").formatted(Formatting.DARK_RED, Formatting.BOLD),
                        Text.literal("El Gordo Pañales se ha comido el mundo cocoide entero").formatted(Formatting.GOLD));
            }
        } else if (t == 380) {
            if (gordo != null) {
                gordo.discard();
            }
        } else if (t >= 400) {
            cleanup();
            current = null;
            GordoBoss.start(player);
        }
    }

    private void cleanup() {
        floating.forEach(ItemEntity::discard);
        floating.clear();
        if (gordo != null) {
            gordo.discard();
        }
    }

    static void title(ServerPlayerEntity player, Text title, Text subtitle) {
        player.networkHandler.sendPacket(new TitleFadeS2CPacket(10, 70, 20));
        player.networkHandler.sendPacket(new SubtitleS2CPacket(subtitle));
        player.networkHandler.sendPacket(new TitleS2CPacket(title));
    }
}
