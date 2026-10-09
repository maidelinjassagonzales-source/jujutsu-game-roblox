package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.RegistryKeys;
import net.minecraft.world.World;

public final class ModDimensions {
    /** Definida por datapack en data/turbopapu/dimension/planeta_turbopapu.json */
    public static final RegistryKey<World> PLANETA = RegistryKey.of(RegistryKeys.WORLD, TurboPapuMod.id("planeta_turbopapu"));

    /** El mundo estomacal del Gordo Pañales (data/turbopapu/dimension/estomago_gordo.json). */
    public static final RegistryKey<World> ESTOMAGO = RegistryKey.of(RegistryKeys.WORLD, TurboPapuMod.id("estomago_gordo"));

    /** El Mundo de Caca, donde vive Verity de Caca (se llega rebotando demasiado con el pañal cagado). */
    public static final RegistryKey<World> MUNDO_CACA = RegistryKey.of(RegistryKeys.WORLD, TurboPapuMod.id("mundo_caca"));

    /** El mundo dentro de la lata de leche de coco de Aroy. */
    public static final RegistryKey<World> LATA_COCO = RegistryKey.of(RegistryKeys.WORLD, TurboPapuMod.id("lata_de_coco"));

    private ModDimensions() {}
}
