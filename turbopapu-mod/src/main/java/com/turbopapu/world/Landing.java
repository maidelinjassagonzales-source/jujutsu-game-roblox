package com.turbopapu.world;

import com.turbopapu.entity.RocketEntity;
import com.turbopapu.entity.TurboPapuenseEntity;
import com.turbopapu.network.ModPackets;
import com.turbopapu.registry.ModEntities;
import net.minecraft.block.Blocks;
import net.minecraft.entity.decoration.ArmorStandEntity;
import net.minecraft.item.ItemStack;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.server.network.ServerPlayerEntity;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;

import java.util.List;

/**
 * Cinemática de llegada al Planeta TurboPapu: el cohete baja del cielo hasta la pista de aterrizaje
 * de la aldea mientras una cámara lo sigue desde el suelo. Al aterrizar, los Turbopapuenses
 * despiertos se acercan, te dan la bienvenida y señalan la guarida de Sualenidus.
 */
public final class Landing {
    public static final double PAD_X = 0.5, PAD_Z = 10.5;

    private Landing() {}

    public static void start(ServerPlayerEntity player, ServerWorld planet, TurboState state) {
        int groundY = state.villageY;
        buildPad(planet, groundY);
        double startY = groundY + 85;
        player.teleport(planet, PAD_X, startY + 1, PAD_Z, 180f, 0f);

        RocketEntity rocket = ModEntities.ROCKET.create(planet);
        if (rocket == null) {
            return;
        }
        rocket.refreshPositionAndAngles(PAD_X, startY, PAD_Z, 0, 0);
        rocket.startLanding(groundY, player);
        planet.spawnEntity(rocket);

        // Cámara en el suelo, a un lado de la pista, mirando hacia arriba.
        ArmorStandEntity cam = new ArmorStandEntity(planet, PAD_X + 9, groundY + 3, PAD_Z + 8);
        NbtCompound tag = new NbtCompound();
        cam.writeCustomDataToNbt(tag);
        tag.putBoolean("Marker", true);
        tag.putBoolean("Invisible", true);
        tag.putBoolean("NoGravity", true);
        cam.readCustomDataFromNbt(tag);
        cam.setInvisible(true);
        cam.setNoGravity(true);
        cam.addCommandTag("turbopapu_camara");
        planet.spawnEntity(cam);
        rocket.camera = cam;
        ModPackets.landing(player, rocket.getId(), cam.getId());
    }

    /** Pista de aterrizaje con franjas amarillas y negras en la plaza. */
    private static void buildPad(ServerWorld world, int y0) {
        int cx = (int) Math.floor(PAD_X), cz = (int) Math.floor(PAD_Z);
        for (int x = -2; x <= 2; x++) {
            for (int z = -2; z <= 2; z++) {
                boolean edge = Math.abs(x) == 2 || Math.abs(z) == 2;
                Build.set(world, cx + x, y0 - 1, cz + z, edge ? ((x + z) % 2 == 0 ? Blocks.YELLOW_CONCRETE : Blocks.BLACK_CONCRETE) : Blocks.GRAY_CONCRETE);
            }
        }
        Build.set(world, cx, y0 - 1, cz, Blocks.WHITE_CONCRETE);
    }

    public static void arrive(ServerPlayerEntity player, RocketEntity rocket) {
        ServerWorld world = (ServerWorld) player.getWorld();
        TurboState state = TurboState.get(world.getServer());
        ModPackets.landing(player, -1, -1);
        player.fallDistance = 0;
        player.teleport(world, rocket.getX() + 2.5, rocket.getY(), rocket.getZ(), 180f, 0f);

        // Los Turbopapuenses despiertos corren a recibirte y miran hacia la guarida.
        List<TurboPapuenseEntity> papus = world.getEntitiesByClass(TurboPapuenseEntity.class,
                rocket.getBoundingBox().expand(40), p -> !p.isDormido());
        TurboPapuenseEntity speaker = null;
        int i = 0;
        for (TurboPapuenseEntity papu : papus) {
            double a = i++ * 0.9;
            papu.getNavigation().startMovingTo(rocket.getX() + Math.cos(a) * 3, rocket.getY(), rocket.getZ() + Math.sin(a) * 3, 1.3);
            if (speaker == null) {
                speaker = papu;
            }
        }
        ModPackets.dialogue(player, state.sualenidusDefeated ? "llegada_paz" : "llegada", 0, speaker == null ? -1 : speaker.getId());
        player.sendMessage(Text.translatable("message.turbopapu.arrived").formatted(Formatting.GOLD, Formatting.BOLD), false);
        if (!state.sualenidusDefeated) {
            player.sendMessage(Text.literal("La guarida de Sualenidus está en X " + TurboState.LAIR_X + ", Z " + TurboState.LAIR_Z
                    + " (sigue el rayo morado del cielo).").formatted(Formatting.LIGHT_PURPLE), false);
            if (player.getCommandTags().add("turbopapu_brujula_planeta")) {
                ItemStack compass = Books.lairCompass(world);
                compass.setCustomName(Text.literal("Brújula Turbopapuense (guarida)").formatted(Formatting.LIGHT_PURPLE));
                player.giveItemStack(compass);
            }
        }
    }

    /** Mira hacia la guarida (lo usan los Turbopapuenses para "señalarla"). */
    public static float yawToLair(double x, double z) {
        double dx = TurboState.LAIR_X - x, dz = TurboState.LAIR_Z - z;
        return (float) (Math.atan2(dz, dx) * 180 / Math.PI) - 90f;
    }
}
