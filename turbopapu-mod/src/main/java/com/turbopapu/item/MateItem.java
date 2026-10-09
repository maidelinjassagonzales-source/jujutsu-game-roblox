package com.turbopapu.item;

import com.turbopapu.registry.ModEffects;
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

/** El mate de Juanma: te despierta y te protege del sueño de lavanda durante un minuto. */
public class MateItem extends TooltipItem {
    public MateItem(Settings settings) {
        super(settings, "mate");
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
        return 24;
    }

    @Override
    public ItemStack finishUsing(ItemStack stack, World world, LivingEntity user) {
        if (!world.isClient) {
            user.removeStatusEffect(ModEffects.DORMIDO);
            user.addStatusEffect(new StatusEffectInstance(ModEffects.DESPIERTO, 20 * 60, 0));
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.SPEED, 20 * 30, 0));
            world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ENTITY_GENERIC_DRINK, SoundCategory.PLAYERS, 1f, 1f);
            if (user instanceof PlayerEntity player) {
                player.sendMessage(Text.translatable("message.turbopapu.mate").formatted(Formatting.GREEN), true);
            }
        }
        if (!(user instanceof PlayerEntity player) || !player.getAbilities().creativeMode) {
            stack.decrement(1);
        }
        return stack;
    }
}
