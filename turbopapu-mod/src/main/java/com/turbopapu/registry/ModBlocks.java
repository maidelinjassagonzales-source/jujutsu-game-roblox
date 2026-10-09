package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import net.minecraft.block.AbstractBlock;
import net.minecraft.block.Block;
import net.minecraft.block.MapColor;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.sound.BlockSoundGroup;

public final class ModBlocks {
    /** Roca del meteorito que mandaron los Turbopapuenses. Brilla un poco. */
    public static final Block FRAGMENTO_METEORITO = new Block(AbstractBlock.Settings.create()
            .mapColor(MapColor.ORANGE)
            .strength(3.0f, 9.0f)
            .requiresTool()
            .luminance(state -> 7)
            .sounds(BlockSoundGroup.ANCIENT_DEBRIS));

    /** Polvo lunar del Planeta TurboPapu (la capa de arriba del suelo). */
    public static final Block REGOLITO_PAPU = new Block(AbstractBlock.Settings.create()
            .mapColor(MapColor.ORANGE)
            .strength(0.6f)
            .sounds(BlockSoundGroup.SAND));

    /** Roca lunar del Planeta TurboPapu (todo lo que hay debajo). */
    public static final Block ROCA_PAPU = new Block(AbstractBlock.Settings.create()
            .mapColor(MapColor.PURPLE)
            .strength(1.5f, 6.0f)
            .requiresTool()
            .sounds(BlockSoundGroup.TUFF));

    private ModBlocks() {}

    public static void register() {
        Registry.register(Registries.BLOCK, TurboPapuMod.id("fragmento_meteorito"), FRAGMENTO_METEORITO);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("regolito_papu"), REGOLITO_PAPU);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("roca_papu"), ROCA_PAPU);
    }
}
