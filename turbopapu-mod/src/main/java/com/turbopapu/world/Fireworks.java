package com.turbopapu.world;

import net.minecraft.entity.projectile.FireworkRocketEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtList;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.math.BlockPos;

public final class Fireworks {
    private static final int[][] COLORS = {
            {0xF2A33A, 0x4B3FD1}, {0xB57EDC, 0xFFFFFF}, {0x75AADB, 0xFFFFFF}, {0xFF4655, 0xFFD700}
    };

    private Fireworks() {}

    public static void celebrate(ServerWorld world, BlockPos center, int count) {
        for (int i = 0; i < count; i++) {
            ItemStack stack = new ItemStack(Items.FIREWORK_ROCKET);
            NbtCompound explosion = new NbtCompound();
            explosion.putByte("Type", (byte) world.random.nextInt(5));
            explosion.putIntArray("Colors", COLORS[world.random.nextInt(COLORS.length)]);
            explosion.putBoolean("Flicker", true);
            explosion.putBoolean("Trail", true);
            NbtList explosions = new NbtList();
            explosions.add(explosion);
            NbtCompound fireworks = new NbtCompound();
            fireworks.putByte("Flight", (byte) (1 + world.random.nextInt(2)));
            fireworks.put("Explosions", explosions);
            stack.getOrCreateNbt().put("Fireworks", fireworks);

            double x = center.getX() + world.random.nextGaussian() * 6;
            double z = center.getZ() + world.random.nextGaussian() * 6;
            world.spawnEntity(new FireworkRocketEntity(world, x, center.getY() + 1, z, stack));
        }
    }
}
