# Memoria del proyecto (para Claude)

Este archivo resume todo lo hecho en las sesiones anteriores para poder seguir trabajando sin perder contexto.
Habla con el usuario en **español**, de forma corta y clara (pide no gastar muchos tokens).

## Qué hay en el repo
- `turbopapu-mod/`: mod de **Minecraft 1.20.1 con Fabric** (Java 17, loom). Es el proyecto principal.
- `*.rbxl`: archivos viejos de un juego de Roblox (no se tocan).
- Rama de trabajo: `claude/minecraft-mod-check-v3idlv` (sale de `claude/confident-brown-wl698m`, que tiene la historia anterior del mod).
- CI: `.github/workflows/turbopapu-mod.yml` compila con `./gradlew build` en cada push que toque `turbopapu-mod/**` y sube el artefacto `turbopapu-mod` (el .jar). En la nube no se podía compilar en local (maven.fabricmc.net bloqueado), así que se validaba con el CI. En local sí debería funcionar `cd turbopapu-mod && ./gradlew build`.
- Las texturas se dibujan con Python + Pillow (PIL) píxel a píxel.

## Estructura del código (`turbopapu-mod/src`)
- `main/java/com/turbopapu/`
  - `entity/PapuNpcEntity.java`: todos los NPC con diálogo. Su comportamiento depende de `NpcProfile` (enum con nombre, color, regalos). Aquí está la lógica especial: Alphatemp (icebergs), elink_64 (moonwalk), Mago Larguirucho (agujero de salchichas), Gordo Pañales (darle mantequilla), Chamán Cocoide, Aroy (entrar/salir de la lata), Sualenidus amigo (PvZ por niveles), conversión del Gordo Rubio viejo en Gordo Pañales.
  - `registry/`: `ModEntities` (tipos + `NpcProfile.bind`), `ModItems`, `ModEffects`, `ModDimensions`, `ModBlocks`.
  - `world/TurboEvents.java`: el tick principal del servidor (cada tick: BossFight, PvzArcade, GordoEvents, CocoideRitual; cada 20 ticks: generación de cosas al acercarse, etc.).
  - `world/TurboState.java`: estado guardado del mundo (PersistentState). Todo lo nuevo que se guarde va aquí (leer y escribir NBT).
  - `fight/`: pelea final contra Sualenidus (`BossFight`), Plantas vs Zombies (`PvzGame`, `PvzPlantType`, `Arenas`) y modo libre por niveles (`PvzArcade`).
  - `network/ModPackets.java` y `DialogueActions.java`: paquetes y acciones de las opciones de diálogo (`"action"` en el JSON).
- `client/java/com/turbopapu/client/`: renderers, modelos, `FightHud`, `PvzScreen`, `CinematicController` (cámara que sigue una entidad, con texto propio), `GordoClient` (screamer, deslizarse con mantequilla, rebote del pañal, tecla G).
- `main/resources/assets/turbopapu/dialogues/dialogues.json`: todos los diálogos. Claves `<npc>_intro` (primera vez) y `<npc>_charla_N` (variantes). Pasos con `name`, `text`, `options` (`text`, `goto`, `action`).
- `main/resources/data/turbopapu/dimension*/`: dimensiones por datapack.

## Lo que se ha añadido (en orden)
1. **Brújula de Guinxu** arreglada: se re-apunta cada tick según la dimensión (en el planeta a la guarida, en el mundo normal al meteorito) y muestra distancia.
2. **Mago Larguirucho**: alto y flaco, aparece cerca del meteorito; abre un agujero 3x3 del que salen **salchichas vivas** (`SalchichaEntity`), el suelo se restaura. También es planta del PvZ.
3. **Pelea final arreglada**: Sualenidus se perdía al teletransportarlo a chunks sin cargar (por eso no salían las almas de Deltarune ni las oleadas). Ahora `moveBoss` carga el destino con un ticket y si desaparece se re-crea. Los Sualems no desaparecen en Pacífico.
4. **PvZ modo libre**: tras vencer a Sualenidus, hablar con Sualenidus amigo → 5 niveles con **zombies normales** (`ZOMBI_PVZ`). Cada nivel desbloquea el siguiente. ESC sale. Comando `/turbopapu pvz <nivel>`.
5. **Gordo Pañales**: profe de su **Centro de FP de Jardinería** (uno fijo a meteorito −130 X, −90 Z, y otros aleatorios). Nos odia porque queremos sacarnos su FP; hay que darle **mantequilla 1 vez por día de Minecraft** (mantequilla = cubo de leche en la mesa → 4). Si un día no se la das: **screamer** y te come → **mundo estomacal** (dimensión `estomago_gordo`), se sale subiendo por las costillas a la garganta.
   - Mantequilla con clic derecho = **te deslizas muy rápido** (efecto `untado`).
   - 10 mantequillas en total → te regala el **Pañal**; puesto, tecla **G** = cagarse encima (asquea y aparta a todos).
   - Tras cagarse, el **pañal cagado rebota** (sin daño por caída, mantener saltar para subir); **15 rebotes seguidos** → **Mundo de Caca** (`mundo_caca`) donde vive **Verity de Caca**, que te devuelve a casa.
6. **Aguacate Cubano**: arboledas de aguacateros en el Planeta TurboPapu; siempre dice "¡Pinga asere!" y regala un aguacate.
7. **Gordo Rubio**: se creó y luego el usuario pidió **sustituirlo por el Gordo Pañales** (los que existan se convierten solos). Ya no tiene huevo.
8. **Mundo de la lata de coco de Aroy** (`lata_de_coco`): agacharse + clic derecho en Aroy para entrar. Mar de agua de coco (bioma `agua_de_coco`), islas con palmeras y cocos (cacao). El Aroy de la isla de llegada te saca.
9. **Capítulo 1 (final)**:
   - En la lata viven los **Cocoides**. Lejos al **este** (X 640) está la **isla con forma de Cuba** con el **edificio espectral** y el **Chamán Cocoide**.
   - Ritual: **Plátanos de Canarias** (cofre del huerto de la FP), **Aguacate cubano**, **Mate argentino** (Juanma) y **Mantequilla**. El chamán dice "¡Asere, tú sí que sabes!".
   - Cinemática (`CocoideRitual`): ofrendas girando, rayos, baja un **Gordo gigante** (`GORDO_JEFE`), reprocha que **has hecho su mismo ciclo** y **se come el mundo cocoide**.
   - Jefe secreto (`GordoBoss`): dentro del estómago (x=2000 de `estomago_gordo`) se rompen **5 núcleos de mantequilla rancia** (terracota amarilla) con slimes "Grasa" y jugos gástricos. Al ganar: **FIN DEL CAPÍTULO 1**, recompensas, `chapter1Done = true`. Si mueres, el chamán deja reintentar sin pagar otra vez.

## Cosas a tener en cuenta
- Nada de esto se ha probado dentro del juego todavía; solo se ha comprobado que compila. Si el usuario reporta fallos, revisar primero esa parte.
- Al mover entidades lejos (otra arena/dimensión), cargar antes el chunk de destino (ver `BossFight.moveBoss`).
- Los enemigos `HostileEntity` del mod sobrescriben `isDisallowedInPeaceful()` para no desaparecer en Pacífico.
- Siguiente paso posible: **Capítulo 2** (el usuario aún no lo ha pedido).
- Al terminar cambios: commit con mensaje claro, push a la rama, esperar al CI y darle al usuario el enlace del artefacto del último run.
