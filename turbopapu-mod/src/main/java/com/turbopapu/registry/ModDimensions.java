package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.RegistryKeys;
import net.minecraft.world.World;

public final class ModDimensions {
    /** Definida por datapack en data/turbopapu/dimension/planeta_turbopapu.json */
    public static final RegistryKey<World> PLANETA = RegistryKey.of(RegistryKeys.WORLD, TurboPapuMod.id("planeta_turbopapu"));

    private ModDimensions() {}
}
