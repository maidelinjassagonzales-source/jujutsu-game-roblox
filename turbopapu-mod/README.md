# TurboPapu: El Planeta Dormido

Mod de Minecraft (**Fabric 1.20.1**) inspirado en la comunidad de [TurboPapu](https://www.twitch.tv/turbopapu778).
Fan-mod sin ánimo de lucro.

## La historia

1. **El meteorito.** A los 2 minutos de jugar, un meteorito cae del cielo cerca de ti. Hay **cinemática**
   (bandas de cine, la cámara sigue al meteorito y la pantalla tiembla al impactar).
2. **La carta.** Al caer aparece una carta al estilo de la de Peach en *Super Mario 64*: los **Turbopapuenses**
   piden ayuda. En su planeta ha aparecido **Sualenidus**, un gordo enorme con una barriga que no para de crecer,
   que habla sin parar de armas de Valorant, huele a lavanda y se ríe como un loco. Por su culpa casi todos se están
   quedando dormidos.
3. **El cofre.** Dentro del meteorito hay un cofre con la *Carta de Auxilio*, el libro **Planos del Cohete** y
   fragmentos de meteorito.
4. **Alphatemp.** Vive en una choza de barro estilo Oddworld/Mudokon (~180 bloques al este del meteorito; las
   coordenadas exactas vienen en el libro). Te da el **Núcleo de Iceberg** y unos **Icebergs de Bolsillo**.
   Le encanta FNAF y a veces invoca icebergs enormes. En el sótano está **Alphafaterfur**, su versión malvada,
   que lleva grabando un video de 2 horas desde 2024. No le interrumpas.
5. **William_Piraton.** Un pez pirata naranja (como un palito de pescado) retirado de los directos con aroy24.
   Aparece en una balsa cuando navegas por el **océano**. Te da el **Mapa Estelar**.
6. **El cohete.** Casco + Motor Turbo + Combustible Papu + Núcleo de Iceberg + Mapa Estelar. Colócalo, súbete
   con clic derecho y... ¡despegue! (cuenta atrás + viaje espacial con el planeta TurboPapu, que tiene ojos y boca).
7. **El Planeta TurboPapu.** Una dimensión propia con cielo morado. En la aldea te reciben los pocos despiertos:
   - **Juanma**, profesor de economía: en otro universo odia a los argentinos, en este los ama (por eso vive aquí,
     son todos argentinos). Te da **mate**, que te despierta y te protege del sueño.
   - **Guinxu** y su pelo loco: te da la **Brújula Despeinada** que apunta a la guarida.
   - **elink_64**, el streamer olvidado de Machala (¿o Perú?), fan de Mario 64 y Michael Jackson: hace el moonwalk
     y te da **Estrellas de Poder**.
   - **Verity Gorda**: Verity (la pelota amarilla con cara sonriente) en versión gorda, invitada desde el mod de Verity.
   - Turbopapuenses despiertos y muchos dormidos.
8. **Sualenidus.** En su guarida de purpur rodeada de lavanda. 400 de vida, barra de jefe, barriga que crece.
   Ataques: **Nube de lavanda** (te deja DORMIDO: casi no te mueves y recibes el doble de daño), **Barrigazo** y
   risas con frases de Valorant. En la segunda fase ataca más rápido. Consejo: mate + icebergs de bolsillo.
9. **El final.** Al vencerle todos despiertan, hay fuegos artificiales y un final al estilo **Resacón en Las
   Vegas**: las fotos de la fiesta que nadie recuerda durante los créditos.

## Compilar y jugar

Necesitas **Java 17+**.

```bash
cd turbopapu-mod
./gradlew build        # el .jar sale en build/libs/
./gradlew runClient    # abre Minecraft con el mod para probar
```

Copia `build/libs/turbopapu-0.1.0.jar` a tu carpeta `mods/` junto con
[Fabric API](https://modrinth.com/mod/fabric-api) (Fabric Loader 0.15+, Minecraft 1.20.1).

GitHub Actions compila el mod automáticamente en cada push (`.github/workflows/turbopapu-mod.yml`) y deja el
`.jar` como artefacto descargable.

## Comandos de prueba (OP)

| Comando | Qué hace |
|---|---|
| `/turbopapu meteorito` | Lanza el meteorito ya |
| `/turbopapu carta` | Abre la carta |
| `/turbopapu viajar` / `volver` | Viaja al planeta / vuelve |
| `/turbopapu final` | Muestra el final |
| `/turbopapu estado` | Muestra el progreso de la historia |

También hay huevos de invocación de todos los personajes en la pestaña creativa **TurboPapu**.

## Texturas

Todas las texturas son pixel art generado por `tools/generate_textures.py` (`python3 tools/generate_textures.py`).
Para dar un aspecto más fiel a cada personaje (por ejemplo, con las fotos de Juanma), reemplaza los PNG en
`src/main/resources/assets/turbopapu/textures/entity/` por los tuyos con el mismo tamaño (64x64, formato skin).

## Junto al mod de Verity

Verity Gorda es una entidad propia (`turbopapu:verity_gorda`) y no depende del mod de Verity, así que ambos mods
pueden instalarse juntos. Si el mod de Verity usa otro loader (Forge/NeoForge) o versión, habrá que portar uno de
los dos para que convivan.

## Estructura

```
src/main/java/com/turbopapu/
  entity/   Turbopapuense, NPCs (NpcProfile: diálogos y regalos), Sualenidus, Meteorito, Cohete
  world/    Historia (TurboEvents/TurboState), meteorito, construcciones, viajes, icebergs
  item/     Cohete, carta, mate, estrella de poder, iceberg de bolsillo
src/client/java/com/turbopapu/client/
  model/ render/   Modelos y renderizadores
  screen/          Carta Mario 64, viaje espacial, final estilo Resacón
src/main/resources/data/turbopapu/
  dimension/ dimension_type/ worldgen/biome/   El Planeta TurboPapu
  recipes/                                     Recetas del cohete
```
