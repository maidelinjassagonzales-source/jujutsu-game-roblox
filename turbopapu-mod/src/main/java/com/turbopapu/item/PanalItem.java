package com.turbopapu.item;

import net.minecraft.item.ArmorItem;
import net.minecraft.item.ArmorMaterial;
import net.minecraft.item.ItemStack;
import net.minecraft.recipe.Ingredient;
import net.minecraft.sound.SoundEvent;
import net.minecraft.sound.SoundEvents;
import net.minecraft.client.item.TooltipContext;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.world.World;
import org.jetbrains.annotations.Nullable;

import java.util.List;

/** El pañal del Gordo Pañales. Póntelo (pantalones) y pulsa G para cagarte encima. */
public class PanalItem extends ArmorItem {
    public static final ArmorMaterial MATERIAL = new ArmorMaterial() {
        @Override
        public int getDurability(Type type) {
            return 300;
        }

        @Override
        public int getProtection(Type type) {
            return 2;
        }

        @Override
        public int getEnchantability() {
            return 10;
        }

        @Override
        public SoundEvent getEquipSound() {
            return SoundEvents.ITEM_ARMOR_EQUIP_LEATHER;
        }

        @Override
        public Ingredient getRepairIngredient() {
            return Ingredient.EMPTY;
        }

        @Override
        public String getName() {
            return "panal";
        }

        @Override
        public float getToughness() {
            return 0;
        }

        @Override
        public float getKnockbackResistance() {
            return 0;
        }
    };

    public PanalItem(Settings settings) {
        super(MATERIAL, Type.LEGGINGS, settings);
    }

    @Override
    public void appendTooltip(ItemStack stack, @Nullable World world, List<Text> tooltip, TooltipContext context) {
        tooltip.add(Text.literal("Regalo del Gordo Pañales.").formatted(Formatting.GRAY));
        tooltip.add(Text.literal("Póntelo y pulsa G para cagarte encima.").formatted(Formatting.GOLD));
        if (stack.hasNbt() && stack.getNbt().getBoolean("Cagado")) {
            tooltip.add(Text.literal("Cagado: rebotas al caer. Si rebotas demasiado...").formatted(Formatting.DARK_RED));
        }
    }
}
