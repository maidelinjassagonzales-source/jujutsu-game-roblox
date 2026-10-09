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
    public static final EntityType<PapuNpcEntity> SUALENIDUS_AMIGO = npc("sualenidus_amigo", 1.4f, 2.8f);
    public static final EntityType<PapuNpcEntity> AROY = npc("aroy", 1.1f, 1.6f);
    public static final EntityType<PapuNpcEntity> MUDOKON = npc("mudokon", 0.6f, 2.0f);
    public static final EntityType<PapuNpcEntity> ABE = npc("abe", 0.6f, 2.1f);
    public static final EntityType<PapuNpcEntity> VERITY_GORDA = npc("verity_gorda", 1.9f, 2.0f);
    public static final EntityType<PapuNpcEntity> MAGO_LARGUIRUCHO = npc("mago_larguirucho", 0.5f, 2.7f);
    public static final EntityType<PapuNpcEntity> GORDO_PANALES = npc("gordo_panales", 1.3f, 2.6f);
    public static final EntityType<PapuNpcEntity> AGUACATE_CUBANO = npc("aguacate_cubano", 0.7f, 1.3f);
    public static final EntityType<PapuNpcEntity> VERITY_CACA = npc("verity_caca", 1.9f, 2.0f);
    public static final EntityType<PapuNpcEntity> GORDO_RUBIO = npc("gordo_rubio", 1.2f, 2.4f);
    public static final EntityType<PapuNpcEntity> COCOIDE = npc("cocoide", 0.7f, 1.3f);
    public static final EntityType<PapuNpcEntity> CHAMAN_COCOIDE = npc("chaman_cocoide", 0.7f, 1.4f);
    /** El Gordo Pañales gigante de la cinemática del ritual. */
    public static final EntityType<PapuNpcEntity> GORDO_JEFE = register("gordo_jefe",
            FabricEntityTypeBuilder.<PapuNpcEntity>createMob()
                    .spawnGroup(SpawnGroup.MISC)
                    .entityFactory(PapuNpcEntity::new)
                    .dimensions(EntityDimensions.fixed(6f, 12f))
                    .defaultAttributes(PapuNpcEntity::createAttributes)
                    .trackRangeBlocks(256)
                    .build());

    public static final EntityType<SalchichaEntity> SALCHICHA = register("salchicha",
            FabricEntityTypeBuilder.<SalchichaEntity>createMob()
                    .spawnGroup(SpawnGroup.MISC)
                    .entityFactory(SalchichaEntity::new)
                    .dimensions(EntityDimensions.fixed(0.5f, 0.35f))
                    .defaultAttributes(SalchichaEntity::createAttributes)
                    .build());

    public static final EntityType<SualenidusEntity> SUALENIDUS = register("sualenidus",
            FabricEntityTypeBuilder.<SualenidusEntity>createMob()
                    .spawnGroup(SpawnGroup.MONSTER)
                    .entityFactory(SualenidusEntity::new)
                    .dimensions(EntityDimensions.fixed(2.4f, 5.0f))
                    .defaultAttributes(SualenidusEntity::createAttributes)
                    .fireImmune()
                    .trackRangeBlocks(128)
                    .build());

    public static final EntityType<SualemMiniEntity> SUALEM_MINI = register("sualem_mini",
            FabricEntityTypeBuilder.<SualemMiniEntity>createMob()
                    .spawnGroup(SpawnGroup.MISC)
                    .entityFactory(SualemMiniEntity::new)
                    .dimensions(EntityDimensions.fixed(0.7f, 1.8f))
                    .defaultAttributes(SualemMiniEntity::createAttributes)
                    .build());

    /** Zombies normales del Plantas vs Zombies del modo libre (misma lógica que los Sualems). */
    public static final EntityType<SualemMiniEntity> ZOMBI_PVZ = register("zombi_pvz",
            FabricEntityTypeBuilder.<SualemMiniEntity>createMob()
                    .spawnGroup(SpawnGroup.MISC)
                    .entityFactory(SualemMiniEntity::new)
                    .dimensions(EntityDimensions.fixed(0.6f, 1.95f))
                    .defaultAttributes(SualemMiniEntity::createAttributes)
                    .build());

    public static final EntityType<PvzPlantEntity> PVZ_PLANT = register("pvz_planta",
            FabricEntityTypeBuilder.<PvzPlantEntity>createMob()
                    .spawnGroup(SpawnGroup.MISC)
                    .entityFactory(PvzPlantEntity::new)
                    .dimensions(EntityDimensions.fixed(0.9f, 1.3f))
                    .defaultAttributes(PvzPlantEntity::createAttributes)
                    .build());

    public static final EntityType<PvzProjectileEntity> PVZ_PROJECTILE = register("pvz_proyectil",
            FabricEntityTypeBuilder.<PvzProjectileEntity>create(SpawnGroup.MISC, PvzProjectileEntity::new)
                    .dimensions(EntityDimensions.fixed(0.4f, 0.4f))
                    .trackRangeBlocks(96)
                    .trackedUpdateRate(2)
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
        NpcProfile.bind(AROY, NpcProfile.AROY);
        NpcProfile.bind(SUALENIDUS_AMIGO, NpcProfile.SUALENIDUS_AMIGO);
        NpcProfile.bind(ABE, NpcProfile.ABE);
        NpcProfile.bind(MAGO_LARGUIRUCHO, NpcProfile.MAGO_LARGUIRUCHO);
        NpcProfile.bind(GORDO_PANALES, NpcProfile.GORDO_PANALES);
        NpcProfile.bind(AGUACATE_CUBANO, NpcProfile.AGUACATE_CUBANO);
        NpcProfile.bind(VERITY_CACA, NpcProfile.VERITY_CACA);
        NpcProfile.bind(GORDO_RUBIO, NpcProfile.GORDO_RUBIO);
        NpcProfile.bind(COCOIDE, NpcProfile.COCOIDE);
        NpcProfile.bind(CHAMAN_COCOIDE, NpcProfile.CHAMAN_COCOIDE);
        NpcProfile.bind(GORDO_JEFE, NpcProfile.GORDO_JEFE);
    }
}
