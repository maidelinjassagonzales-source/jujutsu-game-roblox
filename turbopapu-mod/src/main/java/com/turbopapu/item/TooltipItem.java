package com.turbopapu.item;

import net.minecraft.client.item.TooltipContext;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

import java.util.List;

/** Objeto simple con una línea de descripción traducible: item.turbopapu.&lt;nombre&gt;.tooltip */
public class TooltipItem extends Item {
    private final String key;

    public TooltipItem(Settings settings, String name) {
        super(settings);
        this.key = "item.turbopapu." + name + ".tooltip";
    }

    @Override
    public void appendTooltip(ItemStack stack, @Nullable World world, List<Text> tooltip, TooltipContext context) {
        tooltip.add(Text.translatable(key).formatted(Formatting.GRAY, Formatting.ITALIC));
    }
}
