package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.PapuHumanoidModel;
import com.turbopapu.entity.SualenidusEntity;
import net.minecraft.client.render.entity.BipedEntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;

public class SualenidusRenderer extends BipedEntityRenderer<SualenidusEntity, PapuHumanoidModel<SualenidusEntity>> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/sualenidus.png");
    private static final float SCALE = 2.6f;

    public SualenidusRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new PapuHumanoidModel<>(ctx.getPart(ModModelLayers.FAT)), 1.4f);
    }

    @Override
    public Identifier getTexture(SualenidusEntity entity) {
        return TEXTURE;
    }

    @Override
    protected void scale(SualenidusEntity entity, MatrixStack matrices, float amount) {
        float wide = 1f + (entity.getBarriga() - 1f) * 0.35f;
        matrices.scale(SCALE * wide, SCALE, SCALE * wide);
    }
}
