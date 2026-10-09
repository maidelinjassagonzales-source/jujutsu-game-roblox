package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.entity.*;
import net.fabricmc.fabric.api.object.builder.v1.entity.FabricEntityTypeBuilder;
import net.minecraft.entity.EntityDimensions;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.SpawnGroup;
import net.minecraft.entity.SpawnRestriction;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.world.Heightmap;

public final class ModEntities {
    public static final EntityType<TurboPapuenseEntity> TURBOPAPUENSE = register("turbopapuense",
            FabricEntityTypeBuilder.<TurboPapuenseEntity>createMob()
                    .spawnGroup(SpawnGroup.CREATURE)
                    .entityFactory(TurboPapuenseEntity::new)
                    .dimensions(EntityDimensions.fixed(0.8f, 1.15f))
                    .defaultAttributes(TurboPapuenseEntity::createAttributes)
                    .spawnRestriction(SpawnRestriction.Location.ON_GROUND,
                            Heightmap.Type.MOTION_BLOCKING_NO_LEAVES, MobEntity::canMobSpawn)
                    .build());

    public static final EntityType<PapuNpcEntity> ALPHATEMP = npc("alphatemp", 0.6f, 1.95f);
    public static final EntityType<PapuNpcEntity> ALPHAFATERFUR = npc("alphafaterfur", 0.6f, 1.95f);
    public static final EntityType<PapuNpcEntity> WILLIAM_PIRATON = npc("william_piraton", 0.6f, 2.1f);
    public static final EntityType<PapuNpcEntity> JUANMA = npc("juanma", 0.6f, 1.95f);
    public static final EntityType<PapuNpcEntity> GUINXU = npc("guinxu", 0.6f, 2.2f);
    public static final EntityType<PapuNpcEntity> ELINK_64 = npc("elink_64", 0.6f, 1.95f);
    public static final EntityType<PapuNpcEntity> MUDOKON = npc("mudokon", 0.6f, 2.0f);
    public static final EntityType<PapuNpcEntity> ABE = npc("abe", 0.6f, 2.1f);
    public static final EntityType<PapuNpcEntity> VERITY_GORDA = npc("verity_gorda", 1.9f, 2.0f);

    public static final EntityType<SualenidusEntity> SUALENIDUS = register("sualenidus",
            FabricEntityTypeBuilder.<SualenidusEntity>createMob()
                    .spawnGroup(SpawnGroup.MONSTER)
                    .entityFactory(SualenidusEntity::new)
                    .dimensions(EntityDimensions.fixed(2.4f, 5.0f))
                    .defaultAttributes(SualenidusEntity::createAttributes)
                    .fireImmune()
                    .trackRangeBlocks(128)
                    .build());

    public static final EntityType<MeteorEntity> METEOR = register("meteorito",
            FabricEntityTypeBuilder.<MeteorEntity>create(SpawnGroup.MISC, MeteorEntity::new)
                    .dimensions(EntityDimensions.fixed(4.0f, 4.0f))
                    .trackRangeBlocks(320)
                    .trackedUpdateRate(1)
                    .fireImmune()
                    .build());

    public static final EntityType<RocketEntity> ROCKET = register("cohete",
            FabricEntityTypeBuilder.<RocketEntity>create(SpawnGroup.MISC, RocketEntity::new)
                    .dimensions(EntityDimensions.fixed(1.5f, 4.5f))
                    .trackRangeBlocks(256)
                    .trackedUpdateRate(1)
                    .fireImmune()
                    .build());

    private ModEntities() {}

    private static EntityType<PapuNpcEntity> npc(String name, float width, float height) {
        return register(name, FabricEntityTypeBuilder.<PapuNpcEntity>createMob()
                .spawnGroup(SpawnGroup.MISC)
                .entityFactory(PapuNpcEntity::new)
                .dimensions(EntityDimensions.fixed(width, height))
                .defaultAttributes(PapuNpcEntity::createAttributes)
                .build());
    }

    private static <T extends net.minecraft.entity.Entity> EntityType<T> register(String name, EntityType<T> type) {
        return Registry.register(Registries.ENTITY_TYPE, TurboPapuMod.id(name), type);
    }

    public static void register() {
        NpcProfile.bind(ALPHATEMP, NpcProfile.ALPHATEMP);
        NpcProfile.bind(ALPHAFATERFUR, NpcProfile.ALPHAFATERFUR);
        NpcProfile.bind(WILLIAM_PIRATON, NpcProfile.WILLIAM_PIRATON);
        NpcProfile.bind(JUANMA, NpcProfile.JUANMA);
        NpcProfile.bind(GUINXU, NpcProfile.GUINXU);
        NpcProfile.bind(ELINK_64, NpcProfile.ELINK_64);
        NpcProfile.bind(VERITY_GORDA, NpcProfile.VERITY_GORDA);
        NpcProfile.bind(MUDOKON, NpcProfile.MUDOKON);
        NpcProfile.bind(ABE, NpcProfile.ABE);
    }
}
