package com.turbopapu.fight;

/**
 * Las "plantas" del Plantas vs Zombies final: los amigos que has conocido por el camino.
 * Coste en soles, recarga en ticks y vida.
 */
public enum PvzPlantType {
    TURBOPAPUENSE("Turbopapuense", 50, 150, 30, "Da soles (girasol)"),
    ALPHATEMP("Alphatemp", 100, 150, 30, "Lanza hielo que ralentiza"),
    GUINXU("Guinxu", 175, 150, 30, "Dispara dos veces (repetidor)"),
    MUDOKON("Mudokon", 50, 500, 160, "Aguanta mucho (nuez)"),
    AROY("Aroy", 150, 300, 30, "Cañón de coco: mucho daño"),
    JUANMA("Juanma", 125, 200, 30, "Lanza mate con salpicadura"),
    ELINK_64("elink_64", 150, 900, 30, "¡Explota! (petazeta)"),
    VERITY_GORDA("Verity Gorda", 100, 400, 30, "Rueda por la fila (nuez bolera)"),
    MAGO_LARGUIRUCHO("Mago Larguirucho", 125, 200, 30, "Abre un agujero y lanza salchichas");

    public final String displayName;
    public final int cost;
    public final int cooldown;
    public final int health;
    public final String description;

    PvzPlantType(String displayName, int cost, int cooldown, int health, String description) {
        this.displayName = displayName;
        this.cost = cost;
        this.cooldown = cooldown;
        this.health = health;
        this.description = description;
    }

    public static PvzPlantType byId(int id) {
        PvzPlantType[] values = values();
        return values[Math.floorMod(id, values.length)];
    }
}
