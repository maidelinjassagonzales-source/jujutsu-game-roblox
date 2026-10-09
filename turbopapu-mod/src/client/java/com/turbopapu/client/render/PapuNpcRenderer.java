package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.PapuHumanoidModel;
import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.render.entity.BipedEntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.render.entity.model.EntityModelLayer;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;

public class PapuNpcRenderer extends BipedEntityRenderer<PapuNpcEntity, PapuHumanoidModel<PapuNpcEntity>> {
    private final float scale;

    public PapuNpcRenderer(EntityRendererFactory.Context ctx, EntityModelLayer layer, float scale) {
        super(ctx, new PapuHumanoidModel<>(ctx.getPart(layer)), 0.5f * scale);
        this.scale = scale;
    }

    @Override
    public Identifier getTexture(PapuNpcEntity entity) {
        return TurboPapuMod.id("textures/entity/" + entity.getProfile().textureName() + ".png");
    }

    @Override
    protected void scale(PapuNpcEntity entity, MatrixStack matrices, float amount) {
        matrices.scale(scale, scale, scale);
    }
}
