package com.turbopapu.item;

import com.turbopapu.registry.ModEffects;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.Item;
import net.minecraft.item.ItemStack;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.world.World;

/**
 * Mantequilla: la comida del Gordo Pañales. Clic derecho para untártela en los pies y deslizarte a toda
 * velocidad durante 20 segundos (cada untada extra suma tiempo).
 */
public class MantequillaItem extends Item {
    public MantequillaItem(Settings settings) {
        super(settings);
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        ItemStack stack = user.getStackInHand(hand);
        if (!world.isClient) {
            StatusEffectInstance current = user.getStatusEffect(ModEffects.UNTADO);
            int duration = Math.min(20 * 120, (current == null ? 0 : current.getDuration()) + 20 * 20);
            user.addStatusEffect(new StatusEffectInstance(ModEffects.UNTADO, duration, 0, false, true, true));
            world.playSound(null, user.getBlockPos(), SoundEvents.BLOCK_HONEY_BLOCK_SLIDE, SoundCategory.PLAYERS, 1f, 1.2f);
            user.sendMessage(Text.literal("Te untas mantequilla en los pies... ¡a deslizarse!").formatted(Formatting.YELLOW), true);
            if (!user.getAbilities().creativeMode) {
                stack.decrement(1);
            }
        }
        return TypedActionResult.success(stack, world.isClient);
    }
}
