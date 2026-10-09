package com.turbopapu.client.model;

import com.turbopapu.entity.TurboPapuenseEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.entity.model.SinglePartEntityModel;
import net.minecraft.util.math.MathHelper;

/**
 * Un Turbopapuense: la bola del planeta (cara con ojos y boca), cascos gamer con micro, bracitos y dos patas.
 * Textura 64x64 generada por tools/generate_textures.py
 */
public class TurboPapuenseModel extends SinglePartEntityModel<TurboPapuenseEntity> {
    private final ModelPart root;
    private final ModelPart body;
    private final ModelPart rightLeg;
    private final ModelPart leftLeg;
    private final ModelPart rightArm;
    private final ModelPart leftArm;

    public TurboPapuenseModel(ModelPart root) {
        this.root = root;
        this.body = root.getChild("body");
        this.rightLeg = root.getChild("right_leg");
        this.leftLeg = root.getChild("left_leg");
        this.rightArm = body.getChild("right_arm");
        this.leftArm = body.getChild("left_arm");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData data = new ModelData();
        ModelPartData root = data.getRoot();
        ModelPartData body = root.addChild("body", ModelPartBuilder.create()
                        .uv(0, 0).cuboid(-6, -12, -6, 12, 12, 12),
                ModelTransform.pivot(0, 19, 0));
        // Diadema de los cascos.
        body.addChild("band", ModelPartBuilder.create().uv(0, 34).cuboid(-7, -13, -2, 14, 2, 4), ModelTransform.NONE);
        body.addChild("right_cup", ModelPartBuilder.create().uv(36, 32).cuboid(-8, -9, -2.5f, 2, 5, 5), ModelTransform.NONE);
        body.addChild("left_cup", ModelPartBuilder.create().uv(36, 44).cuboid(6, -9, -2.5f, 2, 5, 5), ModelTransform.NONE);
        body.addChild("mic", ModelPartBuilder.create().uv(50, 32).cuboid(-7.5f, -5, -7, 1, 1, 5), ModelTransform.NONE);
        body.addChild("right_arm", ModelPartBuilder.create().uv(28, 24).cuboid(-3, -1.5f, -1.5f, 3, 3, 3),
                ModelTransform.pivot(-6, -5, 0));
        body.addChild("left_arm", ModelPartBuilder.create().uv(40, 24).cuboid(0, -1.5f, -1.5f, 3, 3, 3),
                ModelTransform.pivot(6, -5, 0));
        root.addChild("right_leg", ModelPartBuilder.create().uv(0, 24).cuboid(-1.5f, 0, -2, 3, 5, 4),
                ModelTransform.pivot(-3, 19, 0));
        root.addChild("left_leg", ModelPartBuilder.create().uv(14, 24).cuboid(-1.5f, 0, -2, 3, 5, 4),
                ModelTransform.pivot(3, 19, 0));
        return TexturedModelData.of(data, 64, 64);
    }

    @Override
    public ModelPart getPart() {
        return root;
    }

    @Override
    public void setAngles(TurboPapuenseEntity entity, float limbAngle, float limbDistance, float animationProgress,
                          float headYaw, float headPitch) {
        body.yaw = headYaw * 0.3f * MathHelper.RADIANS_PER_DEGREE;
        body.pitch = 0;
        float swing = MathHelper.cos(limbAngle * 0.6662f) * 1.4f * limbDistance;
        rightLeg.pitch = swing;
        leftLeg.pitch = -swing;
        rightArm.roll = 0.3f + MathHelper.sin(animationProgress * 0.1f) * 0.1f;
        leftArm.roll = -0.3f - MathHelper.sin(animationProgress * 0.1f) * 0.1f;
        rightArm.pitch = -swing;
        leftArm.pitch = swing;
        // Bota un poquito al andar.
        body.pivotY = 19 - Math.abs(MathHelper.sin(limbAngle * 0.6662f)) * limbDistance * 1.5f;
    }
}
