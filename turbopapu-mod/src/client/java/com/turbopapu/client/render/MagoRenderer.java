package com.turbopapu.client.render;

import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.entity.PapuNpcEntity;
import net.minecraft.client.render.entity.EntityRendererFactory;
import net.minecraft.client.util.math.MatrixStack;

/** El Mago Larguirucho: el modelo de mago estirado, flaco y altísimo. */
public class MagoRenderer extends PapuNpcRenderer {
    public MagoRenderer(EntityRendererFactory.Context ctx) {
        super(ctx, ModModelLayers.MAGO, 1f);
    }

    @Override
    protected void scale(PapuNpcEntity entity, MatrixStack matrices, float amount) {
        matrices.scale(0.75f, 1.32f, 0.75f);
    }
}
