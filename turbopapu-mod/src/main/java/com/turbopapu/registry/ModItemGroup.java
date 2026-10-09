package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import net.fabricmc.fabric.api.itemgroup.v1.FabricItemGroup;
import net.minecraft.item.Item;
import net.minecraft.item.ItemGroup;
import net.minecraft.item.ItemStack;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;
import net.minecraft.text.Text;

public final class ModItemGroup {
    public static final ItemGroup TURBOPAPU = FabricItemGroup.builder()
            .icon(() -> new ItemStack(ModItems.COHETE))
            .displayName(Text.translatable("itemGroup.turbopapu"))
            .entries((context, entries) -> {
                for (Item item : ModItems.ALL) {
                    entries.add(item);
                }
            })
            .build();

    private ModItemGroup() {}

    public static void register() {
        Registry.register(Registries.ITEM_GROUP, TurboPapuMod.id("turbopapu"), TURBOPAPU);
    }
}
