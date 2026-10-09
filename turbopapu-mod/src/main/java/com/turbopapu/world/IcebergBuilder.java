package com.turbopapu.world;

import com.turbopapu.entity.SualenidusEntity;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.particle.ParticleTypes;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Box;
import net.minecraft.util.math.random.Random;

/** Los icebergs ENORMES de Alphatemp. */
public final class IcebergBuilder {
    private IcebergBuilder() {}

    public static void summon(ServerWorld world, BlockPos base, Random random) {
        int height = 14 + random.nextInt(8);
        double radius = 5 + random.nextInt(3);
        for (int y = -3; y <= height; y++) {
            double t = Math.max(0, y) / (double) height;
            double r = radius * Math.pow(1 - t, 0.8) + (y < 0 ? 1 : 0);
            int ri = (int) Math.ceil(r);
            for (int dx = -ri; dx <= ri; dx++) {
                for (int dz = -ri; dz <= ri; dz++) {
                    double wobble = random.nextDouble() * 0.8;
                    if (dx * dx + dz * dz > (r + wobble) * (r + wobble)) {
                        continue;
                    }
                    BlockPos pos = base.add(dx, y, dz);
                    BlockState current = world.getBlockState(pos);
                    if (!(current.isAir() || current.isReplaceable() || !current.getFluidState().isEmpty())) {
                        continue;
                    }
                    BlockState ice = y >= height - 2 ? Blocks.SNOW_BLOCK.getDefaultState()
                            : random.nextFloat() < 0.3f ? Blocks.BLUE_ICE.getDefaultState()
                            : Blocks.PACKED_ICE.getDefaultState();
                    Build.set(world, pos, ice);
                }
            }
        }
        world.playSound(null, base, SoundEvents.BLOCK_GLASS_BREAK, SoundCategory.BLOCKS, 4f, 0.5f);
        world.playSound(null, base, SoundEvents.ENTITY_LIGHTNING_BOLT_THUNDER, SoundCategory.BLOCKS, 2f, 1.5f);
        world.spawnParticles(ParticleTypes.SNOWFLAKE, base.getX(), base.getY() + height / 2.0, base.getZ(), 200, radius, height / 2.0, radius, 0.05);

        Box area = new Box(base).expand(radius + 3, height, radius + 3);
        for (SualenidusEntity boss : world.getEntitiesByClass(SualenidusEntity.class, area, e -> true)) {
            boss.hitByIceberg(world);
        }
        for (net.minecraft.entity.mob.HostileEntity mob : world.getEntitiesByClass(net.minecraft.entity.mob.HostileEntity.class, area,
                e -> !(e instanceof SualenidusEntity))) {
            mob.damage(world.getDamageSources().freeze(), 40f);
        }
    }
}
