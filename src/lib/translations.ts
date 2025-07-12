export const translations = {
    en: {
        // Splash Screen
        splashTitle: 'Goblin Slayer 2048',
        splashDescription: 'Combine goblins to eliminate them in this tactical puzzle game.',
        storyMode: 'Story Mode',
        storyModeDesc: 'Create a Goblin(256) to win.',
        endlessMode: 'Endless Mode',
        endlessModeDesc: 'Survive the endless goblin waves.',
        howToPlay: 'How to Play',
        upgradesAndProgress: 'Upgrades & Progression',
        poweredBy: 'Powered by 2048 mechanics',

        // In-Game Page
        headerTitle: 'Goblin Swiper',
        headerSubtitle: 'Combine goblins to slay them.',
        newGame: 'New Game',
        openMenu: 'Open Menu',

        // Info Panel
        score: 'Score',
        gold: 'Gold',
        level: 'Level',
        totalXp: 'Total XP',
        killsToLevel: 'kills to Lvl.',
        movesUntilAttack: 'moves',
        
        // Abilities
        itemsAndUpgrades: 'Items & Upgrades',
        combineDamageBonus: 'Combine Damage Bonus',
        damageReduction: 'Damage Reduction',
        useRope: 'Use Rope',
        moveGoblin: 'Move a goblin to an empty space.',
        use: 'Use',
        active: 'Active',
        inactive: 'Inactive',
        showInactiveUpgrades: 'Show Inactive Upgrades',

        // Game Over Dialog
        victory: 'Victory!',
        gameOver: 'Game Over',
        finalScore: 'Your final score is',
        runSummary: 'Run Summary',
        time: 'Time',
        goblinsSlain: 'Goblins Slain',
        xpEarned: 'XP Earned',
        playAgain: 'Play Again',
        slayAgain: 'Slay Again',
        
        // Leaderboard
        leaderboardTitle: 'Story Mode Leaderboard',
        leaderboardDesc: 'Top 10 fastest times to defeat the Goblin Lord.',
        rank: 'Rank',
        date: 'Date',
        kills: 'Kills',
        noVictories: 'No victories yet. Be the first!',
        close: 'Close',

        // Permanent Upgrades Dialog
        permUpgradesTitle: 'Permanent Upgrades',
        permUpgradesDesc: 'Spend your XP on permanent buffs.',
        totalXpLabel: 'Total XP:',
        maxLevel: 'Max Level',

        // Shop Dialog
        shopTitle: 'Mysterious Shop',
        shopDesc: 'Spend your gold on powerful items.',
        owned: 'Owned',
        locked: 'Locked',
        noItemsAvailable: 'No items available this time.',
        continueSlaying: 'Continue Slaying',

        // How to Play Dialog
        h2pTitle: 'How to Play',
        h2pDesc: 'A quick guide to becoming the best goblin slayer.',
        h2pBasics: 'Basics',
        h2pCombat: 'Combat',
        h2pPowerups: 'Power-ups',
        h2pProgression: 'Progression',
        h2pModes: 'Modes',
        h2pGotIt: 'Got it!',
        // Basics Tab
        basicsL1: 'Swipe to combine goblins of the same number.',
        basicsL2: 'Each combination damages the resulting goblin (e.g. Goblin(2) + Goblin(2) → Damaged Goblin(4)).',
        basicsL3: 'Defeat goblins to earn points, gold, and experience.',
        basicsL4: "Be careful! If the board fills up and you can't move, you'll take damage.",
        // Combat Tab
        combatTitle: 'Combat & Goblins',
        combatL1: 'Goblins attack every 15 moves. Manage your health ({hp} initial HP) to survive!',
        combatL2: 'Combine goblins to create stronger, more dangerous versions:',
        combatL3: 'Each time you combine, the resulting goblin takes damage. Goblins level 8 or higher will always survive the initial combination.',
        // Powerups Tab
        powerupsTitle: 'Items & Power-ups',
        powerupsL1: 'Get them from the shop that appears on the board. Unlock them first in the permanent upgrades shop!',
        // Progression Tab
        progressionTitle: 'Progression & Upgrades',
        progressionL1: 'Gain Experience (XP) by defeating goblins.',
        progressionL2: 'Use XP on the home screen to buy permanent upgrades that will help you in all your runs.',
        progressionL3: 'Unlock new and powerful items to appear in the in-game shop.',
        progressionL4: 'Every upgrade gets you closer to victory!',
        // Modes Tab
        modesTitle: 'Game Modes',
        storyModeTitle: 'Story Mode',
        endlessModeTitle: 'Endless Mode',

        // Item Names & Descriptions (from allShopItems)
        healthPotion_name: 'Health Potion', healthPotion_desc: '+5 HP',
        torch_name: 'Torch', torch_desc: 'Reveals HP of goblins',
        sword_name: 'Sword', sword_desc: '+1 damage on combines',
        shield_name: 'Shield', shield_desc: 'Reduce damage taken by 1',
        poison_name: 'Poison', poison_desc: 'Combos apply poison',
        rope_name: 'Rope', rope_desc: 'Move a goblin freely (1 use)',
        fireScroll_name: 'Fire Scroll', fireScroll_desc: 'Combos cause splash damage',

        // Permanent Upgrade Names & Descriptions (from PERMANENT_UPGRADES)
        maxHp_name: 'Fortitude', maxHp_desc: 'Increases max player HP by +5.',
        baseDamage_name: 'Sharpened Blade', baseDamage_desc: '+1 base damage on combinations.',
        powerupFreq_name: 'Lucky Charm', powerupFreq_desc: '+15% chance for slain goblins to drop bonus gold.',
        attackTimer_name: 'Vigilance', attackTimer_desc: '+2 moves before horde attacks.',
        xpBonus_name: 'Wisdom', xpBonus_desc: 'Permanently gain +25% XP from kills.',
        startGold_name: 'Deep Pockets', startGold_desc: 'Start runs with +100 gold.',
        overcrowdingResist_name: 'Thick Skin', overcrowdingResist_desc: 'Reduces damage from being crushed by 1.',
        unlockSword_name: 'Unlock: Sword', unlockSword_desc: 'Unlocks the Sword in the shop.',
        unlockTorch_name: 'Unlock: Torch', unlockTorch_desc: 'Unlocks the Torch in the shop.',
        unlockShield_name: 'Unlock: Shield', unlockShield_desc: 'Unlocks the Shield in the shop.',
        unlockHealthPotion_name: 'Unlock: Health Potion', unlockHealthPotion_desc: 'Unlocks the Health Potion in the shop.',
        unlockPoison_name: 'Unlock: Poison', unlockPoison_desc: 'Unlocks Poison in the shop.',
        unlockRope_name: 'Unlock: Rope', unlockRope_desc: 'Unlocks the Rope in the shop.',
        unlockFireScroll_name: 'Unlock: Fire Scroll', unlockFireScroll_desc: 'Unlocks the Fire Scroll in the shop.',

        // Event Logs (dynamic)
        log_chest_appeared: 'A treasure chest appeared!',
        log_new_goblin: 'A new Lv.{value} goblin appeared.',
        log_game_start: 'Game started in {gameMode} mode. Good luck, slayer.',
        log_chest_opened: 'You opened a chest! +{gold} gold.',
        log_shop_appeared: 'A mysterious shop tile has appeared!',
        log_no_room_for_shop: 'No room for a shop to appear!',
        log_shop_disappeared: 'The shop disappeared before you could visit.',
        log_goblin_combine_damage: 'Combined Lv.{value}s. It took {damage} damage.',
        log_goblin_slain: 'The Lv.{value} goblin was slain! +{score} score, +{gold} gold.',
        log_goblin_drop: 'A slain goblin dropped {gold} gold!',
        log_goblin_survived: 'A Lv.{value} goblin survived with {hp} HP.',
        log_goblin_poisoned: 'The Lv.{value} goblin was poisoned!',
        log_milestone: 'Milestone reached! Created Lv.{value} goblin! +{gold} Gold.',
        log_poison_damage: 'Lv.{value} goblin took 1 poison damage.',
        log_poison_death: 'Lv.{value} goblin succumbed to poison!',
        log_fire_scroll_trigger: 'Fire scroll triggers splash damage!',
        log_splash_damage: 'Lv.{value} goblin took 1 splash damage.',
        log_splash_death: 'Lv.{value} goblin burned to a crisp!',
        log_overcrowding_damage: 'The horde is overwhelming! You take {damage} damage.',
        log_overcrowding_resist: 'Your resilience prevents overcrowding damage!',
        log_chest_vanished: 'A treasure chest vanished before you could open it.',
        log_level_up_combine: '+{levels} level(s) for a Lv.{value} goblin!',
        log_level_up_kills: '+{levels} level(s) from slaying goblins!',
        log_horde_attack: 'The horde attacks! You take {damage} damage.',
        log_horde_blocked: 'Your shield blocked all damage from the horde!',
        log_rope_cancelled: 'Rope use cancelled.',
        log_rope_activated: 'Rope mode activated. Select a goblin to move.',
        log_rope_selected: 'Selected Lv.{value} goblin. Choose an empty spot.',
        log_rope_used: 'Moved goblin with a rope.',
        log_rope_cancelled_selection: 'Cancelled selection. Choose a goblin to move.',
        log_enter_shop: 'You enter the shop...',
        log_shop_purchase_leaves: 'The shopkeeper packs up and leaves after your purchase.',
        log_leave_shop: 'You leave the shop... for now.',
        log_purchase: 'Purchased {item} for {cost} gold.',
        log_heal: 'You healed for {hp} HP.',
        log_perm_upgrade_purchased: 'Purchased upgrade: {name}!',

        // GameOver reasons
        reason_crushed: 'You were crushed by the overwhelming horde.',
        reason_slain: 'You were slain by the goblins.',
        reason_victory: 'You have created the Goblin Lord! Victory is yours.',

        // Toasts
        toast_no_ropes: 'No ropes left!',
        toast_not_enough_gold: 'Not enough gold!',
        toast_not_enough_gold_desc: 'You need {cost} gold to buy {item}.',
        toast_not_enough_xp: 'Not enough XP!',
        toast_max_level: 'Max level reached!',
        toast_error_saving: 'Error Saving Progress',
        toast_upgrade_purchased: 'Upgrade Purchased!',
        toast_upgrade_purchased_desc: 'You bought {name}.',
    },
    es: {
        // Splash Screen
        splashTitle: 'Goblin Slayer 2048',
        splashDescription: 'Combina goblins para eliminarlos en este juego de puzle táctico.',
        storyMode: 'Modo Historia',
        storyModeDesc: 'Crea un Goblin(256) para ganar.',
        endlessMode: 'Modo Infinito',
        endlessModeDesc: 'Sobrevive a las infinitas oleadas de goblins.',
        howToPlay: 'Cómo Jugar',
        upgradesAndProgress: 'Mejoras y Progresión',
        poweredBy: 'Basado en la mecánica de 2048',

        // In-Game Page
        headerTitle: 'Goblin Swiper',
        headerSubtitle: 'Combina goblins para matarlos.',
        newGame: 'Nuevo Juego',
        openMenu: 'Abrir Menú',

        // Info Panel
        score: 'Puntuación',
        gold: 'Oro',
        level: 'Nivel',
        totalXp: 'XP Total',
        killsToLevel: 'muertes para Nvl.',
        movesUntilAttack: 'movimientos',

        // Abilities
        itemsAndUpgrades: 'Objetos y Mejoras',
        combineDamageBonus: 'Bonus de Daño por Combinar',
        damageReduction: 'Reducción de Daño',
        useRope: 'Usar Cuerda',
        moveGoblin: 'Mueve un goblin a un espacio vacío.',
        use: 'Usar',
        active: 'Activo',
        inactive: 'Inactivo',
        showInactiveUpgrades: 'Mostrar Mejoras Inactivas',

        // Game Over Dialog
        victory: '¡Victoria!',
        gameOver: 'Fin del Juego',
        finalScore: 'Tu puntuación final es',
        runSummary: 'Resumen de la Partida',
        time: 'Tiempo',
        goblinsSlain: 'Goblins Eliminados',
        xpEarned: 'XP Ganada',
        playAgain: 'Jugar de Nuevo',
        slayAgain: 'Matar de Nuevo',
        
        // Leaderboard
        leaderboardTitle: 'Clasificación Modo Historia',
        leaderboardDesc: 'Los 10 mejores tiempos para derrotar al Goblin Lord.',
        rank: 'Rango',
        date: 'Fecha',
        kills: 'Muertes',
        noVictories: 'Aún no hay victorias. ¡Sé el primero!',
        close: 'Cerrar',

        // Permanent Upgrades Dialog
        permUpgradesTitle: 'Mejoras Permanentes',
        permUpgradesDesc: 'Gasta tu XP en mejoras permanentes.',
        totalXpLabel: 'XP Total:',
        maxLevel: 'Nivel Máx.',

        // Shop Dialog
        shopTitle: 'Tienda Misteriosa',
        shopDesc: 'Gasta tu oro en objetos poderosos.',
        owned: 'Adquirido',
        locked: 'Bloqueado',
        noItemsAvailable: 'No hay objetos disponibles esta vez.',
        continueSlaying: 'Continuar Matando',

        // How to Play Dialog
        h2pTitle: 'Cómo Jugar',
        h2pDesc: 'Una guía rápida para convertirte en el mejor cazador de goblins.',
        h2pBasics: 'Básico',
        h2pCombat: 'Combate',
        h2pPowerups: 'Power-ups',
        h2pProgression: 'Progresión',
        h2pModes: 'Modos',
        h2pGotIt: '¡Entendido!',
        // Basics Tab
        basicsL1: 'Desliza para combinar goblins del mismo número.',
        basicsL2: 'Cada combinación daña al goblin resultante (Ej: Goblin(2) + Goblin(2) → Goblin(4) dañado).',
        basicsL3: 'Elimina goblins para ganar puntos, oro y experiencia.',
        basicsL4: '¡Cuidado! Si el tablero se llena y no puedes mover, recibirás daño.',
        // Combat Tab
        combatTitle: 'Combate y Goblins',
        combatL1: 'Los goblins atacan cada 15 movimientos. ¡Gestiona tu vida ({hp} HP inicial) para sobrevivir!',
        combatL2: 'Combina goblins para crear versiones más fuertes y peligrosas:',
        combatL3: 'Cada vez que combinas, el goblin resultante recibe daño. Los goblins de nivel 8 o más siempre sobrevivirán a la combinación inicial.',
        // Powerups Tab
        powerupsTitle: 'Objetos y Power-ups',
        powerupsL1: 'Consíguelos en la tienda que aparece en el tablero. ¡Desbloquéalos primero en la tienda de mejoras permanentes!',
        // Progression Tab
        progressionTitle: 'Progresión y Mejoras',
        progressionL1: 'Gana Experiencia (XP) al eliminar goblins.',
        progressionL2: 'Usa la XP en la pantalla de inicio para comprar mejoras permanentes que te ayudarán en todas tus partidas.',
        progressionL3: 'Desbloquea nuevos y poderosos objetos para que aparezcan en la tienda del juego.',
        progressionL4: '¡Cada mejora te acerca más a la victoria!',
        // Modes Tab
        modesTitle: 'Modos de Juego',
        storyModeTitle: 'Modo Historia',
        endlessModeTitle: 'Modo Infinito',

        // Item Names & Descriptions
        healthPotion_name: 'Poción de Vida', healthPotion_desc: '+5 HP',
        torch_name: 'Antorcha', torch_desc: 'Revela los HP de los goblins',
        sword_name: 'Espada', sword_desc: '+1 de daño en combos',
        shield_name: 'Escudo', shield_desc: 'Reduce el daño recibido en 1',
        poison_name: 'Veneno', poison_desc: 'Los combos aplican veneno',
        rope_name: 'Cuerda', rope_desc: 'Mueve un goblin libremente (1 uso)',
        fireScroll_name: 'Pergamino de Fuego', fireScroll_desc: 'Los combos causan daño en área',

        // Permanent Upgrade Names & Descriptions
        maxHp_name: 'Fortaleza', maxHp_desc: 'Aumenta los HP máximos en +5.',
        baseDamage_name: 'Hoja Afilada', baseDamage_desc: '+1 de daño base en combinaciones.',
        powerupFreq_name: 'Amuleto de la Suerte', powerupFreq_desc: '+15% de probabilidad de que los goblins suelten oro extra.',
        attackTimer_name: 'Vigilancia', attackTimer_desc: '+2 movimientos antes del ataque de la horda.',
        xpBonus_name: 'Sabiduría', xpBonus_desc: 'Gana permanentemente +25% de XP.',
        startGold_name: 'Bolsillos Profundos', startGold_desc: 'Empieza las partidas con +100 de oro.',
        overcrowdingResist_name: 'Piel Gruesa', overcrowdingResist_desc: 'Reduce el daño por aplastamiento en 1.',
        unlockSword_name: 'Desbloquear: Espada', unlockSword_desc: 'Desbloquea la Espada en la tienda.',
        unlockTorch_name: 'Desbloquear: Antorcha', unlockTorch_desc: 'Desbloquea la Antorcha en la tienda.',
        unlockShield_name: 'Desbloquear: Escudo', unlockShield_desc: 'Desbloquea el Escudo en la tienda.',
        unlockHealthPotion_name: 'Desbloquear: Poción', unlockHealthPotion_desc: 'Desbloquea la Poción de Vida en la tienda.',
        unlockPoison_name: 'Desbloquear: Veneno', unlockPoison_desc: 'Desbloquea el Veneno en la tienda.',
        unlockRope_name: 'Desbloquear: Cuerda', unlockRope_desc: 'Desbloquea la Cuerda en la tienda.',
        unlockFireScroll_name: 'Desbloquear: Pergamino', unlockFireScroll_desc: 'Desbloquea el Pergamino de Fuego en la tienda.',

        // Event Logs
        log_chest_appeared: '¡Apareció un cofre del tesoro!',
        log_new_goblin: 'Apareció un nuevo goblin de Nv.{value}.',
        log_game_start: 'Juego iniciado en modo {gameMode}. ¡Buena suerte, cazador!',
        log_chest_opened: '¡Abriste un cofre! +{gold} de oro.',
        log_shop_appeared: '¡Ha aparecido una misteriosa tienda!',
        log_no_room_for_shop: '¡No hay espacio para que aparezca una tienda!',
        log_shop_disappeared: 'La tienda desapareció antes de que pudieras visitarla.',
        log_goblin_combine_damage: 'Combinados Nv.{value}s. Recibió {damage} de daño.',
        log_goblin_slain: '¡El goblin de Nv.{value} fue eliminado! +{score} puntos, +{gold} de oro.',
        log_goblin_drop: '¡Un goblin eliminado dejó caer {gold} de oro!',
        log_goblin_survived: 'Un goblin de Nv.{value} sobrevivió con {hp} HP.',
        log_goblin_poisoned: '¡El goblin de Nv.{value} fue envenenado!',
        log_milestone: '¡Hito alcanzado! ¡Creado goblin de Nv.{value}! +{gold} de oro.',
        log_poison_damage: 'El goblin de Nv.{value} recibió 1 de daño por veneno.',
        log_poison_death: '¡El goblin de Nv.{value} sucumbió al veneno!',
        log_fire_scroll_trigger: '¡El pergamino de fuego activa daño en área!',
        log_splash_damage: 'El goblin de Nv.{value} recibió 1 de daño en área.',
        log_splash_death: '¡El goblin de Nv.{value} fue reducido a cenizas!',
        log_overcrowding_damage: '¡La horda es abrumadora! Recibes {damage} de daño.',
        log_overcrowding_resist: '¡Tu resistencia previene el daño por aplastamiento!',
        log_chest_vanished: 'Un cofre del tesoro desapareció antes de que pudieras abrirlo.',
        log_level_up_combine: '¡+{levels} nivel(es) por un goblin de Nv.{value}!',
        log_level_up_kills: '¡+{levels} nivel(es) por eliminar goblins!',
        log_horde_attack: '¡La horda ataca! Recibes {damage} de daño.',
        log_horde_blocked: '¡Tu escudo bloqueó todo el daño de la horda!',
        log_rope_cancelled: 'Uso de cuerda cancelado.',
        log_rope_activated: 'Modo cuerda activado. Selecciona un goblin para mover.',
        log_rope_selected: 'Seleccionado goblin de Nv.{value}. Elige un espacio vacío.',
        log_rope_used: 'Moviste un goblin con una cuerda.',
        log_rope_cancelled_selection: 'Selección cancelada. Elige un goblin para mover.',
        log_enter_shop: 'Entras en la tienda...',
        log_shop_purchase_leaves: 'El tendero se va después de tu compra.',
        log_leave_shop: 'Sales de la tienda... por ahora.',
        log_purchase: 'Compraste {item} por {cost} de oro.',
        log_heal: 'Te curaste {hp} HP.',
        log_perm_upgrade_purchased: '¡Mejora comprada: {name}!',

        // GameOver reasons
        reason_crushed: 'Fuiste aplastado por la horda abrumadora.',
        reason_slain: 'Fuiste asesinado por los goblins.',
        reason_victory: '¡Has creado al Señor de los Goblins! La victoria es tuya.',

        // Toasts
        toast_no_ropes: '¡No quedan cuerdas!',
        toast_not_enough_gold: '¡Oro insuficiente!',
        toast_not_enough_gold_desc: 'Necesitas {cost} de oro para comprar {item}.',
        toast_not_enough_xp: '¡XP insuficiente!',
        toast_max_level: '¡Nivel máximo alcanzado!',
        toast_error_saving: 'Error al Guardar el Progreso',
        toast_upgrade_purchased: '¡Mejora Comprada!',
        toast_upgrade_purchased_desc: 'Compraste {name}.',
    }
};

export type Translations = typeof translations.en;

// Simple formatter for strings with placeholders like {key}
export function formatString(str: string, values: Record<string, string | number>): string {
    return str.replace(/\{(\w+)\}/g, (placeholder, key) => {
        return values[key] !== undefined ? String(values[key]) : placeholder;
    });
}
