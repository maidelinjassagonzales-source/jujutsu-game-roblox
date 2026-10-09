package com.turbopapu.client;

import com.turbopapu.client.model.ModModelLayers;
import com.turbopapu.client.model.PapuHumanoidModel;
import com.turbopapu.client.model.TurboPapuenseModel;
import com.turbopapu.client.render.*;
import com.turbopapu.client.dialogue.DialogueScreen;
import com.turbopapu.client.dialogue.Dialogues;
import com.turbopapu.client.screen.EndingScreen;
import com.turbopapu.client.screen.PvzScreen;
import net.fabricmc.fabric.api.networking.v1.PacketByteBufs;
import net.minecraft.network.PacketByteBuf;
import com.turbopapu.client.screen.LetterScreen;
import com.turbopapu.client.screen.TravelScreen;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModEffects;
import com.turbopapu.registry.ModEntities;
import net.fabricmc.api.ClientModInitializer;
import net.fabricmc.fabric.api.client.event.lifecycle.v1.ClientTickEvents;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.client.rendering.v1.EntityModelLayerRegistry;
import net.fabricmc.fabric.api.client.rendering.v1.EntityRendererRegistry;
import net.fabricmc.fabric.api.client.rendering.v1.HudRenderCallback;
import net.minecraft.client.MinecraftClient;
import net.minecraft.client.gui.DrawContext;
import net.minecraft.text.Text;

public class TurboPapuClient implements ClientModInitializer {
    @Override
    public void onInitializeClient() {
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.TURBOPAPUENSE, TurboPapuenseModel::getTexturedModelData);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.HUMANOID, PapuHumanoidModel::humanoid);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.GUINXU, PapuHumanoidModel::guinxu);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.WILLIAM, PapuHumanoidModel::william);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.FAT, PapuHumanoidModel::fat);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.AROY, com.turbopapu.client.model.AroyModel::getTexturedModelData);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.MAGO, PapuHumanoidModel::mago);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.SALCHICHA, com.turbopapu.client.model.SalchichaModel::getTexturedModelData);
        EntityModelLayerRegistry.registerModelLayer(ModModelLayers.VERITY, com.turbopapu.client.model.VerityModel::getTexturedModelData);

        EntityRendererRegistry.register(ModEntities.TURBOPAPUENSE, TurboPapuenseRenderer::new);
        EntityRendererRegistry.register(ModEntities.ALPHATEMP, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1f));
        EntityRendererRegistry.register(ModEntities.ALPHAFATERFUR, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1f));
        EntityRendererRegistry.register(ModEntities.WILLIAM_PIRATON, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.WILLIAM, 1f));
        EntityRendererRegistry.register(ModEntities.JUANMA, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1f));
        EntityRendererRegistry.register(ModEntities.GUINXU, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.GUINXU, 1f));
        EntityRendererRegistry.register(ModEntities.ELINK_64, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1f));
        EntityRendererRegistry.register(ModEntities.VERITY_GORDA, VerityRenderer::new);
        EntityRendererRegistry.register(ModEntities.AROY, AroyRenderer::new);
        EntityRendererRegistry.register(ModEntities.MUDOKON, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1f));
        EntityRendererRegistry.register(ModEntities.ABE, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.HUMANOID, 1.05f));
        EntityRendererRegistry.register(ModEntities.MAGO_LARGUIRUCHO, com.turbopapu.client.render.MagoRenderer::new);
        EntityRendererRegistry.register(ModEntities.SALCHICHA, com.turbopapu.client.render.SalchichaRenderer::new);
        EntityRendererRegistry.register(ModEntities.SUALENIDUS, SualenidusRenderer::new);
        EntityRendererRegistry.register(ModEntities.METEOR, MeteorRenderer::new);
        EntityRendererRegistry.register(ModEntities.SUALEM_MINI, SualemMiniRenderer::new);
        EntityRendererRegistry.register(ModEntities.PVZ_PLANT, PvzPlantRenderer::new);
        EntityRendererRegistry.register(ModEntities.PVZ_PROJECTILE, ctx -> new net.minecraft.client.render.entity.FlyingItemEntityRenderer<>(ctx, 1.4f, true));
        EntityRendererRegistry.register(ModEntities.SUALENIDUS_AMIGO, ctx -> new PapuNpcRenderer(ctx, ModModelLayers.FAT, 1.4f));
        net.fabricmc.fabric.api.blockrenderlayer.v1.BlockRenderLayerMap.INSTANCE.putBlocks(net.minecraft.client.render.RenderLayer.getCutout(),
                com.turbopapu.registry.ModBlocks.ATRAPASUENOS, com.turbopapu.registry.ModBlocks.ARBUSTO_SPOOCE,
                com.turbopapu.registry.ModBlocks.VASIJA_MUDOKON);
        EntityRendererRegistry.register(ModEntities.ROCKET, RocketRenderer::new);

        ClientPlayNetworking.registerGlobalReceiver(ModPackets.CINEMATIC, (client, handler, buf, sender) -> {
            int id = buf.readVarInt();
            int ticks = buf.readVarInt();
            client.execute(() -> CinematicController.start(id, ticks));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.OPEN_LETTER, (client, handler, buf, sender) ->
                client.execute(() -> client.setScreen(new LetterScreen())));
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.TRAVEL, (client, handler, buf, sender) -> {
            boolean toPlanet = buf.readBoolean();
            client.execute(() -> client.setScreen(new TravelScreen(toPlanet)));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.ENDING, (client, handler, buf, sender) ->
                client.execute(() -> client.setScreen(new DialogueScreen(Dialogues.get("final_victoria"), -1)
                        .onFinish(() -> client.setScreen(new EndingScreen())))));
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.FIGHT_STATE, (client, handler, buf, sender) -> {
            PacketByteBuf copy = PacketByteBufs.copy(buf);
            client.execute(() -> FightHud.read(copy));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.GLITCH, (client, handler, buf, sender) ->
                client.execute(FightHud::glitch));
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.PVZ_START, (client, handler, buf, sender) -> {
            int cam = buf.readVarInt();
            client.execute(() -> client.setScreen(new PvzScreen(cam)));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.PVZ_END, (client, handler, buf, sender) ->
                client.execute(() -> {
                    if (client.currentScreen instanceof PvzScreen) {
                        client.setScreen(null);
                    }
                    if (client.player != null) {
                        client.setCameraEntity(client.player);
                    }
                }));
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.MUSIC, (client, handler, buf, sender) -> {
            String key = buf.readString();
            client.execute(() -> FightHud.setAreaMusic(key));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.LANDING, (client, handler, buf, sender) -> {
            int rocket = buf.readVarInt();
            int cam = buf.readVarInt();
            client.execute(() -> LandingCinematic.start(rocket, cam));
        });
        ClientPlayNetworking.registerGlobalReceiver(ModPackets.DIALOGUE, (client, handler, buf, sender) -> {
            String key = buf.readString();
            int variant = buf.readVarInt();
            int npcId = buf.readVarInt();
            client.execute(() -> client.setScreen(new DialogueScreen(Dialogues.pick(key, variant), npcId)));
        });

        ClientTickEvents.END_CLIENT_TICK.register(CinematicController::tick);
        ClientTickEvents.END_CLIENT_TICK.register(client -> {
            FightHud.tick();
            LandingCinematic.tick(client);
        });
        HudRenderCallback.EVENT.register((ctx, tickDelta) -> {
            renderSleepOverlay(ctx);
            CinematicController.renderHud(ctx, tickDelta);
            FightHud.render(ctx);
            LandingCinematic.renderHud(ctx);
        });
    }

    /** Cuando Sualenidus te duerme: pantalla morada que parpadea y "Zzz". */
    private static void renderSleepOverlay(DrawContext ctx) {
        MinecraftClient client = MinecraftClient.getInstance();
        if (client.player == null || !client.player.hasStatusEffect(ModEffects.DORMIDO)) {
            return;
        }
        int w = ctx.getScaledWindowWidth();
        int h = ctx.getScaledWindowHeight();
        float blink = (float) (Math.sin(client.player.age * 0.15) * 0.5 + 0.5);
        int alpha = (int) (110 + blink * 110);
        ctx.fill(0, 0, w, h, (alpha << 24) | 0x2A1240);
        ctx.drawCenteredTextWithShadow(client.textRenderer, Text.literal("Z z z . . ."), w / 2, h / 2 - 20, 0xFFB57EDC);
        ctx.drawCenteredTextWithShadow(client.textRenderer, Text.translatable("hud.turbopapu.asleep"), w / 2, h / 2, 0xFFFFFFFF);
    }
}
