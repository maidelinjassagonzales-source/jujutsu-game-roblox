package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.SalchichaModel;
import com.turbopapu.entity.SalchichaEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.MobEntityRenderer;
import net.minecraft.util.Identifier;

public class SalchichaRenderer extends MobEntityRenderer<SalchichaEntity, SalchichaModel> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/salchicha.png");

    public SalchichaRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new SalchichaModel(ctx.getPart(ModModelLayers.SALCHICHA)), 0.25f);
    }

    @Override
    public Identifier getTexture(SalchichaEntity entity) {
        return TEXTURE;
    }
}
