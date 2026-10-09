package com.turbopapu.client.model;

import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.entity.model.SinglePartEntityModel;
import net.minecraft.util.math.MathHelper;

/**
 * Aroy: una lata de leche de coco Aroy-D. Cuerpo con la etiqueta, un segundo cuerpo girado 45º para que
 * parezca redonda y dos bordes metálicos. Textura HD 256x512 (declarada 64x128).
 */
public class AroyModel extends SinglePartEntityModel<PapuNpcEntity> {
    private final ModelPart root;
    private final ModelPart can;

    public AroyModel(ModelPart root) {
        this.root = root;
        this.can = root.getChild("can");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData data = new ModelData();
        ModelPartData can = data.getRoot().addChild("can", ModelPartBuilder.create()
                        .uv(0, 0).cuboid(-6, -18, -6, 12, 18, 12)
                        .uv(0, 64).cuboid(-6.5f, -19, -6.5f, 13, 1, 13)
                        .uv(0, 80).cuboid(-6.5f, -1, -6.5f, 13, 1, 13),
                ModelTransform.pivot(0, 24, 0));
        can.addChild("round", ModelPartBuilder.create().uv(0, 32).cuboid(-4.5f, -18, -4.5f, 9, 18, 9),
                ModelTransform.of(0, 0, 0, 0, (float) Math.PI / 4, 0));
        return TexturedModelData.of(data, 64, 128);
    }

    @Override
    public ModelPart getPart() {
        return root;
    }

    @Override
    public void setAngles(PapuNpcEntity entity, float limbAngle, float limbDistance, float animationProgress,
                          float headYaw, float headPitch) {
        // La lata va dando saltitos y se balancea.
        float hop = Math.abs(MathHelper.sin(limbAngle * 0.6f)) * limbDistance * 5f;
        can.pivotY = 24 - hop;
        can.roll = MathHelper.sin(limbAngle * 0.6f) * limbDistance * 0.25f
                + MathHelper.sin(animationProgress * 0.08f) * 0.03f;
        can.yaw = headYaw * MathHelper.RADIANS_PER_DEGREE;
    }
}
