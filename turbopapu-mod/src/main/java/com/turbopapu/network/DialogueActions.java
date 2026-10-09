package com.turbopapu.network;

import com.turbopapu.entity.NpcProfile;
import com.turbopapu.entity.PapuNpcEntity;
import com.turbopapu.fight.BossFight;
import com.turbopapu.registry.ModItems;
import com.turbopapu.world.IcebergBuilder;
import net.minecraft.item.ItemStack;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.Heightmap;

/** Lo que pasa en el mundo cuando eliges ciertas respuestas en un diálogo ("action" en dialogues.json). */
public final class DialogueActions {
    private DialogueActions() {}

    public static void handle(ServerPlayerEntity player, String action) {
        ServerWorld world = (ServerWorld) player.getWorld();
        switch (action) {
            case "mate_extra" -> {
                if (player.getCommandTags().add("turbopapu_mate_extra")) {
                    player.giveItemStack(new ItemStack(ModItems.MATE, 3));
                    player.sendMessage(Text.literal("Juanma te ha dado 3 mates más.").formatted(Formatting.GREEN), false);
                }
            }
            case "iceberg" -> {
                PapuNpcEntity alpha = world.getClosestEntity(PapuNpcEntity.class, net.minecraft.entity.ai.TargetPredicate.DEFAULT,
                        player, player.getX(), player.getY(), player.getZ(), player.getBoundingBox().expand(16));
                if (alpha != null && alpha.getProfile() == NpcProfile.ALPHATEMP) {
                    BlockPos target = world.getTopPosition(Heightmap.Type.MOTION_BLOCKING_NO_LEAVES,
                            BlockPos.ofFloored(player.getRotationVec(1f).multiply(18).add(player.getPos())));
                    IcebergBuilder.summon(world, target, world.getRandom());
                }
            }
            case "coco_extra" -> {
                if (player.getCommandTags().add("turbopapu_coco_extra")) {
                    player.giveItemStack(new ItemStack(ModItems.LECHE_DE_COCO, 2));
                }
            }
            default -> BossFight.onDialogueAction(player, action);
        }
    }
}
