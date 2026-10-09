package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.AroyModel;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.MobEntityRenderer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;

public class AroyRenderer extends MobEntityRenderer<PapuNpcEntity, AroyModel> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/aroy.png");
    private static final float SCALE = 1.3f;

    public AroyRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new AroyModel(ctx.getPart(ModModelLayers.AROY)), 0.6f);
    }

    @Override
    public Identifier getTexture(PapuNpcEntity entity) {
        return TEXTURE;
    }

    @Override
    protected void scale(PapuNpcEntity entity, MatrixStack matrices, float amount) {
        matrices.scale(SCALE, SCALE, SCALE);
    }
}
