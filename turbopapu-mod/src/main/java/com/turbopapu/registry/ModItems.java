package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.item.*;
import net.minecraft.entity.EntityType;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.item.BlockItem;
import net.minecraft.item.Item;
import net.minecraft.item.SpawnEggItem;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.util.Rarity;

import java.util.ArrayList;
import java.util.List;

public final class ModItems {
    public static final List<Item> ALL = new ArrayList<>();

    public static final Item FRAGMENTO_METEORITO = register("fragmento_meteorito",
            new BlockItem(ModBlocks.FRAGMENTO_METEORITO, new Item.Settings()));
    public static final Item REGOLITO_PAPU = register("regolito_papu", new BlockItem(ModBlocks.REGOLITO_PAPU, new Item.Settings()));
    public static final Item ROCA_PAPU = register("roca_papu", new BlockItem(ModBlocks.ROCA_PAPU, new Item.Settings()));
    public static final Item ATRAPASUENOS = register("atrapasuenos", new BlockItem(ModBlocks.ATRAPASUENOS, new Item.Settings()));
    public static final Item TOTEM_MUDOKON = register("totem_mudokon", new BlockItem(ModBlocks.TOTEM_MUDOKON, new Item.Settings()));
    public static final Item VASIJA_MUDOKON = register("vasija_mudokon", new BlockItem(ModBlocks.VASIJA_MUDOKON, new Item.Settings()));
    public static final Item LADRILLO_MUDOKON = register("ladrillo_mudokon", new BlockItem(ModBlocks.LADRILLO_MUDOKON, new Item.Settings()));
    public static final Item ARBUSTO_SPOOCE = register("arbusto_spooce", new BlockItem(ModBlocks.ARBUSTO_SPOOCE, new Item.Settings()));

    // --- Piezas del cohete ---
    public static final Item CASCO_COHETE = register("casco_cohete", new TooltipItem(new Item.Settings().maxCount(1), "casco_cohete"));
    public static final Item MOTOR_TURBO = register("motor_turbo", new TooltipItem(new Item.Settings().maxCount(1), "motor_turbo"));
    public static final Item COMBUSTIBLE_PAPU = register("combustible_papu", new TooltipItem(new Item.Settings().maxCount(16), "combustible_papu"));
    public static final Item NUCLEO_ICEBERG = register("nucleo_iceberg", new TooltipItem(new Item.Settings().maxCount(1).rarity(Rarity.RARE), "nucleo_iceberg"));
    public static final Item MAPA_ESTELAR = register("mapa_estelar", new TooltipItem(new Item.Settings().maxCount(1).rarity(Rarity.RARE), "mapa_estelar"));
    public static final Item COHETE = register("cohete", new RocketItem(new Item.Settings().maxCount(1).rarity(Rarity.EPIC)));

    // --- Objetos de la historia ---
    public static final Item CARTA_DE_AUXILIO = register("carta_de_auxilio", new LetterItem(new Item.Settings().maxCount(1).rarity(Rarity.UNCOMMON)));
    public static final Item ICEBERG_DE_BOLSILLO = register("iceberg_de_bolsillo", new PocketIcebergItem(new Item.Settings().maxCount(16).rarity(Rarity.RARE)));
    public static final Item MATE = register("mate", new MateItem(new Item.Settings().maxCount(16)));
    public static final Item VANDAL = register("vandal", new VandalItem(new Item.Settings().maxCount(1).rarity(Rarity.EPIC)));
    public static final Item LECHE_DE_COCO = register("leche_de_coco", new CoconutMilkItem(new Item.Settings().maxCount(16).rarity(Rarity.UNCOMMON)));
    public static final Item SALCHICHA = register("salchicha", new Item(new Item.Settings().food(
            new net.minecraft.item.FoodComponent.Builder().hunger(4).saturationModifier(0.6f).meat().snack().build())));
    public static final Item MANTEQUILLA = register("mantequilla", new com.turbopapu.item.MantequillaItem(new Item.Settings().maxCount(64)));
    public static final Item PANAL = register("panal", new com.turbopapu.item.PanalItem(new Item.Settings().maxCount(1).rarity(Rarity.EPIC)));
    public static final Item AGUACATE = register("aguacate", new Item(new Item.Settings().food(
            new net.minecraft.item.FoodComponent.Builder().hunger(5).saturationModifier(0.7f).build())));
    public static final Item ESTRELLA_DE_PODER = register("estrella_de_poder", new PowerStarItem(new Item.Settings().maxCount(8).rarity(Rarity.EPIC)));

    // --- Huevos de invocación ---
    public static final Item TURBOPAPUENSE_SPAWN_EGG = egg("turbopapuense", ModEntities.TURBOPAPUENSE, 0xF2A33A, 0x4B3FD1);
    public static final Item ALPHATEMP_SPAWN_EGG = egg("alphatemp", ModEntities.ALPHATEMP, 0x9FD8F5, 0x1E3A5F);
    public static final Item ALPHAFATERFUR_SPAWN_EGG = egg("alphafaterfur", ModEntities.ALPHAFATERFUR, 0x5A0E0E, 0x111111);
    public static final Item WILLIAM_PIRATON_SPAWN_EGG = egg("william_piraton", ModEntities.WILLIAM_PIRATON, 0xF08A24, 0x1A1A1A);
    public static final Item JUANMA_SPAWN_EGG = egg("juanma", ModEntities.JUANMA, 0x75AADB, 0xFFFFFF);
    public static final Item GUINXU_SPAWN_EGG = egg("guinxu", ModEntities.GUINXU, 0x6B4423, 0x2E2E2E);
    public static final Item ELINK_64_SPAWN_EGG = egg("elink_64", ModEntities.ELINK_64, 0xE53935, 0x111111);
    public static final Item VERITY_GORDA_SPAWN_EGG = egg("verity_gorda", ModEntities.VERITY_GORDA, 0xFFD60A, 0x111111);
    public static final Item SUALENIDUS_AMIGO_SPAWN_EGG = egg("sualenidus_amigo", ModEntities.SUALENIDUS_AMIGO, 0xB57EDC, 0x77DD77);
    public static final Item AROY_SPAWN_EGG = egg("aroy", ModEntities.AROY, 0x3A1A08, 0xF28C28);
    public static final Item MUDOKON_SPAWN_EGG = egg("mudokon", ModEntities.MUDOKON, 0x6E8C6A, 0xE07A1F);
    public static final Item ABE_SPAWN_EGG = egg("abe", ModEntities.ABE, 0x7FA08A, 0x5A3A1E);
    public static final Item MAGO_LARGUIRUCHO_SPAWN_EGG = egg("mago_larguirucho", ModEntities.MAGO_LARGUIRUCHO, 0x4A1A7A, 0xE8D44D);
    public static final Item GORDO_PANALES_SPAWN_EGG = egg("gordo_panales", ModEntities.GORDO_PANALES, 0xF2C9A0, 0xFFFFFF);
    public static final Item AGUACATE_CUBANO_SPAWN_EGG = egg("aguacate_cubano", ModEntities.AGUACATE_CUBANO, 0x2E4A1E, 0xC8D96A);
    public static final Item SUALENIDUS_SPAWN_EGG = egg("sualenidus", ModEntities.SUALENIDUS, 0xB57EDC, 0xFF4655);

    private ModItems() {}

    private static Item egg(String name, EntityType<? extends MobEntity> type, int primary, int secondary) {
        return register(name + "_spawn_egg", new SpawnEggItem(type, primary, secondary, new Item.Settings()));
    }

    private static Item register(String name, Item item) {
        Registry.register(Registries.ITEM, TurboPapuMod.id(name), item);
        ALL.add(item);
        return item;
    }

    public static void register() {
        // La carga estática de la clase registra todo.
    }
}
