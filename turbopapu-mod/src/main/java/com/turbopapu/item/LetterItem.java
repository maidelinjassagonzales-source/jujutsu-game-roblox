package com.turbopapu.item;

import com.turbopapu.network.ModPackets;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.world.World;

/** La carta estilo Mario 64 que venía dentro del meteorito. Clic derecho para volver a leerla. */
public class LetterItem extends TooltipItem {
    public LetterItem(Settings settings) {
        super(settings, "carta_de_auxilio");
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        if (user instanceof ServerPlayerEntity player) {
            ModPackets.openLetter(player);
        }
        return TypedActionResult.success(user.getStackInHand(hand), world.isClient);
    }
}
