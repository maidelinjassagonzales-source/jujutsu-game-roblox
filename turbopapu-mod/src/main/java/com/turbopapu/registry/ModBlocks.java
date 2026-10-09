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

    // --- Bloques de Oddworld (para la aldea Mudokon de Alphatemp) ---
    public static final Block ATRAPASUENOS = new com.turbopapu.block.DreamcatcherBlock(AbstractBlock.Settings.create()
            .mapColor(MapColor.BROWN).strength(0.3f).noCollision().nonOpaque().sounds(BlockSoundGroup.WOOL));
    public static final Block TOTEM_MUDOKON = new com.turbopapu.block.FacingDecorBlock(AbstractBlock.Settings.create()
            .mapColor(MapColor.GREEN).strength(2.0f).sounds(BlockSoundGroup.WOOD));
    public static final Block VASIJA_MUDOKON = new com.turbopapu.block.ShapedDecorBlock(AbstractBlock.Settings.create()
            .mapColor(MapColor.TERRACOTTA_ORANGE).strength(0.8f).nonOpaque().sounds(BlockSoundGroup.DECORATED_POT),
            Block.createCuboidShape(3, 0, 3, 13, 12, 13));
    public static final Block LADRILLO_MUDOKON = new Block(AbstractBlock.Settings.create()
            .mapColor(MapColor.BROWN).strength(1.5f, 3f).requiresTool().sounds(BlockSoundGroup.MUD_BRICKS));
    public static final Block ARBUSTO_SPOOCE = new com.turbopapu.block.ShapedDecorBlock(AbstractBlock.Settings.create()
            .mapColor(MapColor.LIME).breakInstantly().noCollision().nonOpaque().luminance(state -> 9).sounds(BlockSoundGroup.GRASS),
            Block.createCuboidShape(2, 0, 2, 14, 13, 14));

    private ModBlocks() {}

    public static void register() {
        Registry.register(Registries.BLOCK, TurboPapuMod.id("fragmento_meteorito"), FRAGMENTO_METEORITO);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("regolito_papu"), REGOLITO_PAPU);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("roca_papu"), ROCA_PAPU);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("atrapasuenos"), ATRAPASUENOS);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("totem_mudokon"), TOTEM_MUDOKON);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("vasija_mudokon"), VASIJA_MUDOKON);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("ladrillo_mudokon"), LADRILLO_MUDOKON);
        Registry.register(Registries.BLOCK, TurboPapuMod.id("arbusto_spooce"), ARBUSTO_SPOOCE);
    }
}
