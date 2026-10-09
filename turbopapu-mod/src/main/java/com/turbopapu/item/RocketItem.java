package com.turbopapu.item;

import com.turbopapu.entity.RocketEntity;
import com.turbopapu.registry.ModEntities;
import net.minecraft.item.ItemUsageContext;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.ActionResult;
import net.minecraft.util.math.BlockPos;

/** Coloca el cohete en el suelo. Súbete (clic derecho) para despegar. */
public class RocketItem extends TooltipItem {
    public RocketItem(Settings settings) {
        super(settings, "cohete");
    }

    @Override
    public ActionResult useOnBlock(ItemUsageContext context) {
        if (!(context.getWorld() instanceof ServerWorld world)) {
            return ActionResult.SUCCESS;
        }
        BlockPos pos = context.getBlockPos().offset(context.getSide());
        RocketEntity rocket = ModEntities.ROCKET.create(world);
        if (rocket == null) {
            return ActionResult.FAIL;
        }
        rocket.refreshPositionAndAngles(pos.getX() + 0.5, pos.getY(), pos.getZ() + 0.5, 0, 0);
        world.spawnEntity(rocket);
        world.playSound(null, pos, SoundEvents.BLOCK_ANVIL_PLACE, SoundCategory.BLOCKS, 0.8f, 1.2f);
        if (context.getPlayer() == null || !context.getPlayer().getAbilities().creativeMode) {
            context.getStack().decrement(1);
        }
        return ActionResult.CONSUME;
    }
}
