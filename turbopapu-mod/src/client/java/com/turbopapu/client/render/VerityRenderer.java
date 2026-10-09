package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.VerityModel;
import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.MobEntityRenderer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;

public class VerityRenderer extends MobEntityRenderer<PapuNpcEntity, VerityModel> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/verity_gorda.png");
    private static final float SCALE = 1.6f;

    public VerityRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new VerityModel(ctx.getPart(ModModelLayers.VERITY)), 1.2f);
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
