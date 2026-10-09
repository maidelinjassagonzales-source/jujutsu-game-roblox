package com.turbopapu.client.render;

import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.PapuHumanoidModel;
import com.turbopapu.entity.SualemMiniEntity;
import net.minecraft.client.render.entity.BipedEntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.util.Identifier;

/** Los zombies del modo libre: aspecto de zombie normal de Minecraft. */
public class PvzZombieRenderer extends BipedEntityRenderer<SualemMiniEntity, PapuHumanoidModel<SualemMiniEntity>> {
    private static final Identifier TEXTURE = new Identifier("minecraft", "textures/entity/zombie/zombie.png");

    public PvzZombieRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, new PapuHumanoidModel<>(ctx.getPart(ModModelLayers.HUMANOID)), 0.5f);
    }

    @Override
    public Identifier getTexture(SualemMiniEntity entity) {
        return TEXTURE;
    }
}
