package com.turbopapu.client;

import com.turbopapu.fight.PvzPlantType;
import com.turbopapu.registry.ModEntities;
import net.minecraft.client.MinecraftClient;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.LivingEntity;

import java.util.EnumMap;
import java.util.Map;

/** Cada "planta" se dibuja con el modelo del amigo correspondiente. */
public final class PlantVisuals {
    private static final Map<PvzPlantType, LivingEntity> DUMMIES = new EnumMap<>(PvzPlantType.class);
    private static Object dummyWorld;

    private PlantVisuals() {}

    public static EntityType<? extends LivingEntity> typeFor(PvzPlantType type) {
        return switch (type) {
            case TURBOPAPUENSE -> ModEntities.TURBOPAPUENSE;
            case ALPHATEMP -> ModEntities.ALPHATEMP;
            case GUINXU -> ModEntities.GUINXU;
            case MUDOKON -> ModEntities.MUDOKON;
            case AROY -> ModEntities.AROY;
            case JUANMA -> ModEntities.JUANMA;
            case ELINK_64 -> ModEntities.ELINK_64;
            case VERITY_GORDA -> ModEntities.VERITY_GORDA;
        };
    }

    /** Entidad de mentira (solo para dibujar) del amigo de esa planta. */
    public static LivingEntity dummy(PvzPlantType type) {
        MinecraftClient client = MinecraftClient.getInstance();
        if (client.world == null) {
            return null;
        }
        if (dummyWorld != client.world) {
            DUMMIES.clear();
            dummyWorld = client.world;
        }
        return DUMMIES.computeIfAbsent(type, t -> {
            LivingEntity e = typeFor(t).create(client.world);
            if (e != null) {
                e.setCustomNameVisible(false);
            }
            return e;
        });
    }
}
