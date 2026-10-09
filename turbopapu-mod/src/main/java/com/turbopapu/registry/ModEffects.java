package com.turbopapu.registry;

import com.turbopapu.TurboPapuMod;
import com.turbopapu.effect.TurboEffect;
import net.minecraft.entity.attribute.EntityAttributeModifier;
import net.minecraft.entity.attribute.EntityAttributes;
import net.minecraft.entity.effect.StatusEffect;
import net.minecraft.entity.effect.StatusEffectCategory;
import net.minecraft.registry.Registries;
import net.minecraft.registry.Registry;

public final class ModEffects {
    /** El sueño de lavanda de Sualenidus: casi no te puedes mover y recibes el doble de daño. */
    public static final StatusEffect DORMIDO = new TurboEffect(StatusEffectCategory.HARMFUL, 0xB57EDC)
            .addAttributeModifier(EntityAttributes.GENERIC_MOVEMENT_SPEED,
                    "7107DE5E-7CE8-4030-940E-514C1F160890", -0.85, EntityAttributeModifier.Operation.MULTIPLY_TOTAL)
            .addAttributeModifier(EntityAttributes.GENERIC_ATTACK_SPEED,
                    "55FCED67-E92A-486E-9800-B47F202C4386", -0.6, EntityAttributeModifier.Operation.MULTIPLY_TOTAL);

    /** Efecto del mate de Juanma: inmune al sueño de lavanda. */
    public static final StatusEffect DESPIERTO = new TurboEffect(StatusEffectCategory.BENEFICIAL, 0x4CAF50);

    /** Mantequilla en los pies: te deslizas muy rápido (el empujón lo da el cliente, ver TurboPapuClient). */
    public static final StatusEffect UNTADO = new TurboEffect(StatusEffectCategory.BENEFICIAL, 0xFFE066);

    private ModEffects() {}

    public static void register() {
        Registry.register(Registries.STATUS_EFFECT, TurboPapuMod.id("dormido"), DORMIDO);
        Registry.register(Registries.STATUS_EFFECT, TurboPapuMod.id("despierto"), DESPIERTO);
        Registry.register(Registries.STATUS_EFFECT, TurboPapuMod.id("untado"), UNTADO);
    }
}
