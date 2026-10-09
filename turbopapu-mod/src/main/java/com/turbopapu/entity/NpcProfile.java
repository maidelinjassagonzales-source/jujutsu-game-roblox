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

    VERITY_GORDA("Verity Gorda", Formatting.YELLOW, true, true, false,
            List.of(
                    "¡Hola! :D Soy Verity, la pelota con cara... en versión GORDA. Vine rodando desde mi propio mod.",
                    "Juanma me hizo un asado de bienvenida. Me comí tres. Ahora ruedo más despacio.",
                    "Sualenidus dice que soy redonda. ¡Mira quién habla, con esa barriga! :)",
                    "Sonrío siempre. Hasta dormida. Por eso la lavanda no me afecta tanto... creo. :D",
                    "Cuando todo esto acabe hacemos fiesta. Como en Las Vegas. Nadie va a recordar nada."),
            world -> new ItemStack[0]),

    SUALENIDUS_AMIGO("Sualenidus", Formatting.LIGHT_PURPLE, true, true, false,
            List.of("Ya no duermo a nadie. Bueno, solo con mis historias de Valorant."),
            world -> new ItemStack[]{new ItemStack(net.minecraft.item.Items.ALLIUM, 8)}),

    AROY("Aroy", Formatting.GOLD, true, true, false,
            List.of("¡A mí me gusta el coco!"),
            world -> new ItemStack[]{new ItemStack(ModItems.LECHE_DE_COCO, 4)}),

    MUDOKON("Mudokon", Formatting.DARK_GREEN, true, true, false,
            List.of(
                    "¡Hola!",
                    "¡Vale!",
                    "*silbido*",
                    "¿Tú no eres un Slig, verdad? Uf, menos mal.",
                    "Alphatemp nos dejó vivir aquí después de escapar de RuptureFarms. ¡Nada de Mudokon Pops!",
                    "Alphatemp nos enseñó el iceberg de Oddworld. Nivel 1: Abe. Nivel 9: los huevos de Scrab... mejor no.",
                    "*se tira un pedo* ...Perdón."),
            world -> new ItemStack[0]),

    ABE("Abe", Formatting.GREEN, true, true, false,
            List.of(
                    "¡Hola! Soy Abe. Antes limpiaba suelos en RuptureFarms.",
                    "Sígueme. ...Espera, no, quédate ahí.",
                    "¿Sabes cuántos Mudokons rescaté? 99. ¿Y tú cuántos Turbopapuenses vas a rescatar?",
                    "Si ves un portal de pájaros, ¡sáltalo! Así escapamos nosotros.",
                    "Alphatemp es buena gente. Pero no bajes al sótano... ahí está el otro."),
            world -> new ItemStack[]{new ItemStack(net.minecraft.item.Items.FEATHER, 3)}),

    MAGO_LARGUIRUCHO("Mago Larguirucho", Formatting.DARK_PURPLE, true, true, false,
            List.of(
                    "¡Abracadabra... SALCHICHA!",
                    "Estudié 300 años de magia. Solo me sale un hechizo. Pero es el mejor."),
            world -> new ItemStack[]{new ItemStack(ModItems.SALCHICHA, 4)});

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
