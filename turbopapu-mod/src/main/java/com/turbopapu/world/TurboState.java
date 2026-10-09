package com.turbopapu.world;

import net.minecraft.nbt.NbtCompound;
import java.util.HashSet;
import java.util.Set;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.PersistentState;
import net.minecraft.world.World;

/** Progreso de la historia, guardado en el mundo (data/turbopapu.dat). */
public class TurboState extends PersistentState {
    /** Coordenadas de la guarida de Sualenidus en el planeta (al noreste de la aldea). */
    public static final int LAIR_X = 360;
    public static final int LAIR_Z = -300;

    public boolean meteorFallen;
    public int meteorX, meteorY, meteorZ;
    public int hutX, hutZ;
    public boolean hutBuilt;
    public int guinxuX, guinxuZ, elinkX, elinkZ;
    public boolean guinxuBuilt, elinkBuilt;
    public boolean williamSpawned;
    public boolean magoSpawned;
    public boolean villageBuilt;
    public int villageY;
    public boolean lairBuilt;
    public boolean sualenidusDefeated;
    public boolean ringBuilt, valorantBuilt, lawnBuilt, friendsVillageBuilt, landedOnce;
    public int ringY;
    /** Celdas del mapa del planeta cuyas aldeas aleatorias ya se construyeron (ChunkPos.toLong). */
    public final Set<Long> builtVillages = new HashSet<>();

    /** No se guarda: evita lanzar dos meteoritos a la vez. */
    public transient boolean meteorIncoming;

    /** Casa de Guinxu (~160 bloques al oeste del meteorito) y castillo de elink_64 (~170 al sur). */
    public void placeFriends() {
        guinxuX = meteorX - 160;
        guinxuZ = meteorZ + 50;
        elinkX = meteorX + 40;
        elinkZ = meteorZ + 170;
    }

    public static TurboState get(MinecraftServer server) {
        return server.getWorld(World.OVERWORLD).getPersistentStateManager()
                .getOrCreate(TurboState::fromNbt, TurboState::new, "turbopapu");
    }

    public static TurboState fromNbt(NbtCompound nbt) {
        TurboState s = new TurboState();
        s.meteorFallen = nbt.getBoolean("MeteorFallen");
        s.meteorX = nbt.getInt("MeteorX");
        s.meteorY = nbt.getInt("MeteorY");
        s.meteorZ = nbt.getInt("MeteorZ");
        s.hutX = nbt.getInt("HutX");
        s.hutZ = nbt.getInt("HutZ");
        s.hutBuilt = nbt.getBoolean("HutBuilt");
        s.guinxuX = nbt.getInt("GuinxuX");
        s.guinxuZ = nbt.getInt("GuinxuZ");
        s.elinkX = nbt.getInt("ElinkX");
        s.elinkZ = nbt.getInt("ElinkZ");
        s.guinxuBuilt = nbt.getBoolean("GuinxuBuilt");
        s.elinkBuilt = nbt.getBoolean("ElinkBuilt");
        if (s.meteorFallen && s.guinxuX == 0 && s.guinxuZ == 0) {
            // Mundos donde el meteorito cayó con una versión anterior del mod.
            s.placeFriends();
        }
        s.williamSpawned = nbt.getBoolean("WilliamSpawned");
        s.magoSpawned = nbt.getBoolean("MagoSpawned");
        s.villageBuilt = nbt.getBoolean("VillageBuilt");
        s.villageY = nbt.getInt("VillageY");
        s.lairBuilt = nbt.getBoolean("LairBuilt");
        s.sualenidusDefeated = nbt.getBoolean("SualenidusDefeated");
        s.ringBuilt = nbt.getBoolean("RingBuilt");
        s.valorantBuilt = nbt.getBoolean("ValorantBuilt");
        s.lawnBuilt = nbt.getBoolean("LawnBuilt");
        s.friendsVillageBuilt = nbt.getBoolean("FriendsVillageBuilt");
        s.landedOnce = nbt.getBoolean("LandedOnce");
        s.ringY = nbt.getInt("RingY");
        for (long cell : nbt.getLongArray("BuiltVillages")) {
            s.builtVillages.add(cell);
        }
        return s;
    }

    @Override
    public NbtCompound writeNbt(NbtCompound nbt) {
        nbt.putBoolean("MeteorFallen", meteorFallen);
        nbt.putInt("MeteorX", meteorX);
        nbt.putInt("MeteorY", meteorY);
        nbt.putInt("MeteorZ", meteorZ);
        nbt.putInt("HutX", hutX);
        nbt.putInt("HutZ", hutZ);
        nbt.putBoolean("HutBuilt", hutBuilt);
        nbt.putInt("GuinxuX", guinxuX);
        nbt.putInt("GuinxuZ", guinxuZ);
        nbt.putInt("ElinkX", elinkX);
        nbt.putInt("ElinkZ", elinkZ);
        nbt.putBoolean("GuinxuBuilt", guinxuBuilt);
        nbt.putBoolean("ElinkBuilt", elinkBuilt);
        nbt.putBoolean("WilliamSpawned", williamSpawned);
        nbt.putBoolean("MagoSpawned", magoSpawned);
        nbt.putBoolean("VillageBuilt", villageBuilt);
        nbt.putInt("VillageY", villageY);
        nbt.putBoolean("LairBuilt", lairBuilt);
        nbt.putBoolean("SualenidusDefeated", sualenidusDefeated);
        nbt.putBoolean("RingBuilt", ringBuilt);
        nbt.putBoolean("ValorantBuilt", valorantBuilt);
        nbt.putBoolean("LawnBuilt", lawnBuilt);
        nbt.putBoolean("FriendsVillageBuilt", friendsVillageBuilt);
        nbt.putBoolean("LandedOnce", landedOnce);
        nbt.putInt("RingY", ringY);
        nbt.putLongArray("BuiltVillages", builtVillages.stream().mapToLong(Long::longValue).toArray());
        return nbt;
    }
}
