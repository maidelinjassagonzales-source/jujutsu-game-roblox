package com.turbopapu.world;

import com.turbopapu.registry.ModDimensions;
import net.fabricmc.fabric.api.event.lifecycle.v1.ServerTickEvents;
import net.minecraft.entity.effect.StatusEffectInstance;
import net.minecraft.entity.effect.StatusEffects;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtHelper;
import net.minecraft.registry.RegistryKey;
import net.minecraft.registry.tag.BiomeTags;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;

/** Lógica de la historia que corre cada segundo en el servidor. */
public final class TurboEvents {
    /** El meteorito cae cuando llevas este tiempo jugando (2 minutos). */
    public static final int METEOR_DELAY_TICKS = 20 * 120;

    private static int ticks;

    private TurboEvents() {}

    public static void register() {
        ServerTickEvents.END_SERVER_TICK.register(TurboEvents::onTick);
        net.fabricmc.fabric.api.entity.event.v1.ServerLivingEntityEvents.ALLOW_DEATH.register((entity, source, amount) -> {
            if (entity instanceof ServerPlayerEntity player && com.turbopapu.fight.BossFight.protects(player)) {
                com.turbopapu.fight.BossFight.onPlayerSaved(player);
                return false;
            }
            return true;
        });
    }

    private static final java.util.Set<java.util.UUID> MUSIC_PLAYERS = new java.util.HashSet<>();

    private static void onTick(MinecraftServer server) {
        com.turbopapu.fight.BossFight.tick(server);
        com.turbopapu.fight.PvzArcade.tick(server);
        GordoEvents.tick(server);
        if (++ticks % 20 != 0) {
            return;
        }
        tickAreaMusic(server);
        TurboState state = TurboState.get(server);
        ServerWorld overworld = server.getOverworld();

        for (ServerPlayerEntity player : overworld.getPlayers()) {
            if (player.isSpectator()) {
                continue;
            }
            if (!state.meteorFallen && !state.meteorIncoming && player.age > METEOR_DELAY_TICKS
                    && overworld.isSkyVisible(player.getBlockPos().up())) {
                MeteorEvent.launch(overworld, player);
            }
            if (state.meteorFallen && holdsHutCompass(player)) {
                showHutDistance(player, state);
            }
            ItemStack lairCompass = heldLairCompass(player);
            if (lairCompass != null && state.meteorFallen) {
                // La guarida está en el planeta: aquí la aguja lleva al meteorito, donde empieza el viaje.
                aimCompass(lairCompass, net.minecraft.world.World.OVERWORLD, state.meteorX, state.meteorY, state.meteorZ);
                player.sendMessage(Text.literal("La guarida de Sualenidus está en el planeta Turbopapu. La aguja te lleva al meteorito"
                        + " (X " + state.meteorX + ", Z " + state.meteorZ + "): construye el cohete.").formatted(Formatting.LIGHT_PURPLE), true);
            }
            if (state.meteorFallen && !state.guinxuBuilt && near(player, state.guinxuX, state.guinxuZ, 80)) {
                FriendBuilds.buildGuinxuStudio(overworld, state.guinxuX, state.guinxuZ);
                state.guinxuBuilt = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.elinkBuilt && near(player, state.elinkX, state.elinkZ, 80)) {
                FriendBuilds.buildElinkCastle(overworld, state.elinkX, state.elinkZ);
                state.elinkBuilt = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.magoSpawned && near(player, state.meteorX, state.meteorZ, 48)) {
                // El Mago Larguirucho llega atraído por el meteorito (y por el olor a salchicha).
                double a = overworld.getRandom().nextDouble() * Math.PI * 2;
                BlockPos spot = overworld.getTopPosition(net.minecraft.world.Heightmap.Type.MOTION_BLOCKING_NO_LEAVES,
                        BlockPos.ofFloored(state.meteorX + Math.cos(a) * 22, 64, state.meteorZ + Math.sin(a) * 22));
                Build.spawn(overworld, com.turbopapu.registry.ModEntities.MAGO_LARGUIRUCHO, spot.getX() + 0.5, spot.getY(), spot.getZ() + 0.5, 12);
                state.magoSpawned = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.gordoSpawned && near(player, state.meteorX, state.meteorZ, 48)) {
                // El Gordo Pañales se sienta cerca del meteorito a esperar su mantequilla.
                state.gordoX = state.meteorX - 26;
                state.gordoZ = state.meteorZ - 14;
                int gy = Build.surface(overworld, state.gordoX, state.gordoZ);
                Build.spawn(overworld, com.turbopapu.registry.ModEntities.GORDO_PANALES, state.gordoX + 0.5, gy, state.gordoZ + 0.5, 4);
                state.gordoSpawned = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.hutBuilt && near(player, state.hutX, state.hutZ, 80)) {
                OverworldBuilds.buildAlphatempHut(overworld, state.hutX, state.hutZ);
                state.hutBuilt = true;
                state.markDirty();
            }
            if (state.meteorFallen && !state.williamSpawned && ticks % 100 == 0
                    && overworld.getBiome(player.getBlockPos()).isIn(BiomeTags.IS_OCEAN)
                    && player.getY() > overworld.getSeaLevel() - 4) {
                if (OverworldBuilds.spawnWilliamRaft(overworld, player)) {
                    state.williamSpawned = true;
                    state.markDirty();
                }
            }
        }

        ServerWorld planet = server.getWorld(ModDimensions.PLANETA);
        if (planet != null) {
            for (ServerPlayerEntity player : planet.getPlayers()) {
                if (!state.lairBuilt && near(player, TurboState.LAIR_X, TurboState.LAIR_Z, 96)) {
                    PlanetBuilds.buildLair(planet, state);
                }
                RandomVillages.tick(planet, player, state);
                AvocadoGroves.tick(planet, player, state);
                ItemStack lairCompass = heldLairCompass(player);
                if (lairCompass != null && state.meteorFallen) {
                    aimCompass(lairCompass, ModDimensions.PLANETA, TurboState.LAIR_X, 80, TurboState.LAIR_Z);
                    showLairDistance(player);
                }
                if (state.lairBuilt && !state.sualenidusDefeated && near(player, TurboState.LAIR_X, TurboState.LAIR_Z, 45)
                        && player.getCommandTags().add("turbopapu_intro_sualenidus")) {
                    com.turbopapu.network.ModPackets.dialogue(player, "sualenidus_intro", 0, -1);
                }
                // Gravedad lunar: se salta más alto.
                if (!player.isSpectator()) {
                    player.addStatusEffect(new StatusEffectInstance(StatusEffects.JUMP_BOOST, 50, 1, true, false, true));
                }
            }
        }
    }

    /** La música de Oddworld suena cuando estás en la aldea Mudokon de Alphatemp. */
    private static void tickAreaMusic(MinecraftServer server) {
        TurboState state = TurboState.get(server);
        for (ServerPlayerEntity player : server.getPlayerManager().getPlayerList()) {
            boolean inOverworld = player.getWorld().getRegistryKey() == net.minecraft.world.World.OVERWORLD;
            boolean playing = MUSIC_PLAYERS.contains(player.getUuid());
            if (!playing && inOverworld && state.hutBuilt && near(player, state.hutX, state.hutZ, 40)) {
                MUSIC_PLAYERS.add(player.getUuid());
                com.turbopapu.network.ModPackets.music(player, "aldea_mudokon");
            } else if (playing && (!inOverworld || !near(player, state.hutX, state.hutZ, 60))) {
                MUSIC_PLAYERS.remove(player.getUuid());
                com.turbopapu.network.ModPackets.music(player, "");
            }
        }
    }

    private static boolean holdsHutCompass(ServerPlayerEntity player) {
        for (net.minecraft.item.ItemStack stack : new net.minecraft.item.ItemStack[]{player.getMainHandStack(), player.getOffHandStack()}) {
            if (stack.hasNbt() && stack.getNbt().getBoolean("TurboPapuChoza")) {
                return true;
            }
        }
        return false;
    }

    /** La brújula de la guarida (también las que se dieron antes de tener la marca: apuntan al planeta). */
    private static ItemStack heldLairCompass(ServerPlayerEntity player) {
        String planeta = ModDimensions.PLANETA.getValue().toString();
        for (ItemStack stack : new ItemStack[]{player.getMainHandStack(), player.getOffHandStack()}) {
            NbtCompound nbt = stack.getNbt();
            if (stack.isOf(Items.COMPASS) && nbt != null && (nbt.getBoolean("TurboPapuGuarida")
                    || (nbt.contains("LodestonePos") && planeta.equals(nbt.getString("LodestoneDimension"))
                    && NbtHelper.toBlockPos(nbt.getCompound("LodestonePos")).getX() == TurboState.LAIR_X))) {
                return stack;
            }
        }
        return null;
    }

    /** Hace que la aguja apunte a ese sitio de la dimensión en la que estás (si no, la brújula gira sin rumbo). */
    private static void aimCompass(ItemStack stack, RegistryKey<net.minecraft.world.World> dim, int x, int y, int z) {
        NbtCompound nbt = stack.getOrCreateNbt();
        String dimId = dim.getValue().toString();
        BlockPos target = new BlockPos(x, y, z);
        if (dimId.equals(nbt.getString("LodestoneDimension")) && nbt.contains("LodestonePos")
                && NbtHelper.toBlockPos(nbt.getCompound("LodestonePos")).equals(target)) {
            return;
        }
        nbt.put("LodestonePos", NbtHelper.fromBlockPos(target));
        nbt.putString("LodestoneDimension", dimId);
        nbt.putBoolean("LodestoneTracked", false);
        nbt.putBoolean("TurboPapuGuarida", true);
    }

    /** En el planeta: distancia y dirección a la guarida de Sualenidus encima de la barra de objetos. */
    private static void showLairDistance(ServerPlayerEntity player) {
        double dx = TurboState.LAIR_X + 0.5 - player.getX();
        double dz = TurboState.LAIR_Z + 0.5 - player.getZ();
        int dist = (int) Math.sqrt(dx * dx + dz * dz);
        if (dist < 20) {
            player.sendMessage(Text.literal("¡Estás en la guarida de Sualenidus!").formatted(Formatting.LIGHT_PURPLE), true);
            return;
        }
        String[] dirs = {"sur", "suroeste", "oeste", "noroeste", "norte", "noreste", "este", "sureste"};
        double angle = Math.toDegrees(Math.atan2(-dx, dz));
        String dir = dirs[Math.floorMod((int) Math.round(angle / 45.0), 8)];
        player.sendMessage(Text.literal("Guarida de Sualenidus: " + dist + " bloques al " + dir
                + "  (X " + TurboState.LAIR_X + ", Z " + TurboState.LAIR_Z + ")").formatted(Formatting.LIGHT_PURPLE), true);
    }

    /** Con la brújula en la mano: distancia y dirección a la choza de Alphatemp encima de la barra de objetos. */
    private static void showHutDistance(ServerPlayerEntity player, TurboState state) {
        double dx = state.hutX + 0.5 - player.getX();
        double dz = state.hutZ + 0.5 - player.getZ();
        int dist = (int) Math.sqrt(dx * dx + dz * dz);
        if (dist < 12) {
            player.sendMessage(net.minecraft.text.Text.literal("¡Has llegado a la choza de Alphatemp!")
                    .formatted(net.minecraft.util.Formatting.AQUA), true);
            return;
        }
        String[] dirs = {"sur", "suroeste", "oeste", "noroeste", "norte", "noreste", "este", "sureste"};
        double angle = Math.toDegrees(Math.atan2(-dx, dz));
        String dir = dirs[Math.floorMod((int) Math.round(angle / 45.0), 8)];
        player.sendMessage(net.minecraft.text.Text.literal("Choza de Alphatemp: " + dist + " bloques al " + dir
                + "  (X " + state.hutX + ", Z " + state.hutZ + ")").formatted(net.minecraft.util.Formatting.AQUA), true);
    }

    private static boolean near(ServerPlayerEntity player, int x, int z, int dist) {
        double dx = player.getX() - x;
        double dz = player.getZ() - z;
        return dx * dx + dz * dz < (double) dist * dist;
    }
}
