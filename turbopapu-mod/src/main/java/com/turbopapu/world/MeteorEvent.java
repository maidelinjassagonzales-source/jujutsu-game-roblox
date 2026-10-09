package com.turbopapu.world;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.entity.MeteorEntity;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModBlocks;
import com.turbopapu.registry.ModEntities;
import com.turbopapu.registry.ModItems;
import net.minecraft.block.Blocks;
import net.minecraft.block.ChestBlock;
import net.minecraft.block.entity.ChestBlockEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.network.packet.s2c.play.SubtitleS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleFadeS2CPacket;
import net.minecraft.network.packet.s2c.play.TitleS2CPacket;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.sound.SoundCategory;
import net.minecraft.sound.SoundEvents;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.util.math.Direction;
import net.minecraft.util.math.MathHelper;
import net.minecraft.util.math.Vec3d;
import net.minecraft.world.World;

/**
 * El inicio de la historia: un meteorito cae del cielo cerca del jugador (con cinemática), y dentro hay
 * una carta de auxilio estilo Mario 64 y un cofre con los planos del cohete.
 */
public final class MeteorEvent {
    private static final int FALL_TICKS = 140;

    private MeteorEvent() {}

    public static void launch(ServerWorld world, ServerPlayerEntity player) {
        TurboState state = TurboState.get(world.getServer());
        state.meteorIncoming = true;

        double angle = world.random.nextDouble() * Math.PI * 2;
        int dist = 18 + world.random.nextInt(8);
        int tx = MathHelper.floor(player.getX() + Math.cos(angle) * dist);
        int tz = MathHelper.floor(player.getZ() + Math.sin(angle) * dist);
        int ty = Build.surface(world, tx, tz);
        BlockPos target = new BlockPos(tx, ty, tz);

        // Viene "desde el espacio", en diagonal.
        double startY = Math.min(world.getTopY() - 5, ty + 150);
        Vec3d start = new Vec3d(tx + 0.5 + Math.cos(angle) * 90, startY, tz + 0.5 + Math.sin(angle) * 90);
        Vec3d end = Vec3d.ofBottomCenter(target);
        Vec3d velocity = end.subtract(start).multiply(1.0 / FALL_TICKS);

        MeteorEntity meteor = ModEntities.METEOR.create(world);
        if (meteor == null) {
            state.meteorIncoming = false;
            return;
        }
        meteor.refreshPositionAndAngles(start.x, start.y, start.z, 0, 0);
        meteor.setVelocity(velocity);
        meteor.setTarget(target);
        world.spawnEntity(meteor);
        TurboPapuMod.LOGGER.info("Meteorito TurboPapu en camino hacia {}", target);

        for (ServerPlayerEntity p : world.getPlayers(p -> p.squaredDistanceTo(end) < 200 * 200)) {
            ModPackets.startCinematic(p, meteor.getId(), FALL_TICKS + 50);
            p.networkHandler.sendPacket(new TitleFadeS2CPacket(10, 60, 20));
            p.networkHandler.sendPacket(new TitleS2CPacket(Text.translatable("title.turbopapu.meteor").formatted(Formatting.GOLD)));
            p.networkHandler.sendPacket(new SubtitleS2CPacket(Text.translatable("subtitle.turbopapu.meteor").formatted(Formatting.YELLOW)));
            world.playSound(null, p.getBlockPos(), SoundEvents.ENTITY_LIGHTNING_BOLT_THUNDER, SoundCategory.AMBIENT, 1f, 0.5f);
        }
    }

    /** Impacto: explosión, cráter y el meteorito hueco con el cofre dentro. */
    public static void impact(ServerWorld world, BlockPos target) {
        world.createExplosion(null, target.getX() + 0.5, target.getY() + 1, target.getZ() + 0.5, 4f, World.ExplosionSourceType.NONE);
        world.playSound(null, target, SoundEvents.ENTITY_GENERIC_EXPLODE, SoundCategory.BLOCKS, 8f, 0.5f);

        int r = 4;
        // Cráter.
        for (int dx = -r - 3; dx <= r + 3; dx++) {
            for (int dz = -r - 3; dz <= r + 3; dz++) {
                double d = Math.sqrt(dx * dx + dz * dz);
                if (d > r + 3) continue;
                int depth = (int) Math.round(2.5 - d * 0.35);
                for (int dy = depth; dy >= 0 && depth > 0; dy--) {
                    Build.set(world, target.add(dx, -dy, dz), Blocks.AIR.getDefaultState());
                }
                for (int dy = 1; dy <= 6; dy++) {
                    Build.set(world, target.add(dx, dy, dz), Blocks.AIR.getDefaultState());
                }
                if (world.random.nextInt(5) == 0) {
                    Build.set(world, target.add(dx, -Math.max(depth, 0) - 1, dz), Blocks.MAGMA_BLOCK.getDefaultState());
                }
            }
        }
        // Meteorito hueco (esfera de radio 3) con abertura.
        BlockPos center = target.up(2);
        for (int dx = -3; dx <= 3; dx++) {
            for (int dy = -3; dy <= 3; dy++) {
                for (int dz = -3; dz <= 3; dz++) {
                    double d = Math.sqrt(dx * dx + dy * dy + dz * dz);
                    BlockPos pos = center.add(dx, dy, dz);
                    if (d <= 3.2 && d > 2.0) {
                        Build.set(world, pos, (world.random.nextInt(6) == 0 ? Blocks.MAGMA_BLOCK : ModBlocks.FRAGMENTO_METEORITO).getDefaultState());
                    } else if (d <= 2.0) {
                        Build.set(world, pos, Blocks.AIR.getDefaultState());
                    }
                }
            }
        }
        // Entrada mirando al sur.
        for (int dy = -1; dy <= 0; dy++) {
            for (int dz = 2; dz <= 3; dz++) {
                Build.set(world, center.add(0, dy, dz), Blocks.AIR.getDefaultState());
            }
        }
        BlockPos floor = center.down(2);
        Build.set(world, floor, ModBlocks.FRAGMENTO_METEORITO.getDefaultState());
        Build.set(world, floor.south(), ModBlocks.FRAGMENTO_METEORITO.getDefaultState());

        BlockPos chestPos = center.down();
        Build.set(world, chestPos, Blocks.CHEST.getDefaultState().with(ChestBlock.FACING, Direction.SOUTH));
        Build.set(world, chestPos.east(), Blocks.SHROOMLIGHT.getDefaultState());
        Build.set(world, chestPos.west(), Blocks.SHROOMLIGHT.getDefaultState());

        TurboState state = TurboState.get(world.getServer());
        state.meteorFallen = true;
        state.meteorIncoming = false;
        state.meteorX = target.getX();
        state.meteorY = target.getY();
        state.meteorZ = target.getZ();
        // La choza de Alphatemp queda a ~180 bloques al este.
        state.hutX = target.getX() + 180;
        state.hutZ = target.getZ() + 40;
        state.markDirty();

        if (world.getBlockEntity(chestPos) instanceof ChestBlockEntity chest) {
            chest.setStack(4, new ItemStack(ModItems.CARTA_DE_AUXILIO));
            chest.setStack(13, Books.rocketPlans(state));
            chest.setStack(10, new ItemStack(ModBlocks.FRAGMENTO_METEORITO, 10));
            chest.setStack(16, new ItemStack(Items.COMPASS));
            chest.setStack(22, new ItemStack(Items.COOKED_BEEF, 8));
        }
    }

    /** Un par de segundos después del impacto aparece la carta en pantalla. */
    public static void afterImpact(ServerWorld world, BlockPos target) {
        for (ServerPlayerEntity p : world.getPlayers(p -> p.getBlockPos().isWithinDistance(target, 200))) {
            ModPackets.openLetter(p);
            p.sendMessage(Text.translatable("message.turbopapu.meteor_landed", target.getX(), target.getY(), target.getZ())
                    .formatted(Formatting.GOLD), false);
        }
    }
}
