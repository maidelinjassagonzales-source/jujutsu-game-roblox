package com.turbopapu.client.render;

import com.turbopapu.client.PlantVisuals;
import com.turbopapu.entity.PvzPlantEntity;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.entity.EntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.texture.SpriteAtlasTexture;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.entity.LivingEntity;
import net.minecraft.util.Identifier;

/** Dibuja la planta con el modelo del amigo (un poco más pequeño), mirando hacia los Sualems. */
public class PvzPlantRenderer extends EntityRenderer<PvzPlantEntity> {
    public PvzPlantRenderer(EntityRendererFactory.Context ctx) {
        super(ctx);
        this.shadowRadius = 0.4f;
    }

    @Override
    public void render(PvzPlantEntity entity, float yaw, float tickDelta, MatrixStack matrices, VertexConsumerProvider vertices, int light) {
        LivingEntity dummy = PlantVisuals.dummy(entity.getPlantType());
        if (dummy == null) {
            return;
        }
        dummy.age = entity.age;
        dummy.setYaw(entity.getYaw());
        dummy.prevYaw = entity.getYaw();
        dummy.bodyYaw = entity.getYaw();
        dummy.prevBodyYaw = entity.getYaw();
        dummy.headYaw = entity.getYaw();
        dummy.prevHeadYaw = entity.getYaw();
        float scale = dummy.getHeight() > 1.6f ? 0.6f : 0.8f;
        matrices.push();
        matrices.scale(scale, scale, scale);
        MinecraftClient.getInstance().getEntityRenderDispatcher()
                .render(dummy, 0, 0, 0, entity.getYaw(), tickDelta, matrices, vertices, light);
        matrices.pop();
    }

    @Override
    public Identifier getTexture(PvzPlantEntity entity) {
        return SpriteAtlasTexture.BLOCK_ATLAS_TEXTURE;
    }
}
