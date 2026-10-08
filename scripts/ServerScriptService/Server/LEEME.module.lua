--[[
======================================================================
  LEEME · GUÍA DEL PROYECTO (Anime Smash · R6)
  Este ModuleScript no se ejecuta: solo es documentación.
======================================================================

ESTRUCTURA
----------
ReplicatedStorage/Shared          (lo usan cliente y servidor)
  CombatConfig       Física, knockback, blast zones, cámara, partidas
  EconomyConfig      Monedas Malditas/Gemas, recompensas, paquetes de gemas
  CatalogConfig      Precios de personajes, Acceso Anticipado, skins, VIP
  BattlePassConfig   Temporada, XP por nivel, recompensas del pase
  Characters/        Un ModuleScript por luchador (movimientos y apariencia)
  KnockbackMath / KnockbackSimulator / CharacterRegistry

ServerScriptService/Server        (servidor = autoridad)
  Main               Arranque + enrutador de la tienda
  Data/DataTemplate  Estructura de los datos guardados de cada jugador
  Services/
    DataService       Guardado con bloqueo de sesión y autoguardado
    EconomyService    Monedas, XP, niveles, compras con Robux
    FighterService    Crea los personajes R6 (apariencia + skin)
    CombatService     Ataques, hitboxes, % de daño, knockback
    MatchService      Partidas, KOs, stocks, victoria
    UnlockService     Comprar/elegir personajes y skins
    BoosterService    +5% por skin premium y por VIP
    BattlePassService Pase de batalla gratis/premium
    LobbyService      Estatua del campeón + Muro de Leyendas

StarterPlayer/StarterPlayerScripts/Client
  ClientMain + Controllers/ (cámara, movimiento, combate, móvil, HUD,
  tienda, pase, objetivos, pantalla de victoria, menú) + Modules/UI

CONTROLES
---------
PC: A/D moverse · Espacio saltar (x2) · S en el aire caída rápida
    Clic/J golpe · Clic der/K fuerte · E/L especial · T cambiar personaje
    Mantén W/S/A-D al atacar para variantes (arriba/abajo/lado/aire)
Móvil: joystick a la izquierda + botones Golpe/Fuerte/Especial/Saltar
Mando: stick izq · A saltar · X golpe · Y fuerte · B especial

ANTES DE PUBLICAR (checklist)
-----------------------------
[ ] Crear los Developer Products de gemas en Creator Hub > Monetization
    y poner sus IDs en EconomyConfig.GemPacks (Id = 0 => botón desactivado)
[ ] Crear el Developer Product del Pase Premium (Robux) y poner su ID en
    BattlePassConfig.PremiumProductId (uno nuevo cada temporada)
[ ] Crear el gamepass VIP y poner su ID en CatalogConfig.GamePasses.VIP
[ ] Revisar fechas: CatalogConfig.Characters.CursedKing.Release y
    BattlePassConfig.Season (Start/End)
[ ] Ajustar EconomyConfig.EstimatedCoinsPerHour con datos reales
[ ] Sustituir la apariencia por colores (Appearance) por modelos R6 propios
[ ] Añadir AnimationId a los movimientos (campo AnimationId en Characters/)
[ ] Nombres/arte ORIGINALES: no usar personajes con copyright (Jujutsu
    Kaisen, Dragon Ball...) en un juego que cobra Robux: riesgo de DMCA.

PROBAR EN STUDIO
----------------
* F5 = un jugador (modo práctica con muñeco).
* Partida real: en la barra superior elige "Servidor y clientes", pon 2
  jugadores y pulsa Play.
* Dinero de prueba (SOLO en Studio), en la Command Bar con vista Cliente:
    game.ReplicatedStorage.Remotes.ShopRequest:InvokeServer("DevGrant")
* En Studio los datos se guardan en "PlayerData_v1_Studio", separado de
  los jugadores reales ("PlayerData_v1"): probar no estropea nada.

CÓMO AÑADIR UN PERSONAJE NUEVO
------------------------------
1. Duplica un ModuleScript de Characters/ y cambia Id, DisplayName,
   Appearance y Moves.
2. Añádelo a CatalogConfig.Characters con Order, Rarity y precios.
   Si pones Release = CatalogConfig.utc(año, mes, día, hora), saldrá en
   Acceso Anticipado (solo Gemas) 14 días y luego con Monedas Malditas.
3. (Opcional) Añade skins en CatalogConfig.Skins.

MONETIZACIÓN ÉTICA (reglas que sigue el código)
-----------------------------------------------
* Nunca se vende daño: boosters solo aceleran Monedas/XP (+5%).
* Todo lo de pago se puede conseguir gratis jugando, salvo cosméticos.
* Acceso Anticipado = antes, no más fuerte (mismo balance).
* Doble clic de confirmación en cada gasto de moneda.
* Sin cajas de botín: siempre se ve exactamente lo que compras.
======================================================================
]]

return nil
