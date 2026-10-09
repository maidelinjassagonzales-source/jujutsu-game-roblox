package com.turbopapu.client.render;

import com.turbopapu.entity.MeteorEntity;
import com.turbopapu.registry.ModBlocks;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.client.render.LightmapTextureManager;
import net.minecraft.client.render.OverlayTexture;
import net.minecraft.client.render.VertexConsumerProvider;
import net.minecraft.client.render.block.BlockRenderManager;
import net.minecraft.client.render.entity.EntityRenderer;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.texture.SpriteAtlasTexture;
import net.minecraft.client.util.math.MatrixStack;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.RotationAxis;

/** El meteorito: una roca gigante girando, envuelta en magma. */
public class MeteorRenderer extends EntityRenderer<MeteorEntity> {
    private final BlockRenderManager blocks;

    public MeteorRenderer(EntityRendererFactory.Context ctx) {
        super(ctx);
        this.blocks = ctx.getBlockRenderManager();
    }

    @Override
    public void render(MeteorEntity entity, float yaw, float tickDelta, MatrixStack matrices, VertexConsumerProvider vertices, int light) {
        if (entity.isInvisible()) {
            return;
        }
        float spin = (entity.age + tickDelta) * 9f;
        matrices.push();
        matrices.translate(0, 2, 0);
        matrices.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(spin));
        matrices.multiply(RotationAxis.POSITIVE_X.rotationDegrees(spin * 0.7f));
        renderCube(matrices, vertices, ModBlocks.FRAGMENTO_METEORITO.getDefaultState(), 3.2f, 0, 0, 0);
        // Trozos de magma sobresaliendo por cada cara.
        float o = 1.3f;
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, o, 0.4f, 0);
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, -o, -0.3f, 0.5f);
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, 0.2f, o, -0.4f);
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, -0.5f, -o, 0.1f);
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, 0.3f, 0.2f, o);
        renderCube(matrices, vertices, Blocks.MAGMA_BLOCK.getDefaultState(), 1.4f, 0, -0.5f, -o);
        matrices.pop();
        super.render(entity, yaw, tickDelta, matrices, vertices, light);
    }

    private void renderCube(MatrixStack matrices, VertexConsumerProvider vertices, BlockState state, float size,
                            float x, float y, float z) {
        matrices.push();
        matrices.translate(x, y, z);
        matrices.scale(size, size, size);
        matrices.translate(-0.5, -0.5, -0.5);
        blocks.renderBlockAsEntity(state, matrices, vertices, LightmapTextureManager.MAX_LIGHT_COORDINATE, OverlayTexture.DEFAULT_UV);
        matrices.pop();
    }

    @Override
    public Identifier getTexture(MeteorEntity entity) {
        return SpriteAtlasTexture.BLOCK_ATLAS_TEXTURE;
    }
}
