package com.turbopapu.client.model;

import com.turbopapu.entity.SualenidusEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.entity.model.BipedEntityModel;
import net.minecraft.entity.mob.MobEntity;
import net.minecraft.util.math.MathHelper;

import java.util.NoSuchElementException;

/**
 * Modelo humanoide con variantes: normal, pelo loco (Guinxu), cabeza de pez con tricornio (William_Piraton)
 * y barriga enorme (Sualenidus). Textura estilo skin de 64x64.
 */
public class PapuHumanoidModel<T extends MobEntity> extends BipedEntityModel<T> {
    private final ModelPart belly;

    public PapuHumanoidModel(ModelPart root) {
        super(root);
        ModelPart b;
        try {
            b = root.getChild("body").getChild("belly");
        } catch (NoSuchElementException e) {
            b = null;
        }
        this.belly = b;
    }

    private static ModelData base() {
        return BipedEntityModel.getModelData(Dilation.NONE, 0f);
    }

    public static TexturedModelData humanoid() {
        return TexturedModelData.of(base(), 64, 64);
    }

    /** Guinxu: melena larga y lisa con raya en medio que le cae por la espalda y por delante de los hombros. */
    public static TexturedModelData guinxu() {
        ModelData data = base();
        ModelPartData head = data.getRoot().getChild("head");
        head.addChild("hair_top", ModelPartBuilder.create().uv(0, 32).cuboid(-4.5f, -8.6f, -4.5f, 9, 2, 9), ModelTransform.NONE);
        head.addChild("hair_back", ModelPartBuilder.create().uv(36, 32).cuboid(-4.5f, -7.5f, 3.6f, 9, 14, 1), ModelTransform.NONE);
        head.addChild("hair_left", ModelPartBuilder.create().uv(0, 43).cuboid(3.6f, -7.5f, -3.5f, 1, 12, 6), ModelTransform.NONE);
        head.addChild("hair_right", ModelPartBuilder.create().uv(0, 43).mirrored().cuboid(-4.6f, -7.5f, -3.5f, 1, 12, 6), ModelTransform.NONE);
        return TexturedModelData.of(data, 64, 64);
    }

    /** William_Piraton: pez naranja con traje, parche y sombrero pirata (tricornio). */
    public static TexturedModelData william() {
        ModelData data = base();
        ModelPartData head = data.getRoot().getChild("head");
        head.addChild("brim", ModelPartBuilder.create().uv(0, 32).cuboid(-5, -9, -5, 10, 1, 10), ModelTransform.NONE);
        head.addChild("crown", ModelPartBuilder.create().uv(40, 32).cuboid(-3, -12, -3, 6, 3, 6), ModelTransform.NONE);
        head.addChild("fin_left", ModelPartBuilder.create().uv(0, 48).cuboid(4, -5, -1, 1, 3, 2), ModelTransform.NONE);
        head.addChild("fin_right", ModelPartBuilder.create().uv(0, 48).cuboid(-5, -5, -1, 1, 3, 2), ModelTransform.NONE);
        head.addChild("lips", ModelPartBuilder.create().uv(0, 54).cuboid(-2, -3, -5, 4, 2, 1), ModelTransform.NONE);
        return TexturedModelData.of(data, 64, 64);
    }

    /** Barriga gigante que no para de crecer. */
    public static TexturedModelData fat() {
        ModelData data = base();
        ModelPartData body = data.getRoot().getChild("body");
        body.addChild("belly", ModelPartBuilder.create().uv(0, 32).cuboid(-5, -4, -6, 10, 8, 6),
                ModelTransform.pivot(0, 8, 0));
        return TexturedModelData.of(data, 64, 64);
    }

    @Override
    public void setAngles(T entity, float limbAngle, float limbDistance, float animationProgress, float headYaw, float headPitch) {
        super.setAngles(entity, limbAngle, limbDistance, animationProgress, headYaw, headPitch);
        if (belly != null) {
            float size = entity instanceof SualenidusEntity boss ? boss.getBarriga() : 1.15f;
            float breathe = 1f + MathHelper.sin(animationProgress * 0.12f) * 0.05f;
            belly.xScale = size * breathe;
            belly.yScale = size * breathe;
            belly.zScale = size * breathe * 1.2f;
        }
    }
}
