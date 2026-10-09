package com.turbopapu.command;

import com.mojang.brigadier.context.CommandContext;
import com.turbopapu.network.ModPackets;
import com.turbopapu.world.MeteorEvent;
import com.turbopapu.world.TurboState;
import com.turbopapu.world.Travel;
import net.fabricmc.fabric.api.command.v2.CommandRegistrationCallback;
import net.minecraft.server.command.CommandManager;
import net.minecraft.server.command.ServerCommandSource;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;

/**
 * Comandos de prueba (nivel OP 2):
 * /turbopapu meteorito | carta | viajar | volver | final | estado
 */
public final class TurboCommands {
    private TurboCommands() {}

    public static void register() {
        CommandRegistrationCallback.EVENT.register((dispatcher, registryAccess, environment) ->
                dispatcher.register(CommandManager.literal("turbopapu")
                        .requires(source -> source.hasPermissionLevel(2))
                        .then(CommandManager.literal("meteorito").executes(ctx -> {
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            TurboState.get(ctx.getSource().getServer()).meteorIncoming = false;
                            MeteorEvent.launch((ServerWorld) player.getWorld(), player);
                            return 1;
                        }))
                        .then(CommandManager.literal("carta").executes(ctx -> {
                            ModPackets.openLetter(ctx.getSource().getPlayerOrThrow());
                            return 1;
                        }))
                        .then(CommandManager.literal("viajar").executes(ctx -> {
                            Travel.toPlanet(ctx.getSource().getPlayerOrThrow());
                            return 1;
                        }))
                        .then(CommandManager.literal("volver").executes(ctx -> {
                            Travel.toOverworld(ctx.getSource().getPlayerOrThrow());
                            return 1;
                        }))
                        .then(CommandManager.literal("final").executes(ctx -> {
                            ModPackets.showEnding(ctx.getSource().getPlayerOrThrow());
                            return 1;
                        }))
                        .then(CommandManager.literal("choza").executes(ctx -> {
                            // Construye la choza de Alphatemp y la aldea Mudokon delante del jugador.
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            TurboState state = TurboState.get(ctx.getSource().getServer());
                            int x = (int) player.getX() + 25, z = (int) player.getZ();
                            com.turbopapu.world.OverworldBuilds.buildAlphatempHut((ServerWorld) player.getWorld(), x, z);
                            state.hutX = x;
                            state.hutZ = z;
                            state.hutBuilt = true;
                            state.markDirty();
                            return 1;
                        }))
                        .then(CommandManager.literal("brujula").executes(ctx -> {
                            // Da la brújula que apunta a la choza de Alphatemp (útil si el meteorito cayó con una versión vieja).
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            TurboState state = TurboState.get(ctx.getSource().getServer());
                            if (!state.meteorFallen) {
                                ctx.getSource().sendError(Text.literal("Todavía no ha caído el meteorito."));
                                return 0;
                            }
                            player.giveItemStack(com.turbopapu.world.Books.hutCompass((ServerWorld) player.getWorld(), state));
                            return 1;
                        }))
                        .then(CommandManager.literal("pvz")
                                .then(CommandManager.argument("nivel", com.mojang.brigadier.arguments.IntegerArgumentType.integer(1, com.turbopapu.fight.PvzGame.MAX_LEVEL))
                                        .executes(ctx -> {
                                            com.turbopapu.fight.PvzArcade.start(ctx.getSource().getPlayerOrThrow(),
                                                    com.mojang.brigadier.arguments.IntegerArgumentType.getInteger(ctx, "nivel"));
                                            return 1;
                                        })))
                        .then(CommandManager.literal("guinxu").executes(ctx -> {
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            com.turbopapu.world.FriendBuilds.buildGuinxuStudio((ServerWorld) player.getWorld(), (int) player.getX() + 15, (int) player.getZ());
                            return 1;
                        }))
                        .then(CommandManager.literal("elink").executes(ctx -> {
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            com.turbopapu.world.FriendBuilds.buildElinkCastle((ServerWorld) player.getWorld(), (int) player.getX() + 20, (int) player.getZ());
                            return 1;
                        }))
                        .then(CommandManager.literal("aldea_amigos").executes(ctx -> {
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            ServerWorld world = (ServerWorld) player.getWorld();
                            com.turbopapu.world.FriendsVillage.build(world, TurboState.get(ctx.getSource().getServer()));
                            player.sendMessage(Text.literal("Aldea de los Amigos en X " + com.turbopapu.world.FriendsVillage.CX
                                    + ", Z " + com.turbopapu.world.FriendsVillage.CZ), false);
                            return 1;
                        }))
                        .then(CommandManager.literal("pelea").executes(ctx -> {
                            // Teletransporta al ring de Sualenidus.
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            TurboState state = TurboState.get(ctx.getSource().getServer());
                            ServerWorld planet = ctx.getSource().getServer().getWorld(com.turbopapu.registry.ModDimensions.PLANETA);
                            if (planet == null) {
                                return 0;
                            }
                            if (!state.lairBuilt) {
                                com.turbopapu.world.PlanetBuilds.buildLair(planet, state);
                            }
                            if (!state.ringBuilt) {
                                state.ringY = com.turbopapu.fight.Arenas.buildRing(planet, com.turbopapu.fight.Arenas.lairFloor(planet));
                                state.ringBuilt = true;
                                state.markDirty();
                            }
                            player.teleport(planet, TurboState.LAIR_X + 0.5, state.ringY, TurboState.LAIR_Z + 2.5, 180, 0);
                            return 1;
                        }))
                        .then(CommandManager.literal("aldea").executes(ctx -> {
                            // Construye una aldea de Turbopapuenses delante del jugador.
                            ServerPlayerEntity player = ctx.getSource().getPlayerOrThrow();
                            com.turbopapu.world.VillageBuilder.build((ServerWorld) player.getWorld(), (int) player.getX() + 40,
                                    (int) player.getZ(), player.getRandom(), false,
                                    TurboState.get(ctx.getSource().getServer()).sualenidusDefeated);
                            return 1;
                        }))
                        .then(CommandManager.literal("estado").executes(TurboCommands::status))));
    }

    private static int status(CommandContext<ServerCommandSource> ctx) {
        TurboState s = TurboState.get(ctx.getSource().getServer());
        ctx.getSource().sendFeedback(() -> Text.literal(
                "Meteorito: " + s.meteorFallen + " (" + s.meteorX + ", " + s.meteorY + ", " + s.meteorZ + ")"
                        + "\nChoza de Alphatemp: " + s.hutX + ", " + s.hutZ + " construida=" + s.hutBuilt
                        + "\nEstudio de Guinxu: " + s.guinxuX + ", " + s.guinxuZ + " construido=" + s.guinxuBuilt
                        + "\nCastillo de elink_64: " + s.elinkX + ", " + s.elinkZ + " construido=" + s.elinkBuilt
                        + "\nWilliam aparecido: " + s.williamSpawned
                        + "\nAldea: " + s.villageBuilt + " | Guarida: " + s.lairBuilt + " (" + TurboState.LAIR_X + ", " + TurboState.LAIR_Z + ")"
                        + "\nSualenidus derrotado: " + s.sualenidusDefeated), false);
        return 1;
    }
}
