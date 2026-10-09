package com.turbopapu.fight;

import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModDimensions;
import com.turbopapu.registry.ModItems;
import com.turbopapu.world.TurboState;
import net.minecraft.entity.decoration.ArmorStandEntity;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.item.ItemStack;
import net.minecraft.registry.RegistryKey;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.world.World;

import java.util.UUID;

/**
 * Modo libre del Plantas vs Zombies, desbloqueado al vencer a Sualenidus. Niveles 1..5 con zombies normales;
 * cada nivel superado desbloquea el siguiente. Al terminar vuelves a donde estabas.
 */
public final class PvzArcade {
    private static PvzArcade current;

    private final ServerWorld world;
    private final UUID playerId;
    private final PvzGame game;
    private final ArmorStandEntity camera;
    private final RegistryKey<World> returnDim;
    private final double returnX, returnY, returnZ;
    private final float returnYaw;

    private PvzArcade(ServerWorld world, ServerPlayerEntity player, int level) {
        this.world = world;
        this.playerId = player.getUuid();
        this.returnDim = player.getWorld().getRegistryKey();
        this.returnX = player.getX();
        this.returnY = player.getY();
        this.returnZ = player.getZ();
        this.returnYaw = player.getYaw();
        this.game = new PvzGame(world, null, level, true);
        player.teleport(world, Arenas.LAWN_X - 2.5, Arenas.LAWN_Y, Arenas.rowZ(2), -90, 0);
        player.addStatusEffect(new StatusEffectInstance(StatusEffects.RESISTANCE, 20 * 60 * 30, 4, false, false));
        this.camera = PvzGame.spawnCamera(world);
    }

    public static boolean isActive() {
        return current != null;
    }

    public static boolean unlocked(ServerPlayerEntity player, int level) {
        return level <= 1 || player.getCommandTags().contains("turbopapu_pvz_" + (level - 1));
    }

    /** Empieza un nivel (lo llaman el diálogo de Sualenidus reformado y /turbopapu pvz). */
    public static void start(ServerPlayerEntity player, int level) {
        MinecraftServer server = player.getServer();
        ServerWorld planet = server == null ? null : server.getWorld(ModDimensions.PLANETA);
        TurboState state = server == null ? null : TurboState.get(server);
        if (planet == null || state == null) {
            return;
        }
        if (!state.sualenidusDefeated) {
            player.sendMessage(Text.literal("Primero tienes que vencer a Sualenidus.").formatted(Formatting.RED), false);
            return;
        }
        level = Math.max(1, Math.min(PvzGame.MAX_LEVEL, level));
        if (!unlocked(player, level)) {
            player.sendMessage(Text.literal("Primero supera el nivel " + (level - 1) + ".").formatted(Formatting.RED), false);
            return;
        }
        if (current != null || BossFight.current() != null) {
            player.sendMessage(Text.literal("Ya hay una partida en marcha.").formatted(Formatting.RED), false);
            return;
        }
        if (!state.lawnBuilt) {
            Arenas.buildLawn(planet);
            state.lawnBuilt = true;
            state.markDirty();
        }
        current = new PvzArcade(planet, player, level);
        current.game.start();
        ModPackets.pvzStart(player, current.camera.getId());
    }

    public static void tick(MinecraftServer server) {
        if (current == null) {
            return;
        }
        ServerPlayerEntity player = current.player();
        if (player == null || !player.isAlive()) {
            current.end(player);
            return;
        }
        current.game.tick();
        if (current != null && current.world.getTime() % 4 == 0) {
            ModPackets.arcadeState(player, current.game);
        }
    }

    public static void place(ServerPlayerEntity player, int col, int row, int type) {
        if (current != null && current.playerId.equals(player.getUuid())) {
            current.game.place(player, col, row, type);
        }
    }

    public static void shovel(ServerPlayerEntity player, int col, int row) {
        if (current != null && current.playerId.equals(player.getUuid())) {
            current.game.shovel(col, row);
        }
    }

    public static void quit(ServerPlayerEntity player) {
        if (current != null && current.playerId.equals(player.getUuid())) {
            player.sendMessage(Text.literal("Has salido del Plantas vs Zombies.").formatted(Formatting.GRAY), false);
            current.end(player);
        }
    }

    static void won(PvzGame game) {
        if (current == null || current.game != game) {
            return;
        }
        ServerPlayerEntity player = current.player();
        if (player != null) {
            int level = game.level;
            player.addCommandTag("turbopapu_pvz_" + level);
            player.networkHandler.sendPacket(new net.minecraft.network.packet.s2c.play.TitleS2CPacket(
                    Text.literal("¡NIVEL " + level + " SUPERADO!").formatted(Formatting.GREEN, Formatting.BOLD)));
            player.networkHandler.sendPacket(new net.minecraft.network.packet.s2c.play.SubtitleS2CPacket(
                    Text.literal(level < PvzGame.MAX_LEVEL ? "Desbloqueado el nivel " + (level + 1) : "¡Has completado todos los niveles!")
                            .formatted(Formatting.YELLOW)));
            player.giveItemStack(new ItemStack(ModItems.SALCHICHA, 2 + level));
            if (level == PvzGame.MAX_LEVEL) {
                player.giveItemStack(new ItemStack(ModItems.ESTRELLA_DE_PODER));
            }
            current.world.playSound(null, player.getBlockPos(), SoundEvents.UI_TOAST_CHALLENGE_COMPLETE, SoundCategory.PLAYERS, 1f, 1f);
        }
        current.end(player);
    }

    static void lost(PvzGame game) {
        if (current == null || current.game != game) {
            return;
        }
        ServerPlayerEntity player = current.player();
        if (player != null) {
            player.sendMessage(Text.literal("¡Los zombies se comieron tus cerebros! Habla con Sualenidus para reintentarlo.")
                    .formatted(Formatting.RED), false);
            current.world.playSound(null, player.getBlockPos(), SoundEvents.ENTITY_ZOMBIE_AMBIENT, SoundCategory.HOSTILE, 2f, 0.6f);
        }
        current.end(player);
    }

    private ServerPlayerEntity player() {
        return world.getServer().getPlayerManager().getPlayer(playerId);
    }

    private void end(ServerPlayerEntity player) {
        current = null;
        game.clear();
        camera.discard();
        if (player == null) {
            return;
        }
        ModPackets.pvzEnd(player);
        ModPackets.fightEnded(player);
        player.removeStatusEffect(StatusEffects.RESISTANCE);
        ServerWorld back = world.getServer().getWorld(returnDim);
        if (back != null && player.isAlive()) {
            player.teleport(back, returnX, returnY, returnZ, returnYaw, 0);
        }
    }
}
