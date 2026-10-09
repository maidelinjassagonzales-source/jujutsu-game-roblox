package com.turbopapu.item;

import net.minecraft.entity.LivingEntity;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.ItemUsage;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.util.UseAction;
import net.minecraft.world.World;

/** Leche de coco Aroy-D, regalo de Aroy: te cura y te deja duro como una lata. */
public class CoconutMilkItem extends TooltipItem {
    public CoconutMilkItem(Settings settings) {
        super(settings, "leche_de_coco");
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        return ItemUsage.consumeHeldItem(world, user, hand);
    }

    @Override
    public UseAction getUseAction(ItemStack stack) {
        return UseAction.DRINK;
    }

    @Override
    public int getMaxUseTime(ItemStack stack) {
        return 32;
    }

    @Override
    public ItemStack finishUsing(ItemStack stack, World world, LivingEntity user) {
        if (!world.isClient) {
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.REGENERATION, 20 * 12, 1));
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.RESISTANCE, 20 * 60, 0));
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.SATURATION, 10, 0));
            world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ENTITY_GENERIC_DRINK, SoundCategory.PLAYERS, 1f, 1.2f);
            if (user instanceof PlayerEntity player) {
                player.sendMessage(Text.translatable("message.turbopapu.leche_de_coco").formatted(Formatting.GOLD), true);
            }
        }
        if (!(user instanceof PlayerEntity player) || !player.getAbilities().creativeMode) {
            stack.decrement(1);
        }
        return stack;
    }
}
