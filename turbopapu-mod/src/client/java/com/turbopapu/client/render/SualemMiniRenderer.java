package com.turbopapu.client.render;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.PapuHumanoidModel;
import com.turbopapu.entity.SualemMiniEntity;
import net.minecraft.client.render.entity.BipedEntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;

/** Los Sualems "zombies": mismo aspecto que Sualenidus pero tamaño normal. */
public class SualemMiniRenderer extends BipedEntityRenderer<SualemMiniEntity, PapuHumanoidModel<SualemMiniEntity>> {
    private static final Identifier TEXTURE = TurboPapuMod.id("textures/entity/sualenidus.png");

    public SualemMiniRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new PapuHumanoidModel<>(ctx.getPart(ModModelLayers.FAT)), 0.5f);
    }

    @Override
    public Identifier getTexture(SualemMiniEntity entity) {
        return TEXTURE;
    }

    @Override
    protected void scale(SualemMiniEntity entity, MatrixStack matrices, float amount) {
        matrices.scale(0.85f, 0.85f, 0.85f);
    }
}
