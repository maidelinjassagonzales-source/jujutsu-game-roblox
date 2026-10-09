package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.AguacateModel;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.MobEntityRenderer;
import net.minecraft.util.Identifier;

public class AguacateRenderer extends MobEntityRenderer<PapuNpcEntity, AguacateModel> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/aguacate_cubano.png");

    public AguacateRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new AguacateModel(ctx.getPart(ModModelLayers.AGUACATE)), 0.4f);
    }

    @Override
    public Identifier getTexture(PapuNpcEntity entity) {
        return TEXTURE;
    }
}
