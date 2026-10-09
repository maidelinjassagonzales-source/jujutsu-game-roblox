package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.world.CraterFeature;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.world.gen.feature.DefaultFeatureConfig;
import net.minecraft.world.gen.feature.Feature;

public final class ModFeatures {
    /** Cráteres lunares (usado en data/turbopapu/worldgen/configured_feature/crater.json). */
    public static final Feature<DefaultFeatureConfig> CRATER = new CraterFeature(DefaultFeatureConfig.CODEC);

    private ModFeatures() {}

    public static void register() {
        Registry.register(Registries.FEATURE, TurboPapuMod.id("crater"), CRATER);
    }
}
