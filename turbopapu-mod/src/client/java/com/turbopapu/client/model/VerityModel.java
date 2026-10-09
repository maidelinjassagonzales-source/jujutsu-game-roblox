package com.turbopapu.client.model;

import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.model.*;
import net.minecraft.client.render.entity.model.SinglePartEntityModel;
import net.minecraft.util.math.MathHelper;

/**
 * Verity: una pelota amarilla con cara sonriente. Esta es su versión GORDA: más ancha que alta,
 * hecha con tres bloques cruzados para que parezca redonda. Textura 128x128.
 */
public class VerityModel extends SinglePartEntityModel<PapuNpcEntity> {
    private final ModelPart root;
    private final ModelPart ball;

    public VerityModel(ModelPart root) {
        this.root = root;
        this.ball = root.getChild("ball");
    }

    public static TexturedModelData getTexturedModelData() {
        ModelData data = new ModelData();
        ModelPartData ball = data.getRoot().addChild("ball", ModelPartBuilder.create()
                        // Núcleo vertical (arriba y abajo de la pelota).
                        .uv(0, 0).cuboid(-8, -20, -8, 16, 20, 16)
                        // Anillo central (donde están los ojos).
                        .uv(0, 36).cuboid(-9, -17, -9, 18, 14, 18)
                        // Barriga: la parte más ancha (donde está la sonrisa).
                        .uv(0, 68).cuboid(-10, -11, -10, 20, 8, 20),
                ModelTransform.pivot(0, 24, 0));
        return TexturedModelData.of(data, 128, 128);
    }

    @Override
    public ModelPart getPart() {
        return root;
    }

    @Override
    public void setAngles(PapuNpcEntity entity, float limbAngle, float limbDistance, float animationProgress,
                          float headYaw, float headPitch) {
        // Rebota al moverse y "respira" cuando está quieta.
        float bounce = Math.abs(MathHelper.sin(limbAngle * 0.5f)) * limbDistance * 3f;
        float breathe = MathHelper.sin(animationProgress * 0.1f) * 0.03f;
        ball.pivotY = 24 - bounce;
        ball.yaw = headYaw * MathHelper.RADIANS_PER_DEGREE * 0.5f;
        ball.xScale = 1f + breathe;
        ball.zScale = 1f + breathe;
        ball.yScale = 1f - breathe;
    }
}
