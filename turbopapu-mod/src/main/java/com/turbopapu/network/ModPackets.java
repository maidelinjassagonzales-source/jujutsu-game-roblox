package com.turbopapu.network;

import com.turbopapu.TurboPapuMod;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Identifier;
import com.turbopapu.fight.BossFight;
import com.turbopapu.fight.PvzGame;
import com.turbopapu.fight.PvzPlantType;

/** Paquetes servidor → cliente para las escenas: cinemática, carta, viaje y final. */
public final class ModPackets {
    public static final Identifier CINEMATIC = TurboPapuMod.id("cinematic");
    public static final Identifier OPEN_LETTER = TurboPapuMod.id("open_letter");
    public static final Identifier TRAVEL = TurboPapuMod.id("travel");
    public static final Identifier ENDING = TurboPapuMod.id("ending");
    public static final Identifier DIALOGUE = TurboPapuMod.id("dialogue");
    public static final Identifier FIGHT_STATE = TurboPapuMod.id("fight_state");
    public static final Identifier GLITCH = TurboPapuMod.id("glitch");
    public static final Identifier PVZ_START = TurboPapuMod.id("pvz_start");
    public static final Identifier PVZ_END = TurboPapuMod.id("pvz_end");
    public static final Identifier MUSIC = TurboPapuMod.id("music");
    public static final Identifier LANDING = TurboPapuMod.id("landing");
    // Cliente -> servidor
    public static final Identifier DIALOGUE_ACTION = TurboPapuMod.id("dialogue_action");
    public static final Identifier PVZ_PLACE = TurboPapuMod.id("pvz_place");
    public static final Identifier PVZ_SHOVEL = TurboPapuMod.id("pvz_shovel");
    public static final Identifier PVZ_QUIT = TurboPapuMod.id("pvz_quit");
    public static final Identifier SCREAMER = TurboPapuMod.id("screamer");
    public static final Identifier CAGARSE = TurboPapuMod.id("cagarse");
    public static final Identifier REBOTES = TurboPapuMod.id("rebotes");

    private ModPackets() {}

    public static void register() {
        ServerPlayNetworking.registerGlobalReceiver(DIALOGUE_ACTION, (server, player, handler, buf, sender) -> {
            String action = buf.readString(64);
            server.execute(() -> DialogueActions.handle(player, action));
        });
        ServerPlayNetworking.registerGlobalReceiver(PVZ_PLACE, (server, player, handler, buf, sender) -> {
            int col = buf.readVarInt(), row = buf.readVarInt(), type = buf.readVarInt();
            server.execute(() -> BossFight.pvzPlace(player, col, row, type));
        });
        ServerPlayNetworking.registerGlobalReceiver(PVZ_SHOVEL, (server, player, handler, buf, sender) -> {
            int col = buf.readVarInt(), row = buf.readVarInt();
            server.execute(() -> BossFight.pvzShovel(player, col, row));
        });
        ServerPlayNetworking.registerGlobalReceiver(CAGARSE, (server, player, handler, buf, sender) ->
                server.execute(() -> com.turbopapu.world.GordoEvents.poop(player)));
        ServerPlayNetworking.registerGlobalReceiver(REBOTES, (server, player, handler, buf, sender) ->
                server.execute(() -> com.turbopapu.world.PoopWorld.bouncedTooMuch(player)));
        ServerPlayNetworking.registerGlobalReceiver(PVZ_QUIT, (server, player, handler, buf, sender) ->
                server.execute(() -> com.turbopapu.fight.PvzArcade.quit(player)));
    }

    public static void fightState(ServerPlayerEntity player, BossFight fight) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(fight.phase().ordinal());
        buf.writeVarInt(fight.round());
        buf.writeVarInt(fight.spikeTicks());
        buf.writeVarInt(fight.defuse());
        writePvz(buf, fight.pvz(), false);
        ServerPlayNetworking.send(player, FIGHT_STATE, buf);
    }

    /** Estado del Plantas vs Zombies del modo libre (se dibuja igual que la fase final de la pelea). */
    public static void arcadeState(ServerPlayerEntity player, PvzGame pvz) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(BossFight.Phase.PVZ.ordinal());
        buf.writeVarInt(0);
        buf.writeVarInt(0);
        buf.writeVarInt(0);
        writePvz(buf, pvz, true);
        ServerPlayNetworking.send(player, FIGHT_STATE, buf);
    }

    private static void writePvz(PacketByteBuf buf, PvzGame pvz, boolean arcade) {
        buf.writeBoolean(pvz != null);
        if (pvz != null) {
            buf.writeVarInt(pvz.sun());
            buf.writeVarInt(pvz.wave());
            buf.writeVarInt(pvz.totalWaves());
            buf.writeBoolean(arcade);
            buf.writeVarInt(pvz.waveProgress());
            buf.writeString(pvz.message());
            for (int i = 0; i < PvzPlantType.values().length; i++) {
                buf.writeVarInt(pvz.cooldownPercent(i));
            }
        }
    }

    public static void fightEnded(ServerPlayerEntity player) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(-1);
        ServerPlayNetworking.send(player, FIGHT_STATE, buf);
    }

    public static void glitch(ServerPlayerEntity player) {
        ServerPlayNetworking.send(player, GLITCH, PacketByteBufs.empty());
    }

    public static void pvzStart(ServerPlayerEntity player, int cameraId) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(cameraId);
        ServerPlayNetworking.send(player, PVZ_START, buf);
    }

    public static void screamer(ServerPlayerEntity player) {
        ServerPlayNetworking.send(player, SCREAMER, PacketByteBufs.empty());
    }

    public static void pvzEnd(ServerPlayerEntity player) {
        ServerPlayNetworking.send(player, PVZ_END, PacketByteBufs.empty());
    }

    /** Música de zona ("" = parar). */
    public static void music(ServerPlayerEntity player, String key) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeString(key);
        ServerPlayNetworking.send(player, MUSIC, buf);
    }

    /** Cinemática de aterrizaje del cohete en el planeta. */
    public static void landing(ServerPlayerEntity player, int rocketId, int cameraId) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(rocketId);
        buf.writeVarInt(cameraId);
        ServerPlayNetworking.send(player, LANDING, buf);
    }

    public static void startCinematic(ServerPlayerEntity player, int entityId, int ticks) {
        startCinematic(player, entityId, ticks, "");
    }

    /** Cinemática siguiendo a una entidad, con un texto propio en las bandas negras ("" = el del meteorito). */
    public static void startCinematic(ServerPlayerEntity player, int entityId, int ticks, String caption) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(entityId);
        buf.writeVarInt(ticks);
        buf.writeString(caption);
        ServerPlayNetworking.send(player, CINEMATIC, buf);
    }

    public static void openLetter(ServerPlayerEntity player) {
        ServerPlayNetworking.send(player, OPEN_LETTER, PacketByteBufs.empty());
    }

    public static void showTravel(ServerPlayerEntity player, boolean toPlanet) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeBoolean(toPlanet);
        ServerPlayNetworking.send(player, TRAVEL, buf);
    }

    /** Abre un diálogo de dialogues.json (clave exacta o variante clave_N) mirando a la entidad npcId (-1 = ninguna). */
    public static void dialogue(ServerPlayerEntity player, String key, int variant, int npcId) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeString(key);
        buf.writeVarInt(variant);
        buf.writeVarInt(npcId);
        ServerPlayNetworking.send(player, DIALOGUE, buf);
    }

    public static void showEnding(ServerPlayerEntity player) {
        ServerPlayNetworking.send(player, ENDING, PacketByteBufs.empty());
    }
}
