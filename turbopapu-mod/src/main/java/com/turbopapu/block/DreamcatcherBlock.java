package com.turbopapu.block;

import net.minecraft.block.Block;
import net.minecraft.block.BlockState;
import net.minecraft.block.HorizontalFacingBlock;
import net.minecraft.block.ShapeContext;
import net.minecraft.item.ItemPlacementContext;
import net.minecraft.state.StateManager;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.shape.VoxelShape;
import net.minecraft.world.BlockView;

/** Atrapasueños colgado en la pared (estilo Mudokon). No tiene colisión. */
public class DreamcatcherBlock extends HorizontalFacingBlock {
    private static final VoxelShape NORTH_WALL = Block.createCuboidShape(1, 1, 0, 15, 15, 1);
    private static final VoxelShape SOUTH_WALL = Block.createCuboidShape(1, 1, 15, 15, 15, 16);
    private static final VoxelShape WEST_WALL = Block.createCuboidShape(0, 1, 1, 1, 15, 15);
    private static final VoxelShape EAST_WALL = Block.createCuboidShape(15, 1, 1, 16, 15, 15);

    public DreamcatcherBlock(Settings settings) {
        super(settings);
        setDefaultState(getStateManager().getDefaultState().with(FACING, Direction.SOUTH));
    }

    @Override
    protected void appendProperties(StateManager.Builder<Block, BlockState> builder) {
        builder.add(FACING);
    }

    @Override
    public BlockState getPlacementState(ItemPlacementContext ctx) {
        Direction side = ctx.getSide();
        Direction facing = side.getAxis().isHorizontal() ? side : ctx.getHorizontalPlayerFacing().getOpposite();
        return getDefaultState().with(FACING, facing);
    }

    @Override
    public VoxelShape getOutlineShape(BlockState state, BlockView world, BlockPos pos, ShapeContext context) {
        // Mira hacia FACING, así que la pared está detrás (en la dirección contraria).
        return switch (state.get(FACING)) {
            case SOUTH -> NORTH_WALL;
            case NORTH -> SOUTH_WALL;
            case EAST -> WEST_WALL;
            default -> EAST_WALL;
        };
    }
}
