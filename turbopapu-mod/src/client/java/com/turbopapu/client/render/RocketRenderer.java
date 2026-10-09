package com.turbopapu.client.render;

import com.turbopapu.entity.RocketEntity;
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

/** El cohete, montado con bloques: cuerpo blanco, punta y aletas naranjas/azules (colores TurboPapu) y ventanilla. */
public class RocketRenderer extends EntityRenderer<RocketEntity> {
    private final BlockRenderManager blocks;

    public RocketRenderer(EntityRendererFactory.Context ctx) {
        super(ctx);
        this.blocks = ctx.getBlockRenderManager();
        this.shadowRadius = 0.8f;
    }

    @Override
    public void render(RocketEntity rocket, float yaw, float tickDelta, MatrixStack m, VertexConsumerProvider v, int light) {
        m.push();
        if (rocket.getFlight() >= 0 && !rocket.isFlying()) {
            // Tiembla durante la cuenta atrás.
            m.translate((rocket.getWorld().random.nextFloat() - 0.5f) * 0.06f, 0, (rocket.getWorld().random.nextFloat() - 0.5f) * 0.06f);
        }
        // Cuerpo.
        piece(m, v, Blocks.WHITE_CONCRETE.getDefaultState(), -0.5f, 0.5f, -0.5f, 1f, 2.6f, 1f, light);
        // Ventanilla.
        piece(m, v, Blocks.LIGHT_BLUE_STAINED_GLASS.getDefaultState(), -0.25f, 2.0f, -0.55f, 0.5f, 0.5f, 0.1f, light);
        // Franja naranja.
        piece(m, v, Blocks.ORANGE_CONCRETE.getDefaultState(), -0.52f, 1.2f, -0.52f, 1.04f, 0.25f, 1.04f, light);
        // Punta en escalones.
        piece(m, v, Blocks.ORANGE_CONCRETE.getDefaultState(), -0.4f, 3.1f, -0.4f, 0.8f, 0.4f, 0.8f, light);
        piece(m, v, Blocks.BLUE_CONCRETE.getDefaultState(), -0.28f, 3.5f, -0.28f, 0.56f, 0.4f, 0.56f, light);
        piece(m, v, Blocks.BLUE_CONCRETE.getDefaultState(), -0.14f, 3.9f, -0.14f, 0.28f, 0.4f, 0.28f, light);
        // Aletas.
        for (int i = 0; i < 4; i++) {
            m.push();
            m.multiply(RotationAxis.POSITIVE_Y.rotationDegrees(90 * i));
            piece(m, v, Blocks.BLUE_CONCRETE.getDefaultState(), 0.5f, 0.0f, -0.08f, 0.5f, 1.0f, 0.16f, light);
            m.pop();
        }
        // Tobera.
        piece(m, v, Blocks.GRAY_CONCRETE.getDefaultState(), -0.3f, 0.2f, -0.3f, 0.6f, 0.3f, 0.6f, light);
        if (rocket.isFlying()) {
            piece(m, v, Blocks.MAGMA_BLOCK.getDefaultState(), -0.25f, -0.6f, -0.25f, 0.5f, 0.8f, 0.5f, LightmapTextureManager.MAX_LIGHT_COORDINATE);
        }
        m.pop();
        super.render(rocket, yaw, tickDelta, m, v, light);
    }

    private void piece(MatrixStack m, VertexConsumerProvider v, BlockState state, float x, float y, float z,
                       float sx, float sy, float sz, int light) {
        m.push();
        m.translate(x, y, z);
        m.scale(sx, sy, sz);
        blocks.renderBlockAsEntity(state, m, v, light, OverlayTexture.DEFAULT_UV);
        m.pop();
    }

    @Override
    public Identifier getTexture(RocketEntity entity) {
        return SpriteAtlasTexture.BLOCK_ATLAS_TEXTURE;
    }
}
