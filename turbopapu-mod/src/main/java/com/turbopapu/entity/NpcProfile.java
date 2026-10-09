package com.turbopapu.entity;

import com.turbopapu.registry.ModItems;
import com.turbopapu.world.Books;
import net.minecraft.entity.EntityType;
import net.minecraft.item.ItemStack;
import net.minecraft.server.world.ServerWorld;
import net.minecraft.util.Formatting;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Function;

/**
 * Datos de cada personaje: nombre, color, diálogos y el regalo que te dan la primera vez que hablas con ellos.
 * Los textos están en español directamente para que sea fácil editarlos.
 */
public enum NpcProfile {
    ALPHATEMP("Alphatemp", Formatting.AQUA, true, true, false,
            List.of(
                    "¡Hey! Soy Alphatemp. Bienvenido a mi choza... estilo Mudokon, sí. Me la decoró un amigo de Oddworld.",
                    "¿Sabías que TODO tiene un iceberg? Minecraft, FNAF, las tostadoras... TODO.",
                    "Nivel 1 del iceberg de FNAF: Freddy da miedo. Nivel 9: Freddy paga impuestos.",
                    "¿Vas a ir al Planeta TurboPapu? Toma este Núcleo de Iceberg. Sin él tu cohete no aguanta el frío del espacio.",
                    "Abajo hay un sótano... ahí está Alphafaterfur, mi versión malvada. No le interrumpas. En serio.",
                    "Si Sualenidus te molesta, ¡tírale un iceberg encima! Te regalo unos de bolsillo."),
            world -> new ItemStack[]{new ItemStack(ModItems.NUCLEO_ICEBERG), new ItemStack(ModItems.ICEBERG_DE_BOLSILLO, 3)}),

    ALPHAFATERFUR("Alphafaterfur", Formatting.DARK_RED, false, false, true,
            List.of(
                    "Shhh... estoy grabando. Llevo grabando ESTE video desde 2024.",
                    "Dura 2 horas. Bueno... 2 horas desde hace dos años. El render no termina nunca.",
                    "Alphatemp hace icebergs. Yo hago... otras cosas. Cosas MALVADAS. Como no poner timestamps.",
                    "¡Si me vuelves a interrumpir te vas a enterar!"),
            world -> new ItemStack[0]),

    WILLIAM_PIRATON("William_Piraton", Formatting.GOLD, true, false, false,
            List.of(
                    "¡Arrr! William_Piraton, para servirte. Pez, pirata y ex-streamer.",
                    "Antes hacía directos con aroy24... qué tiempos. Ahora me he retirado al mar.",
                    "¿Que vas al Planeta TurboPapu? Necesitarás un Mapa Estelar. Toma el mío, yo ya no viajo.",
                    "No, no soy un palito de pescado. Soy NARANJA, que es distinto.",
                    "Si ves a aroy24, dile que el parche del ojo es por estilo, no por el directo de 2021."),
            world -> new ItemStack[]{new ItemStack(ModItems.MAPA_ESTELAR)}),

    JUANMA("Juanma", Formatting.BLUE, true, true, false,
            List.of(
                    "¡Buenas! Soy Juanma, profesor de economía. Bienvenido al Planeta TurboPapu.",
                    "En otro universo no soportaba a los argentinos... ¡pero en ESTE universo los amo! Por eso vivo acá: son todos argentinos, che.",
                    "Lección del día: si Sualenidus te duerme, tu productividad cae al 0%. Tomá mate.",
                    "La inflación en este planeta es de un 300%... de sueño. Todo por culpa de Sualenidus.",
                    "Tomá unos mates, pibe. Te mantienen despierto contra la lavanda de ese gordo."),
            world -> new ItemStack[]{new ItemStack(ModItems.MATE, 6)}),

    GUINXU("Guinxu", Formatting.YELLOW, true, true, false,
            List.of(
                    "¡Ey! Soy Guinxu. Sí, el pelo es así de natural. No, no se despeina ni en el espacio.",
                    "Estaba haciendo un juego en 48 horas y aparecí aquí. Típico.",
                    "La guarida de Sualenidus está lejos, al noreste. Mi brújula te lleva directo.",
                    "Toma mi Brújula Despeinada. Apunta siempre a la guarida... y a veces a mi peluquero.",
                    "Cuando derrotes a Sualenidus hacemos un juego sobre esto. Lo tengo clarísimo."),
            world -> new ItemStack[]{Books.lairCompass(world)}),

    ELINK_64("elink_64", Formatting.RED, true, true, false,
            List.of(
                    "¡It's-a me, elink_64! El streamer que el internet olvidó... pero el Planeta TurboPapu no.",
                    "¡Saludos desde Machala! ¿O era Perú? Ya ni me acuerdo, llevo años aquí.",
                    "Super Mario 64 es el mejor juego de la historia. Y Michael Jackson el mejor cantante. ¡Hee-hee!",
                    "Toma estas Estrellas de Poder. ¡Here we go! Úsalas si Sualenidus te pega muy fuerte.",
                    "*hace el moonwalk* ¡Auuu!"),
            world -> new ItemStack[]{new ItemStack(ModItems.ESTRELLA_DE_PODER, 3)}),

    VERITY_GORDA("Verity Gorda", Formatting.LIGHT_PURPLE, true, true, false,
            List.of(
                    "¡Hola! Soy Verity... en mi versión gorda. Vine desde mi propio mod a ayudar.",
                    "Juanma me hizo un asado de bienvenida. Me comí tres. Las vacas del planeta me odian.",
                    "Sualenidus tiene más barriga que yo. Y eso que yo tengo MUCHA.",
                    "Cuando todo esto acabe hacemos fiesta. Como en Las Vegas. Nadie va a recordar nada."),
            world -> new ItemStack[0]);

    private static final Map<EntityType<?>, NpcProfile> BY_TYPE = new HashMap<>();

    public final String displayName;
    public final Formatting color;
    public final boolean invulnerable;
    public final boolean wanders;
    public final boolean hostileWhenHit;
    public final List<String> lines;
    private final Function<ServerWorld, ItemStack[]> gifts;

    NpcProfile(String displayName, Formatting color, boolean invulnerable, boolean wanders, boolean hostileWhenHit,
               List<String> lines, Function<ServerWorld, ItemStack[]> gifts) {
        this.displayName = displayName;
        this.color = color;
        this.invulnerable = invulnerable;
        this.wanders = wanders;
        this.hostileWhenHit = hostileWhenHit;
        this.lines = lines;
        this.gifts = gifts;
    }

    public ItemStack[] gifts(ServerWorld world) {
        return gifts.apply(world);
    }

    public String textureName() {
        return name().toLowerCase(java.util.Locale.ROOT);
    }

    public static void bind(EntityType<?> type, NpcProfile profile) {
        BY_TYPE.put(type, profile);
    }

    public static NpcProfile of(EntityType<?> type) {
        return BY_TYPE.getOrDefault(type, ALPHATEMP);
    }
}
