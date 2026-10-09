package com.turbopapu.client.screen;

import com.turbopapu.TurboPapuMod;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.text.Text;
import net.minecraft.util.Identifier;
import net.minecraft.util.math.random.Random;

/** Viaje espacial: estrellas pasando y el Planeta TurboPapu (¡con cara!) acercándose. */
public class TravelScreen extends Screen {
    private static final Identifier PLANET = TurboPapuMod.id("textures/gui/planeta_turbopapu.png");
    private static final int DURATION = 120;

    private final boolean toPlanet;
    private final float[][] stars = new float[160][3];
    private int ticks;

    public TravelScreen(boolean toPlanet) {
        super(Text.literal("Viaje"));
        this.toPlanet = toPlanet;
        Random random = Random.create();
        for (float[] s : stars) {
            s[0] = random.nextFloat() * 2 - 1;
            s[1] = random.nextFloat() * 2 - 1;
            s[2] = random.nextFloat();
        }
    }

    @Override
    public void tick() {
        if (++ticks >= DURATION) {
            close();
        }
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        float t = (ticks + delta) / DURATION;
        ctx.fill(0, 0, width, height, 0xFF05030F);
        int cx = width / 2, cy = height / 2;
        for (float[] s : stars) {
            float z = (s[2] - t * 0.8f) % 1f;
            if (z < 0) z += 1f;
            float depth = 0.05f + z;
            int x = (int) (cx + s[0] * cx / depth * 0.4f);
            int y = (int) (cy + s[1] * cy / depth * 0.4f);
            int size = depth < 0.3f ? 2 : 1;
            ctx.fill(x, y, x + size, y + size, 0xFFFFFFFF);
        }
        if (toPlanet) {
            int size = (int) (16 + Math.pow(t, 2.2) * Math.min(width, height) * 1.4);
            ctx.drawTexture(PLANET, cx - size / 2, cy - size / 2, size, size, 0, 0, 256, 256, 256, 256);
            ctx.drawCenteredTextWithShadow(textRenderer, Text.translatable("travel.turbopapu.to_planet"), cx, height - 30, 0xFFF2A33A);
        } else {
            int size = (int) (16 + Math.pow(t, 2.2) * Math.min(width, height) * 1.4);
            ctx.fill(cx - size / 2, cy - size / 2, cx + size / 2, cy + size / 2, 0xFF2E7D32);
            ctx.fill(cx - size / 3, cy - size / 4, cx + size / 4, cy + size / 3, 0xFF1565C0);
            ctx.drawCenteredTextWithShadow(textRenderer, Text.translatable("travel.turbopapu.to_overworld"), cx, height - 30, 0xFF75AADB);
        }
        if (t > 0.85f) {
            int alpha = (int) ((t - 0.85f) / 0.15f * 255) & 0xFF;
            ctx.fill(0, 0, width, height, (alpha << 24) | 0xFFFFFF);
        }
    }

    @Override
    public boolean shouldPause() {
        return false;
    }
}
