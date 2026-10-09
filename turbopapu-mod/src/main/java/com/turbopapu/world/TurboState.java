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
    public boolean williamSpawned;
    public boolean villageBuilt;
    public int villageY;
    public boolean lairBuilt;
    public boolean sualenidusDefeated;
    /** Celdas del mapa del planeta cuyas aldeas aleatorias ya se construyeron (ChunkPos.toLong). */
    public final Set<Long> builtVillages = new HashSet<>();

    /** No se guarda: evita lanzar dos meteoritos a la vez. */
    public transient boolean meteorIncoming;

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
        s.williamSpawned = nbt.getBoolean("WilliamSpawned");
        s.villageBuilt = nbt.getBoolean("VillageBuilt");
        s.villageY = nbt.getInt("VillageY");
        s.lairBuilt = nbt.getBoolean("LairBuilt");
        s.sualenidusDefeated = nbt.getBoolean("SualenidusDefeated");
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
        nbt.putBoolean("WilliamSpawned", williamSpawned);
        nbt.putBoolean("VillageBuilt", villageBuilt);
        nbt.putInt("VillageY", villageY);
        nbt.putBoolean("LairBuilt", lairBuilt);
        nbt.putBoolean("SualenidusDefeated", sualenidusDefeated);
        nbt.putLongArray("BuiltVillages", builtVillages.stream().mapToLong(Long::longValue).toArray());
        return nbt;
    }
}
