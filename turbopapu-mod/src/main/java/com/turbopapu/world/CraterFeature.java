package com.turbopapu.world;

import com.mojang.serialization.Codec;
import com.turbopapu.registry.ModBlocks;
import net.minecraft.block.BlockState;
import net.minecraft.block.Blocks;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.random.Random;
import net.minecraft.world.Heightmap;
import net.minecraft.world.StructureWorldAccess;
import net.minecraft.world.gen.feature.DefaultFeatureConfig;
import net.minecraft.world.gen.feature.Feature;
import net.minecraft.world.gen.feature.util.FeatureContext;

/** Un cráter como los de la luna: hoyo redondo con el borde un poco levantado. */
public class CraterFeature extends Feature<DefaultFeatureConfig> {
    public CraterFeature(Codec<DefaultFeatureConfig> codec) {
        super(codec);
    }

    @Override
    public boolean generate(FeatureContext<DefaultFeatureConfig> context) {
        StructureWorldAccess world = context.getWorld();
        Random random = context.getRandom();
        BlockPos origin = context.getOrigin();
        int r = 3 + random.nextInt(7);
        BlockState dust = ModBlocks.REGOLITO_PAPU.getDefaultState();
        BlockState rock = ModBlocks.ROCA_PAPU.getDefaultState();
        int rim = r + 2;

        for (int dx = -rim; dx <= rim; dx++) {
            for (int dz = -rim; dz <= rim; dz++) {
                double d = Math.sqrt(dx * dx + dz * dz) / r;
                int x = origin.getX() + dx;
                int z = origin.getZ() + dz;
                int top = world.getTopY(Heightmap.Type.WORLD_SURFACE_WG, x, z);
                BlockState ground = world.getBlockState(new BlockPos(x, top - 1, z));
                if (!ground.isOf(ModBlocks.REGOLITO_PAPU) && !ground.isOf(ModBlocks.ROCA_PAPU)) {
                    continue;
                }
                if (d <= 1.0) {
                    int depth = (int) Math.round((1 - d * d) * r * 0.5);
                    for (int y = top - 1; y > top - 1 - depth; y--) {
                        setBlockState(world, new BlockPos(x, y, z), Blocks.AIR.getDefaultState());
                    }
                    BlockPos floor = new BlockPos(x, top - 1 - depth, z);
                    setBlockState(world, floor, random.nextInt(4) == 0 ? rock : dust);
                } else if (d <= 1.35) {
                    // Borde levantado con el material que salió del impacto.
                    int h = d < 1.2 ? 2 : 1;
                    for (int y = 0; y < h; y++) {
                        setBlockState(world, new BlockPos(x, top + y, z), dust);
                    }
                }
            }
        }
        return true;
    }
}
