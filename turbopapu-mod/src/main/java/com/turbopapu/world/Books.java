package com.turbopapu.world;

import com.turbopapu.registry.ModDimensions;
import net.minecraft.item.ItemStack;
import net.minecraft.item.Items;
import net.minecraft.nbt.NbtCompound;
import net.minecraft.nbt.NbtHelper;
import net.minecraft.nbt.NbtList;
import net.minecraft.nbt.NbtOps;
import net.minecraft.nbt.NbtString;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.text.Text;
import net.minecraft.util.Formatting;
import net.minecraft.util.math.BlockPos;
import net.minecraft.world.World;

public final class Books {
    private Books() {}

    public static ItemStack writtenBook(String title, String author, String... pages) {
        ItemStack book = new ItemStack(Items.WRITTEN_BOOK);
        NbtCompound nbt = book.getOrCreateNbt();
        nbt.putString("title", title);
        nbt.putString("author", author);
        NbtList list = new NbtList();
        for (String page : pages) {
            list.add(NbtString.of(Text.Serializer.toJson(Text.literal(page))));
        }
        nbt.put("pages", list);
        nbt.putBoolean("resolved", true);
        return book;
    }

    /** Instrucciones para construir el cohete. Incluye las coordenadas de la choza de Alphatemp. */
    public static ItemStack rocketPlans(TurboState state) {
        return writtenBook("Planos del Cohete", "Los Turbopapuenses",
                "PLANOS DEL COHETE\n\nPara viajar al Planeta TurboPapu necesitas 5 piezas:\n\n1. Casco del Cohete\n2. Motor Turbo\n3. Combustible Papu\n4. Núcleo de Iceberg\n5. Mapa Estelar",
                "1. CASCO DEL COHETE\n\n  H\nH B H\nH B H\n\nH = lingote de hierro\nB = bloque de hierro",
                "2. MOTOR TURBO\n\nM R M\nM A M\nM   M\n\nM = fragmento de meteorito\nR = bloque de redstone\nA = alto horno",
                "3. COMBUSTIBLE PAPU\n(sin forma)\n\n2 polvo de blaze\n1 bloque de carbón\n1 fragmento de meteorito\n1 cubo de lava",
                "4. NÚCLEO DE ICEBERG\n\nTe lo dará ALPHATEMP. Vive en una choza estilo Mudokon cerca de:\n\nX: " + state.hutX + "\nZ: " + state.hutZ + "\n\nLa brújula del cofre apunta allí. Cuidado con el sótano...",
                "5. MAPA ESTELAR\n\nLo tiene WILLIAM_PIRATON, un pez pirata retirado que navega por el MAR. Explora los océanos hasta encontrar su balsa.",
                "EL COHETE\n(sin forma)\n\nCasco + Motor + Combustible + Núcleo de Iceberg + Mapa Estelar\n\nColócalo en el suelo, súbete con clic derecho y... ¡TURBO PAPU!",
                "En el planeta te esperan los pocos que siguen despiertos.\n\nGuárdate el cohete: al llegar te lo devolvemos para volver a casa.\n\n¡Te esperamos!\n- Los Turbopapuenses");
    }

    /** Brújula que apunta a la choza Mudokon de Alphatemp (va en el cofre del meteorito). */
    public static ItemStack hutCompass(ServerWorld world, TurboState state) {
        ItemStack compass = new ItemStack(Items.COMPASS);
        NbtCompound nbt = compass.getOrCreateNbt();
        nbt.put("LodestonePos", NbtHelper.fromBlockPos(new BlockPos(state.hutX, 64, state.hutZ)));
        World.CODEC.encodeStart(NbtOps.INSTANCE, World.OVERWORLD).result()
                .ifPresent(dim -> nbt.put("LodestoneDimension", dim));
        nbt.putBoolean("LodestoneTracked", false);
        nbt.putBoolean("TurboPapuChoza", true);
        compass.setCustomName(Text.literal("Brújula a la choza de Alphatemp").formatted(Formatting.AQUA));
        NbtList lore = new NbtList();
        lore.add(NbtString.of(Text.Serializer.toJson(Text.literal("Apunta a la choza Mudokon de Alphatemp").formatted(Formatting.GRAY))));
        lore.add(NbtString.of(Text.Serializer.toJson(Text.literal("X: " + state.hutX + "  Z: " + state.hutZ).formatted(Formatting.YELLOW))));
        lore.add(NbtString.of(Text.Serializer.toJson(Text.literal("Llévala en la mano para ver la distancia").formatted(Formatting.DARK_GRAY))));
        compass.getOrCreateSubNbt("display").put("Lore", lore);
        return compass;
    }

    /** La Brújula Despeinada de Guinxu: apunta a la guarida de Sualenidus. */
    public static ItemStack lairCompass(ServerWorld world) {
        ItemStack compass = new ItemStack(Items.COMPASS);
        NbtCompound nbt = compass.getOrCreateNbt();
        nbt.put("LodestonePos", NbtHelper.fromBlockPos(new BlockPos(TurboState.LAIR_X, 80, TurboState.LAIR_Z)));
        World.CODEC.encodeStart(NbtOps.INSTANCE, ModDimensions.PLANETA).result()
                .ifPresent(dim -> nbt.put("LodestoneDimension", dim));
        nbt.putBoolean("LodestoneTracked", false);
        compass.setCustomName(Text.literal("Brújula Despeinada de Guinxu").formatted(Formatting.YELLOW));
        return compass;
    }
}
