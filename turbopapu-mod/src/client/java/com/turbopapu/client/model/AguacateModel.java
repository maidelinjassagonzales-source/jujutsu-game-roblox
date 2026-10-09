package com.turbopapu.client.model;

import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.client.render.entity.model.EntityModel;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.MathHelper;

/** Aguacate Cubano: cuerpo de aguacate (más ancho abajo), sombrero de paja, bracitos y piernecitas. */
public class AguacateModel extends EntityModel<PapuNpcEntity> {
    private final ModelPart body;
    private final ModelPart leftLeg, rightLeg, leftArm, rightArm;

    public AguacateModel(ModelPart root) {
        this.body = root.getChild("body");
        this.leftLeg = root.getChild("left_leg");
        this.rightLeg = root.getChild("right_leg");
        this.leftArm = body.getChild("left_arm");
        this.rightArm = body.getChild("right_arm");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData data = new ModelData();
        ModelPartData root = data.getRoot();
        ModelPartData body = root.addChild("body", ModelPartBuilder.create()
                        .uv(0, 0).cuboid(-5, -10, -4.5f, 10, 10, 9)
                        .uv(0, 19).cuboid(-3.5f, -16, -3.5f, 7, 6, 7),
                ModelTransform.pivot(0, 21, 0));
        body.addChild("hat_brim", ModelPartBuilder.create().uv(0, 45).cuboid(-5, -17, -5, 10, 1, 10), ModelTransform.NONE);
        body.addChild("hat_top", ModelPartBuilder.create().uv(38, 0).cuboid(-2.5f, -20, -2.5f, 5, 3, 5), ModelTransform.NONE);
        body.addChild("left_arm", ModelPartBuilder.create().uv(0, 32).cuboid(0, -1, -1, 4, 2, 2), ModelTransform.pivot(5, -6, 0));
        body.addChild("right_arm", ModelPartBuilder.create().uv(0, 32).mirrored().cuboid(-4, -1, -1, 4, 2, 2), ModelTransform.pivot(-5, -6, 0));
        root.addChild("left_leg", ModelPartBuilder.create().uv(12, 32).cuboid(-1, 0, -1, 2, 3, 2), ModelTransform.pivot(2, 21, 0));
        root.addChild("right_leg", ModelPartBuilder.create().uv(12, 32).mirrored().cuboid(-1, 0, -1, 2, 3, 2), ModelTransform.pivot(-2, 21, 0));
        return TexturedModelData.of(data, 64, 64);
    }

    @Override
    public void setAngles(PapuNpcEntity entity, float limbAngle, float limbDistance, float animationProgress, float headYaw, float headPitch) {
        body.yaw = headYaw * MathHelper.RADIANS_PER_DEGREE * 0.5f;
        body.roll = MathHelper.sin(limbAngle * 0.6662f) * 0.12f * limbDistance;
        leftLeg.pitch = MathHelper.cos(limbAngle * 0.6662f) * 1.3f * limbDistance;
        rightLeg.pitch = MathHelper.cos(limbAngle * 0.6662f + MathHelper.PI) * 1.3f * limbDistance;
        // Bailando un poquito de salsa.
        leftArm.roll = -0.4f + MathHelper.sin(animationProgress * 0.2f) * 0.4f;
        rightArm.roll = 0.4f - MathHelper.sin(animationProgress * 0.2f) * 0.4f;
    }

    @Override
    public void render(MatrixStack matrices, VertexConsumer vertices, int light, int overlay, float red, float green, float blue, float alpha) {
        body.render(matrices, vertices, light, overlay, red, green, blue, alpha);
        leftLeg.render(matrices, vertices, light, overlay, red, green, blue, alpha);
        rightLeg.render(matrices, vertices, light, overlay, red, green, blue, alpha);
    }
}
