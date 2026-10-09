package com.turbopapu.world;

import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModItems;
import net.fabricmc.fabric.api.event.player.PlayerBlockBreakEvents;
import net.minecraft.block.Blocks;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.entity.mob.SlimeEntity;
import net.minecraft.entity.boss.BossBar;
import net.minecraft.entity.boss.ServerBossBar;
import net.minecraft.item.ItemStack;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

/**
 * Jefe secreto del Capítulo 1: dentro del estómago del Gordo Pañales hay que romper los 5 núcleos de
 * mantequilla rancia (terracota amarilla) mientras la grasa (slimes) te ataca. Al romperlos todos, el Gordo
 * revienta, los Cocoides vuelven a ser libres y termina el Capítulo 1.
 */
public final class GordoBoss {
    /** El estómago del jefe está lejos del estómago "normal" de los castigos diarios. */
    private static final int OX = 2000;
    private static final int[][] CORES = {{-8, -6}, {8, -6}, {-9, 6}, {9, 6}, {0, 13}};
    private static final String[] PAIN = {
            "¡AY, MI BARRIGA! ¡Eso era mi mantequilla de reserva!",
            "¡Para! ¡Que me da ardor!",
            "¡NO! ¡Ese núcleo era de mantequilla de Soria!",
            "¡Me estoy deshinchando! ¡Esto no es justo, yo solo quería mi FP!"
    };

    private static GordoBoss current;

    private final ServerWorld world;
    private final UUID playerId;
    private final List<BlockPos> cores = new ArrayList<>();
    private final ServerBossBar bar = new ServerBossBar(Text.literal("Gordo Pañales (por dentro)").formatted(Formatting.GOLD),
            BossBar.Color.YELLOW, BossBar.Style.NOTCHED_6);
    private int t;
    private int wonAt = -1;
    private BlockPos acidAt;

    private GordoBoss(ServerWorld world, ServerPlayerEntity player) {
        this.world = world;
        this.playerId = player.getUuid();
    }

    public static void register() {
        PlayerBlockBreakEvents.AFTER.register((world, player, pos, state, blockEntity) -> {
            if (current != null && world == current.world && player instanceof ServerPlayerEntity sp) {
                current.onBreak(sp, pos);
            }
        });
    }

    public static boolean isActive() {
        return current != null;
    }

    public static boolean isFighting(ServerPlayerEntity player) {
        return current != null && current.playerId.equals(player.getUuid());
    }

    static void start(ServerPlayerEntity player) {
        ServerWorld stomach = player.getServer().getWorld(ModDimensions.ESTOMAGO);
        if (stomach == null) {
            return;
        }
        TurboState state = TurboState.get(player.getServer());
        GordoBoss boss = new GordoBoss(stomach, player);
        if (!state.bossStomachBuilt) {
            GordoEvents.buildStomach(stomach, OX, false);
            state.bossStomachBuilt = true;
            state.markDirty();
        }
        boss.buildCores();
        current = boss;
        player.teleport(stomach, OX + 0.5, GordoEvents.FLOOR + 1, GordoEvents.ARRIVAL_Z, 0, 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.NAUSEA, 120, 0, false, false));
        boss.bar.addPlayer(player);
        boss.bar.setPercent(1f);
        CocoideRitual.title(player, Text.literal("DENTRO DEL GORDO").formatted(Formatting.GOLD, Formatting.BOLD),
                Text.literal("Rompe los 5 núcleos de mantequilla rancia").formatted(Formatting.YELLOW));
        player.sendMessage(Text.literal("<Gordo Pañales> ¡Ja! Ahora formas parte de mi digestión. ¡Y los Cocoides también!")
                .formatted(Formatting.DARK_RED), false);
    }

    /** Pilares de hueso con un núcleo arriba, unidos a la isla de llegada por puentes de hueso. */
    private void buildCores() {
        int floor = GordoEvents.FLOOR;
        int az = (int) Math.floor(GordoEvents.ARRIVAL_Z);
        cores.clear();
        for (int[] c : CORES) {
            int x = OX + c[0], z = c[1];
            Build.fill(world, x - 1, floor - 6, z - 1, x + 1, floor + 1, z + 1, Blocks.BONE_BLOCK);
            BlockPos core = new BlockPos(x, floor + 2, z);
            Build.set(world, core, Blocks.YELLOW_GLAZED_TERRACOTTA.getDefaultState());
            cores.add(core);
            // Puente: primero en x, luego en z.
            int sx = OX, sz = az;
            for (int bx = Math.min(sx, x); bx <= Math.max(sx, x); bx++) {
                Build.set(world, bx, floor, sz, Blocks.BONE_BLOCK);
            }
            for (int bz = Math.min(sz, z); bz <= Math.max(sz, z); bz++) {
                Build.set(world, x, floor, bz, Blocks.BONE_BLOCK);
            }
        }
    }

    public static void tick(MinecraftServer server) {
        if (current == null) {
            return;
        }
        ServerPlayerEntity player = server.getPlayerManager().getPlayer(current.playerId);
        if (player == null || !player.isAlive() || player.getWorld() != current.world) {
            if (player != null) {
                player.sendMessage(Text.literal("El Gordo te ha digerido... Habla con el Chamán Cocoide para volver a intentarlo.")
                        .formatted(Formatting.RED), false);
            }
            current.end();
            return;
        }
        current.step(player);
    }

    private void step(ServerPlayerEntity player) {
        t++;
        if (wonAt >= 0) {
            victoryStep(player);
            return;
        }
        if (t % 20 == 0) {
            for (BlockPos c : cores) {
                world.spawnParticles(ParticleTypes.FALLING_HONEY, c.getX() + 0.5, c.getY() + 1.2, c.getZ() + 0.5, 4, 0.3, 0.2, 0.3, 0);
                world.spawnParticles(ParticleTypes.GLOW, c.getX() + 0.5, c.getY() + 0.5, c.getZ() + 0.5, 3, 0.4, 0.4, 0.4, 0);
            }
        }
        // La grasa del Gordo cobra vida.
        if (t % 220 == 0) {
            for (int i = 0; i < 2; i++) {
                SlimeEntity slime = EntityType.SLIME.create(world);
                if (slime != null) {
                    slime.setSize(2, true);
                    slime.setCustomName(Text.literal("Grasa").formatted(Formatting.YELLOW));
                    slime.refreshPositionAndAngles(player.getX() + (i == 0 ? 3 : -3), player.getY() + 1, player.getZ() + 2, 0, 0);
                    world.spawnEntity(slime);
                }
            }
            world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_SLIME_SQUISH, SoundCategory.HOSTILE, 2f, 0.5f);
        }
        // Jugos gástricos: caen donde estabas; si no te apartas, te queman.
        if (t % 300 == 150) {
            acidAt = player.getBlockPos();
            player.sendMessage(Text.literal("¡JUGOS GÁSTRICOS! ¡Apártate!").formatted(Formatting.GREEN, Formatting.BOLD), true);
        }
        if (acidAt != null && t % 300 > 150 && t % 300 < 190 && t % 4 == 0) {
            world.spawnParticles(ParticleTypes.DRIPPING_DRIPSTONE_LAVA, acidAt.getX() + 0.5, acidAt.getY() + 6, acidAt.getZ() + 0.5, 20, 2, 0.5, 2, 0);
        }
        if (acidAt != null && t % 300 == 190) {
            world.spawnParticles(ParticleTypes.ITEM_SLIME, acidAt.getX() + 0.5, acidAt.getY() + 0.5, acidAt.getZ() + 0.5, 60, 2, 0.3, 2, 0.1);
            if (player.getBlockPos().getSquaredDistance(acidAt) < 9) {
                player.addStatusEffect(new StatusEffectInstance(StatusEffects.POISON, 100, 1));
            }
            acidAt = null;
        }
        if (t % 400 == 0) {
            world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_PLAYER_BURP, SoundCategory.HOSTILE, 3f, 0.3f);
        }
    }

    private void onBreak(ServerPlayerEntity player, BlockPos pos) {
        if (!cores.remove(pos)) {
            return;
        }
        world.spawnParticles(ParticleTypes.EXPLOSION, pos.getX() + 0.5, pos.getY() + 0.5, pos.getZ() + 0.5, 4, 0.5, 0.5, 0.5, 0);
        world.spawnParticles(ParticleTypes.FALLING_HONEY, pos.getX() + 0.5, pos.getY() + 1, pos.getZ() + 0.5, 40, 1, 1, 1, 0);
        world.playSound(null, pos, SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.HOSTILE, 2f, 0.8f);
        world.playSound(null, pos, SoundEvents.ENTITY_RAVAGER_HURT, SoundCategory.HOSTILE, 3f, 0.5f);
        bar.setPercent(cores.size() / (float) CORES.length);
        if (cores.isEmpty()) {
            wonAt = t;
            bar.setPercent(0f);
            player.sendMessage(Text.literal("<Gordo Pañales> ¡NOOOO! ¡MI BARRIGAAAA! ¡Si solo quería aprobar jardinería!")
                    .formatted(Formatting.DARK_RED), false);
            return;
        }
        player.sendMessage(Text.literal("<Gordo Pañales> " + PAIN[(CORES.length - cores.size() - 1) % PAIN.length])
                .formatted(Formatting.DARK_RED), false);
        player.sendMessage(Text.literal("Núcleos restantes: " + cores.size()).formatted(Formatting.YELLOW), true);
    }

    private void victoryStep(ServerPlayerEntity player) {
        int v = t - wonAt;
        if (v % 6 == 0 && v < 80) {
            double x = player.getX() + world.random.nextGaussian() * 6, z = player.getZ() + world.random.nextGaussian() * 6;
            world.spawnParticles(ParticleTypes.EXPLOSION_EMITTER, x, player.getY() + 3, z, 1, 0, 0, 0, 0);
            world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.HOSTILE, 1.5f, 0.6f + world.random.nextFloat() * 0.4f);
        }
        if (v == 10) {
            CocoideRitual.title(player, Text.literal("¡HAS DESTRUIDO AL GORDO!").formatted(Formatting.GOLD, Formatting.BOLD),
                    Text.literal("...desde dentro").formatted(Formatting.YELLOW));
        }
        if (v == 90) {
            ServerWorld can = player.getServer().getWorld(ModDimensions.LATA_COCO);
            if (can != null) {
                BlockPos t2 = CoconutWorld.templeCenter();
                player.teleport(can, t2.getX() - 3.5, t2.getY(), t2.getZ() + 0.5, -90, 0);
                can.spawnParticles(ParticleTypes.HAPPY_VILLAGER, t2.getX(), t2.getY() + 2, t2.getZ(), 80, 6, 2, 6, 0);
                can.playSound(null, t2, SoundEvents.UI_TOAST_CHALLENGE_COMPLETE, SoundCategory.PLAYERS, 2f, 1f);
            }
            TurboState state = TurboState.get(player.getServer());
            state.chapter1Done = true;
            state.markDirty();
            for (ItemStack reward : new ItemStack[]{new ItemStack(ModItems.ESTRELLA_DE_PODER, 3), new ItemStack(ModItems.MANTEQUILLA, 16),
                    new ItemStack(net.minecraft.item.Items.DIAMOND, 5)}) {
                if (!player.giveItemStack(reward)) {
                    player.dropItem(reward, false);
                }
            }
            CocoideRitual.title(player, Text.literal("FIN DEL CAPÍTULO 1").formatted(Formatting.AQUA, Formatting.BOLD),
                    Text.literal("Los Cocoides vuelven a ser libres").formatted(Formatting.WHITE));
            com.turbopapu.network.ModPackets.dialogue(player, "chaman_victoria", 0, -1);
            end();
        }
    }

    private void end() {
        bar.clearPlayers();
        current = null;
    }
}
