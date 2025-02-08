function normalizeStatType(statCode) {
    const statMap = {
        "0": "Maximum HP",
        "3": "Maximum MP",
        "20": "Attack",
        "21": "Defense",
        "22": "Speed",
        "26": "Vitality",
        "27": "Wisdom",
        "28": "Dexterity",
        "116": "Maximum Shield", // #C0C0C0
        "125": "Loot Boost",
        "132": "Damage Reduction", // #495DCC
        "138": "Critical Hit Chance", // #e27b2d
        "139": "Critical Hit Multiplier", // #FFBB32
        "140": "Dodge Chance", // #8899FF
        "144": "Shield Recharge Time" // #72BF26
        // The rest use #f2f287
    };

    return statMap[statCode] || "Unknown";
}

function normalizeStatColor(statCode) {
    const colorMap = {
        "0": "#f2f287", // Maximum HP
        "3": "#f2f287", // Maximum MP
        "20": "#f2f287", // Attack
        "21": "#f2f287", // Defense
        "22": "#f2f287", // Speed
        "26": "#f2f287", // Vitality
        "27": "#f2f287", // Wisdom
        "28": "#f2f287", // Dexterity
        "116": "#C0C0C0", // Maximum Shield
        "125": "#f2f287", // Loot Boost
        "132": "#495DCC", // Damage Reduction
        "138": "#e27b2d", // Critical Hit Chance
        "139": "#FFBB32", // Critical Hit Multiplier
        "140": "#8899FF", // Dodge Chance
        "144": "#72BF26"  // Shield Recharge Time
    };
    return colorMap[statCode] || "Unknown";
}

function normalizeBagType(string) {
    const bagTypes = {
        "5": "untiered",
        "6": "hunter",
        "10": "legendary",
        "13": "cosmic",
        "14": "legendary",
        "12": "demonic"
    };

    return bagTypes[string] || "Unknown";
}

function normalizeId(string) {
    return string
        .toLowerCase()
        .replace(/[^a-z0-9]/g, '')
}

function normalizeFile(string) {
    const fileMappings = {
        "halloween24": "assets/174_rotmg.assets.EmbeddedAssets_Halloween24Embed.png",
        "lofiObj7": "assets/204_rotmg.assets.EmbeddedAssets_LofiObj7Embed.png",
        "lofiObj6": "assets/203_rotmg.assets.EmbeddedAssets_LofiObj6Embed.png",
        "shmittySheet": "assets/48_rotmg.assets.EmbeddedAssets_ShmittySheetEmbed.png",
        "lofiObj3": "assets/113_rotmg.assets.EmbeddedAssets_LofiObj3Embed.png",
        "lofiObj5": "assets/220_rotmg.assets.EmbeddedAssets_LofiObj5Embed.png",
        "gPlusSheet": "assets/27_rotmg.assets.EmbeddedAssets_GPlusSheetEmbed.png",
        "customObjects64x64": "assets/211_rotmg.assets.EmbeddedAssets_CustomObjects64x64.png",
        "lostHallsObjects8x8": "assets/59_rotmg.assets.EmbeddedAssets_LostHallsObjects8x8.png",
        "lofiObj2": "assets/30_rotmg.assets.EmbeddedAssets_LofiObj2Embed.png"
    };

    return fileMappings[string] || "no file name";
}

function normalizeSlotType(string) {
    const slotMapping = {
        // Weapons
        "17": { slot: "Weapon", category: "Staff" },
        "8": { slot: "Weapon", category: "Wand" },
        "1": { slot: "Weapon", category: "Sword" },
        "2": { slot: "Weapon", category: "Dagger" },
        "24": { slot: "Weapon", category: "Katana" },
        "3": { slot: "Weapon", category: "Bow" },

        // Armors
        "14": { slot: "Armor", category: "Robe" },
        "7": { slot: "Armor", category: "Heavy" },
        "6": { slot: "Armor", category: "Leather" },

        // Abilities
        "23": { slot: "Ability", category: "Scepter" },
        "16": { slot: "Ability", category: "Helm" },
        "12": { slot: "Ability", category: "Seal" },
        "21": { slot: "Ability", category: "Orb" },
        "5": { slot: "Ability", category: "Shield" },
        "13": { slot: "Ability", category: "Cloak" },
        "26": { slot: "Ability", category: "Mask" },
        "11": { slot: "Ability", category: "Spell" },
        "19": { slot: "Ability", category: "Skull" },
        "25": { slot: "Ability", category: "Shuriken" },
        "4": { slot: "Ability", category: "Tome" },
        "22": { slot: "Ability", category: "Prism" },
        "18": { slot: "Ability", category: "Poison" },
        "15": { slot: "Ability", category: "Quiver" },
        "20": { slot: "Ability", category: "Trap" },

        // Rings
        "9": { slot: "Ring", category: "Ring" },

        // Potion
        "10": { slot: "Consumable", category: "Consumable" }
    };

    if (string == "all") return slotMapping
    return slotMapping[string] || "Unknown";
}

function normalizeActivateText(element) {
    const text = element.textContent

    let maxTargets = element.getAttribute("maxTargets") || null
    let statPerTarget = element.getAttribute("statPerTarget") || null
    let damagePerStat = element.getAttribute("damagePerStat") || null
    let stat = normalizeStatType(element.getAttribute("statMod")) || null

    let effect = element.getAttribute("effect") || null
    let duration = element.getAttribute("duration") || null
    let range = element.getAttribute("range") || null


    let statPerTargetText, damagePerStatText
    if (element.hasAttribute("useWisMod")) {
        statPerTargetText = "(increases with Wisdom)"
        damagePerStatText = "(increases with Wisdom)"
    } else {
        statPerTargetText = `(+1 every ${statPerTarget} ${stat})`
        damagePerStatText = `(+${damagePerStat} every 1 ${stat})`
    }
    const map = {
        "Lightning": `
            -Targets ${maxTargets} enemies
            ${statPerTargetText} <br>
            -Deals ${element.getAttribute("totalDamage")} damage
            ${damagePerStatText}`,
        "ConditionEffectAura": `
        -On Allies: ${effect} in ${range} sqrs for ${duration} secs
        `,
        "ConditionEffectSelf": `
        -On Self: ${effect} for ${duration} secs
        `

        
    }

    return map[text] || "Unknown"
}

function capitalize(string) {
    if (string.length === 0) return string;
    return string.charAt(0).toUpperCase() + string.slice(1).toLowerCase();
}