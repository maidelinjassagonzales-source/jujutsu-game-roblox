package com.turbopapu;

import com.turbopapu.command.TurboCommands;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.*;
import com.turbopapu.world.TurboEvents;
import net.fabricmc.api.ModInitializer;
import net.minecraft.util.Identifier;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

public class TurboPapuMod implements ModInitializer {
    public static final String MOD_ID = "turbopapu";
    public static final Logger LOGGER = LoggerFactory.getLogger(MOD_ID);

    public static Identifier id(String path) {
        return new Identifier(MOD_ID, path);
    }

    @Override
    public void onInitialize() {
        ModBlocks.register();
        ModEffects.register();
        ModEntities.register();
        ModItems.register();
        ModItemGroup.register();
        ModPackets.register();
        TurboCommands.register();
        TurboEvents.register();
        LOGGER.info("¡El Planeta TurboPapu pide ayuda!");
    }
}
