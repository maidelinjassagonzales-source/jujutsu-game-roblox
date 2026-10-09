package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.TurboPapuenseModel;
import com.turbopapu.entity.TurboPapuenseEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.MobEntityRenderer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.RotationAxis;

public class TurboPapuenseRenderer extends MobEntityRenderer<TurboPapuenseEntity, TurboPapuenseModel> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/turbopapuense.png");
    private static final Identifier TEXTURE_DORMIDO = TurboPapuMod.id("textures/entity/turbopapuense_dormido.png");

    public TurboPapuenseRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new TurboPapuenseModel(ctx.getPart(ModModelLayers.TURBOPAPUENSE)), 0.5f);
    }

    @Override
    public Identifier getTexture(TurboPapuenseEntity entity) {
        return entity.isDormido() ? TEXTURE_DORMIDO : TEXTURE;
    }

    @Override
    protected void setupTransforms(TurboPapuenseEntity entity, MatrixStack matrices, float animationProgress, float bodyYaw, float tickDelta) {
        super.setupTransforms(entity, matrices, animationProgress, bodyYaw, tickDelta);
        if (entity.isDormido()) {
            // Tumbado de lado, roncando.
            matrices.translate(0.55, 0.4, 0);
            matrices.multiply(RotationAxis.POSITIVE_Z.rotationDegrees(90));
        }
    }
}
