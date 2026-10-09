package com.turbopapu.client.model;

import com.turbopapu.TurboPapuMod;
import net.minecraft.client.render.entity.model.EntityModelLayer;

public final class ModModelLayers {
    public static final EntityModelLayer TURBOPAPUENSE = layer("turbopapuense");
    public static final EntityModelLayer HUMANOID = layer("humanoid");
    public static final EntityModelLayer GUINXU = layer("guinxu");
    public static final EntityModelLayer WILLIAM = layer("william_piraton");
    public static final EntityModelLayer FAT = layer("fat");
    public static final EntityModelLayer AROY = layer("aroy");
    public static final EntityModelLayer VERITY = layer("verity_gorda");
    public static final EntityModelLayer MAGO = layer("mago_larguirucho");
    public static final EntityModelLayer SALCHICHA = layer("salchicha");
    public static final EntityModelLayer AGUACATE = layer("aguacate_cubano");

    private ModModelLayers() {}

    private static EntityModelLayer layer(String name) {
        return new EntityModelLayer(TurboPapuMod.id(name), "main");
    }
}
