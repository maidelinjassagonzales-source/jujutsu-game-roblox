package com.turbopapu.item;

import com.turbopapu.world.IcebergBuilder;
import net.minecraft.entity.player.PlayerEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.Hand;
import net.minecraft.util.TypedActionResult;
import net.minecraft.util.hit.BlockHitResult;
import net.minecraft.util.hit.HitResult;
import net.minecraft.world.World;

/** Regalo de Alphatemp: invoca un iceberg ENORME donde estés mirando (y aplasta a Sualenidus si está cerca). */
public class PocketIcebergItem extends TooltipItem {
    public PocketIcebergItem(Settings settings) {
        super(settings, "iceberg_de_bolsillo");
    }

    @Override
    public TypedActionResult<ItemStack> use(World world, PlayerEntity user, Hand hand) {
        ItemStack stack = user.getStackInHand(hand);
        HitResult hit = user.raycast(64, 0, true);
        if (hit.getType() != HitResult.Type.BLOCK) {
            return TypedActionResult.fail(stack);
        }
        if (world instanceof ServerWorld serverWorld) {
            IcebergBuilder.summon(serverWorld, ((BlockHitResult) hit).getBlockPos().up(), serverWorld.getRandom());
            user.sendMessage(Text.translatable("message.turbopapu.iceberg").formatted(Formatting.AQUA), true);
            if (!user.getAbilities().creativeMode) {
                stack.decrement(1);
            }
        }
        user.getItemCooldownManager().set(this, 100);
        return TypedActionResult.success(stack, world.isClient);
    }
}
