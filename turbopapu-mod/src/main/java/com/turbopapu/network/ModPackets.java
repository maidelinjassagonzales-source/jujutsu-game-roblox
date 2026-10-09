package com.turbopapu.network;

import com.turbopapu.TurboPapuMod;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.fabricmc.fabric.api.networking.v1.ServerPlayNetworking;
import net.minecraft.network.PacketByteBuf;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Identifier;

/** Paquetes servidor → cliente para las escenas: cinemática, carta, viaje y final. */
public final class ModPackets {
    public static final Identifier CINEMATIC = TurboPapuMod.id("cinematic");
    public static final Identifier OPEN_LETTER = TurboPapuMod.id("open_letter");
    public static final Identifier TRAVEL = TurboPapuMod.id("travel");
    public static final Identifier ENDING = TurboPapuMod.id("ending");
    public static final Identifier DIALOGUE = TurboPapuMod.id("dialogue");

    private ModPackets() {}

    public static void register() {
    }

    public static void startCinematic(ServerPlayerEntity player, int entityId, int ticks) {
        PacketByteBuf buf = PacketByteBufs.create();
        buf.writeVarInt(entityId);
        buf.writeVarInt(ticks);
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
