package com.turbopapu.client.model;

import com.turbopapu.entity.SalchichaEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.VertexConsumer;
import net.minecraft.client.render.entity.model.EntityModel;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.math.MathHelper;

/** Una salchicha tumbada con puntas redondeadas y ojitos, que se menea al andar. */
public class SalchichaModel extends EntityModel<SalchichaEntity> {
    private final ModelPart body;

    public SalchichaModel(ModelPart root) {
        this.body = root.getChild("body");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData data = new ModelData();
        ModelPartData body = data.getRoot().addChild("body",
                ModelPartBuilder.create().uv(0, 0).cuboid(-2, -4, -5, 4, 4, 10), ModelTransform.pivot(0, 24, 0));
        body.addChild("tip_front", ModelPartBuilder.create().uv(0, 14).cuboid(-1.5f, -3.5f, -6, 3, 3, 1), ModelTransform.NONE);
        body.addChild("tip_back", ModelPartBuilder.create().uv(8, 14).cuboid(-1.5f, -3.5f, 5, 3, 3, 1), ModelTransform.NONE);
        return TexturedModelData.of(data, 32, 32);
    }

    @Override
    public void setAngles(SalchichaEntity entity, float limbAngle, float limbDistance, float animationProgress, float headYaw, float headPitch) {
        body.yaw = MathHelper.sin(limbAngle * 1.2f) * 0.4f * limbDistance;
        body.roll = MathHelper.sin(animationProgress * 0.15f) * 0.08f;
    }

    @Override
    public void render(MatrixStack matrices, VertexConsumer vertices, int light, int overlay, float red, float green, float blue, float alpha) {
        body.render(matrices, vertices, light, overlay, red, green, blue, alpha);
    }
}
