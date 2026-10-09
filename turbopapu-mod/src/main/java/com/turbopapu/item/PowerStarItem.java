package com.turbopapu.item;

import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.world.World;

/** La Estrella de Poder de elink_64: te cura entero y te da corazones extra. "¡Here we go!" */
public class PowerStarItem extends TooltipItem {
    public PowerStarItem(Settings settings) {
        super(settings, "estrella_de_poder");
    }

    @Override
    public boolean hasGlint(ItemStack stack) {
        return true;
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        ItemStack stack = user.getStackInHand(hand);
        if (!world.isClient) {
            user.setHealth(user.getMaxHealth());
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.ABSORPTION, 20 * 120, 2));
            user.addStatusEffect(new StatusEffectInstance(StatusEffects.JUMP_BOOST, 20 * 30, 1));
            world.playSound(null, user.getX(), user.getY(), user.getZ(), SoundEvents.ENTITY_PLAYER_LEVELUP, SoundCategory.PLAYERS, 1f, 1.5f);
            user.sendMessage(Text.translatable("message.turbopapu.estrella").formatted(Formatting.YELLOW), true);
            if (!user.getAbilities().creativeMode) {
                stack.decrement(1);
            }
        }
        user.getItemCooldownManager().set(this, 40);
        return TypedActionResult.success(stack, world.isClient);
    }
}
