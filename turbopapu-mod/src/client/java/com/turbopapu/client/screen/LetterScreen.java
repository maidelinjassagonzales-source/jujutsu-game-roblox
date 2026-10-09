package com.turbopapu.client.screen;

import net.minecraft.client.gui.DrawContext;
import net.minecraft.client.gui.screen.Screen;
import net.minecraft.client.sound.PositionedSoundInstance;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.OrderedText;
import net.minecraft.text.Text;

import java.util.List;

/**
 * La carta de auxilio al estilo de la carta de Peach al empezar Super Mario 64:
 * pergamino, texto que aparece letra a letra y firma al final. Clic para saltar / cerrar.
 */
public class LetterScreen extends Screen {
    private static final String LETTER = """
            Querido terrícola:

            ¡Por favor, ven al Planeta TurboPapu! Te hemos preparado un asado.

            Pero hay un problema... Ha aparecido un enemigo que podría acabar con toda nuestra especie: SUALENIDUS. \
            Es un gordo ENORME con una barriga que no para de crecer. No deja de hablar de armas de Valorant, \
            huele a lavanda y se ríe como un loco.

            Por su culpa casi todos los Turbopapuenses nos estamos quedando dormidos y no podemos despertar. \
            Solo unos pocos hemos aguantado despiertos para mandarte este meteorito.

            En el cofre tienes los planos de un cohete. Constrúyelo y ven a salvarnos, por favor.

            Atentamente,
            Los Turbopapuenses (los que siguen despiertos)""";

    private float shown;
    private int ticks;

    public LetterScreen() {
        super(Text.literal("Carta de los Turbopapuenses"));
    }

    @Override
    protected void init() {
        if (ticks == 0 && client != null) {
            client.getSoundManager().play(PositionedSoundInstance.master(SoundEvents.ITEM_BOOK_PAGE_TURN, 1f));
        }
    }

    @Override
    public void tick() {
        ticks++;
        shown = Math.min(LETTER.length(), shown + 1.6f);
        if (client != null && ticks % 3 == 0 && shown < LETTER.length()) {
            client.getSoundManager().play(PositionedSoundInstance.master(SoundEvents.BLOCK_WOODEN_BUTTON_CLICK_ON, 2.0f, 0.1f));
        }
    }

    @Override
    public void render(DrawContext ctx, int mouseX, int mouseY, float delta) {
        ctx.fill(0, 0, width, height, 0xC0000000);
        int w = Math.min(320, width - 20);
        int h = Math.min(230, height - 20);
        int x = (width - w) / 2;
        int y = (height - h) / 2;

        // Pergamino con bordes.
        ctx.fill(x - 3, y - 3, x + w + 3, y + h + 3, 0xFF6B4F2A);
        ctx.fill(x, y, x + w, y + h, 0xFFF3E2B3);
        ctx.fill(x + 4, y + 4, x + w - 4, y + h - 4, 0xFFF8EBC6);
        // Sello naranja/azul de TurboPapu.
        int sx = x + w - 26, sy = y + 8;
        ctx.fill(sx, sy, sx + 18, sy + 18, 0xFF4B3FD1);
        ctx.fill(sx + 3, sy + 3, sx + 18, sy + 18, 0xFFF2A33A);
        ctx.fill(sx + 5, sy + 7, sx + 7, sy + 10, 0xFF1A1A1A);
        ctx.fill(sx + 11, sy + 7, sx + 13, sy + 10, 0xFF1A1A1A);
        ctx.fill(sx + 7, sy + 12, sx + 11, sy + 15, 0xFF2EC4C4);

        String visible = LETTER.substring(0, (int) shown);
        List<OrderedText> lines = textRenderer.wrapLines(Text.literal(visible), w - 36);
        int lineY = y + 12;
        int maxLines = (h - 30) / 10;
        int start = Math.max(0, lines.size() - maxLines);
        for (int i = start; i < lines.size(); i++) {
            ctx.drawText(textRenderer, lines.get(i), x + 14, lineY, 0xFF3B2A14, false);
            lineY += 10;
        }
        if (shown >= LETTER.length() && (ticks / 10) % 2 == 0) {
            ctx.drawCenteredTextWithShadow(textRenderer, Text.literal("▼ Clic para cerrar"), width / 2, y + h - 14, 0xFFFFD34E);
        }
        super.render(ctx, mouseX, mouseY, delta);
    }

    @Override
    public boolean mouseClicked(double mouseX, double mouseY, int button) {
        if (shown < LETTER.length()) {
            shown = LETTER.length();
        } else {
            close();
        }
        return true;
    }

    @Override
    public boolean shouldPause() {
        return false;
    }
}
