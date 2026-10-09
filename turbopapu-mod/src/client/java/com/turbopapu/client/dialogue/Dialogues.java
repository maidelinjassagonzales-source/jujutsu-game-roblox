package com.turbopapu.client.dialogue;

import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.turbopapu.TurboPapuMod;
import net.minecraft.client.MinecraftClient;
import net.minecraft.resource.Resource;

import java.io.Reader;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Diálogos cargados de assets/turbopapu/dialogues/dialogues.json (mismo formato que LoyolaQuest):
 * cada clave es una lista de pasos {name, text, portrait, pw, ph, shake, music, photo}.
 * Las variantes se llaman clave_0, clave_1, ...
 */
public final class Dialogues {
    public record Step(String name, String text, String portrait, int pw, int ph, boolean shake, String music, String photo) {}

    private static Map<String, List<Step>> cache;

    private Dialogues() {}

    public static List<Step> get(String key) {
        if (cache == null) {
            load();
        }
        return cache.getOrDefault(key, List.of(new Step("Sistema", "(Falta el diálogo: " + key + ")", null, 0, 0, false, null, null)));
    }

    /** La clave exacta si existe; si no, la variante número {@code variant} de clave_0, clave_1, ... */
    public static List<Step> pick(String key, int variant) {
        if (cache == null) {
            load();
        }
        if (cache.containsKey(key)) {
            return cache.get(key);
        }
        List<String> variants = new ArrayList<>();
        while (cache.containsKey(key + "_" + variants.size())) {
            variants.add(key + "_" + variants.size());
        }
        if (variants.isEmpty()) {
            return get(key);
        }
        return cache.get(variants.get(Math.floorMod(variant, variants.size())));
    }

    public static void reload() {
        cache = null;
    }

    private static void load() {
        cache = new HashMap<>();
        Optional<Resource> resource = MinecraftClient.getInstance().getResourceManager()
                .getResource(TurboPapuMod.id("dialogues/dialogues.json"));
        if (resource.isEmpty()) {
            TurboPapuMod.LOGGER.error("No se encontró dialogues.json");
            return;
        }
        try (Reader reader = resource.get().getReader()) {
            JsonObject root = JsonParser.parseReader(reader).getAsJsonObject();
            for (Map.Entry<String, JsonElement> entry : root.entrySet()) {
                List<Step> steps = new ArrayList<>();
                JsonArray array = entry.getValue().getAsJsonArray();
                for (JsonElement e : array) {
                    JsonObject o = e.getAsJsonObject();
                    steps.add(new Step(
                            str(o, "name"), str(o, "text"), str(o, "portrait"),
                            o.has("pw") ? o.get("pw").getAsInt() : 0,
                            o.has("ph") ? o.get("ph").getAsInt() : 0,
                            o.has("shake") && o.get("shake").getAsBoolean(),
                            str(o, "music"), str(o, "photo")));
                }
                cache.put(entry.getKey(), steps);
            }
        } catch (Exception ex) {
            TurboPapuMod.LOGGER.error("Error leyendo dialogues.json", ex);
        }
    }

    private static String str(JsonObject o, String key) {
        return o.has(key) && !o.get(key).isJsonNull() ? o.get(key).getAsString() : null;
    }
}
