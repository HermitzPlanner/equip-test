let indexSpecialEffects = {}
let indexActivateText = {}
let equipmentTooltip = {}

Promise.all([
    fetch('as/src-rotmg-constants-SpecialEffects.as')
        .then(response => response.text())
        .then(data => filterEffectsIndex(data)),

    fetch('as/src-rotmg-constants-ActivationType.as')
        .then(response => response.text())
        .then(data => filterActivationTypeIndex(data)),

    fetch('as/src-rotmg-ui-tooltip-EquipmentToolTip.as')
        .then(response => response.text())
        .then(data => filterTooltipData(data)),
])
.then(loadXML)
//.then(() => Equipment()) // Now Equipment() only runs after both fetches complete
.catch(console.error);


function filterTooltipData(data) {
    //console.log("Original Tooltip Data:", data);

    const parsedFunctions = parseFunctions(data)
    console.log("Parsed Functions:", parsedFunctions);

    const projectileProperties = parseProjectileProperties(parsedFunctions)
    const specialEffectsColors = parseColors(parsedFunctions)
    const specialEffectsText = parseSpecialEffectsText(parsedFunctions)
    const activateText = parseActivateText(parsedFunctions)

    equipmentTooltip = {
        "projectileProperties": projectileProperties,
        "specialEffectsColors": specialEffectsColors,
        "specialEffectsText": specialEffectsText,
        "activateText": activateText
    } 

    console.log("equipmentTooltip", equipmentTooltip)
}

function parseActivateTextOLD(data) {
    let text = {};

    for (let i = 0; i < data["makeActivateEffects"].length; i++) {
        let line = data["makeActivateEffects"][i].trim();

        // If the line starts with 'case', it's a property name
        if (line.startsWith("case")) {
            let textName = line.slice(20).trim();

            // Clean the textName by removing unwanted substrings
            textName = textName
                .replace(":", "")
            // Check subsequent lines until we find a line starting with 'return'
            let value = null;
            for (let j = i + 1; j < data["makeActivateEffects"].length; j++) {
                let valueLine = data["makeActivateEffects"][j].trim();
                if (valueLine.startsWith("this.attributes +=")) {
                    value = valueLine.slice(19).trim(); // Extract the value
                    break
                }
            }

            value = value
            .replace(/["+(){};]/g, '')
            .replace(/\\n/g, '')
            .replace(/[\\]/g, '')

            if (value !== null) {
                text[textName] = value;
            }
        }
    }
    return text
}

function parseActivateText({
    stat = "", amount = 0, duration = 0, range = 0, condition = "",
    totalDamage = 0, impactDmg = 0, radius = 0, healAmount = 0, 
    maxTargets = 0, name = "", className = "", currencyName = "", 
    objectId = "", chance = 0, pieceName = "", stacking = "", 
    airTime = 0, type = ""
} = {}) {
    const statColor = (txt, isArmorPiercing) => `<span class="text-outline ${isArmorPiercing ? 'untiered' : 'stat-color'}">${txt}</span>`

    return {
        GENERIC_ACTIVATE: `BuildGenericAEae, wisModded, rangeColor, durationColor, condition, conditionColor`,
        INCREMENT_STAT: `Increases ${statColor(normalizeStatType(stat))} by ${statColor(amount)}`,
        HEAL: `Heals ${statColor(amount < 0 ? '-' : '+' + amount)} HP`,
        MAGIC: `Heals ${statColor(amount < 0 ? '-' : '+' + amount)} MP`,
        HEAL_NOVA: `Heals ${statColor(amount < 0 ? '-' : '+' + amount)} HP in ${statColor(range)} sqrs`,
        STAT_BOOST_SELF: `On Self: ${statColor(amount < 0 ? '-' : '+' + amount)} ${statColor(normalizeStatType(stat))} for ${statColor(duration)} secs`,
        STAT_BOOST_AURA: `On Allies: ${statColor(amount < 0 ? '-' : '+' + amount)} ${statColor(normalizeStatType(stat))} in ${statColor(range)} sqrs for ${statColor(duration)} secs`,
        BULLET_NOVA: `Spell: ${statColor(amount < 0 ? '-' : '+' + amount)} shots`,
        COND_EFFECT_SELF: `On Self: ${statColor(condition)} for ${statColor(duration)} secs`,
        COND_EFFECT_AURA: `On Allies: ${statColor(condition)} in ${statColor(range)} sqrs for ${statColor(duration)} secs`,
        TELEPORT: `Teleports to cursor`,
        POISON_GRENADE: `Poison: Deals ${statColor(totalDamage)} damage${impactDmg ? ` (${statColor(impactDmg)} impact)` : ""} in ${statColor(radius)} sqrs for ${statColor(duration)} secs`,
        VAMPIRE_BLAST: `Skull: Heals ${statColor(healAmount)} HP dealing ${statColor(totalDamage)} damage in ${statColor(radius)} sqrs`,
        TRAP: `Trap: Deals ${statColor(totalDamage)} damage in ${statColor(radius)} sqrs. Lasts for ${statColor(duration)} secs`,
        STASIS_BLAST: `Stasis enemies within ${statColor(range)} sqrs of cursor for ${statColor(duration)} secs`,
        DECOY: `Decoy: Lasts for ${statColor(duration)} secs`,
        LIGHTNING: `Lightning: Targets ${statColor(maxTargets)} enemies dealing ${statColor(totalDamage)} damage`,
        MAGIC_NOVA: `Heals ${statColor(amount < 0 ? '-' : '+' + amount)} MP in ${statColor(range)} sqrs`,
        DAMAGE_BLAST: `AoE: Deals ${statColor(totalDamage)} damage in ${statColor(radius)} sqrs`,
        POISON_BLAST: `AoE: Deals ${statColor(totalDamage)} damage${impactDmg ? ` (${statColor(impactDmg)} impact)` : ""} in ${statColor(radius)} sqrs for ${statColor(duration)} secs`,
        REMOVE_NEG_COND: `On Allies: Purifies all debuffs in ${statColor(range)} sqrs`,
        REMOVE_NEG_COND_SELF: `On Self: Purifies all debuffs`,
        BACKPACK: `Unlocks the backpack`,
        UNLOCK_SATCHEL: `Unlocks the materials satchel`,
        CHANGE_NAME_COLOR: `Changes the color of your name in chat`,
        UNLOCK_CHAR: `Unlocks an extra character slot`,
        UNLOCK_VAULT: `Unlocks an extra vault chest`,
        CRATE: `Opens a loot crate`,
        UNLOCK_SKIN: `Unlocks the ${statColor(name)} skin for ${statColor(className)}`,
        XP_BOOST: `x2 XP while active`,
        LT_BOOST: `+1 tier from loot while active`,
        LD_BOOST: `${statColor(amount < 0 ? '-' : '+' + amount)}% loot drop chance while active`,
        ADD_CURRENCY: `Adds ${statColor(amount < 0 ? '-' : '+' + amount)} ${statColor(currencyName)} to your account`,
        RESET_SKILL_TREE: `Resets skill tree progress`,
        SPELL_GRENADE: `Airborne Spell: ${statColor(amount < 0 ? '-' : '+' + amount)} shots`,
        ALLY: `Summons a ${statColor(objectId)} for ${statColor(duration)} seconds`,
        PURIFY_MADNESS: `Purifies 'King's Madness' and resets Madness buildup`,
        ATTACKING_VINES: `Spawns a cluster of three vines at cursor for 3 seconds`,
        RARE_EVENTS_BOOST: `Boosts a Realm's chance to spawn Rare Events by ${statColor(chance)}%`,
        NEXT_REALM_EVENT: `Forces the next Realm event to be ${statColor(objectId)}`,
        CHAOS_FIRES: `Summons 4 flames for 3.5 secs`,
        KING_GEMS_1: `Summons a Blue or Green gem that orbits player for 5 secs`,
        KING_GEMS_2: `Summons a Red or Yellow gem that orbits decoy for 5 secs`,
        ADD_SKILL_POINTS: `Adds ${statColor(amount < 0 ? '-' : '+' + amount)} skill points to your character`,
        QUEST_TELEPORT: `Teleports you to your quest when used in Realm`,
        SKILL_XP_BOOST: `${statColor(amount < 0 ? '-' : '+' + amount)}% Skill XP while active`,
        INCREMENT_LB: `Increases Lootboost by ${statColor(amount < 0 ? '-' : '+' + amount)}`,
        PILL: `Resets your Birthsign and sends you to the Dark Room`,
        PERMA_PET: `Spawns a cosmetic ${statColor(objectId)} pet`,
        MAGICIAN_BUNNY: `Lasts for ${statColor(duration)} secs`,
        GOLDEN_WATCH: `Activates the passive effect`,
        MONKE_MODE: `Activates Monkey’s Curse for 20 mins`,
        RAID_KEY_PIECE: `Activates the ${statColor(pieceName)} raid altar in Nexus`,
        HELL_KEY_CREATE: `Activates all three raid altars in Nexus and starts the Hell Raid`,
        TEMPORARY_LB: `Grants ${statColor(amount < 0 ? '-' : '+' + amount)}% loot boost for ${statColor(duration)} secs (${statColor(stacking)})`,
        THROW_SNOWBALL: `Snowball: Steals ${statColor(impactDmg)} points from players within ${statColor(radius)} sqrs and adds ${statColor(amount < 0 ? '-' : '+' + amount)} points for every player hit`,
        BARRAGE: `Barrage: Fire ${statColor(amount < 0 ? '-' : '+' + amount)} sets of shots at enemy closest to cursor every ${statColor(duration)} sec`,
        GRENADE: `Grenade: Deals ${statColor(impactDmg)} damage within ${statColor(radius)} sqrs, ${statColor(airTime)} sec air time`,
        DEATH_BOOST: `Activates ${statColor(amount < 0 ? '-' : '+' + amount)}% death loot boost for ${statColor(duration)} secs`,
        SKILL_XP: `Grants your character ${statColor(amount < 0 ? '-' : '+' + amount)} SXP`,
        HALLOWEEN_CANDY: `This candy is added to the ${statColor(type)} candy pool, to empower Realm Event dungeons`
    };
    
}


function parseColors(data) {
    let color = {};

    for (let i = 0; i < data["GetEffectColor"].length; i++) {
        let line = data["GetEffectColor"][i].trim();

        // If the line starts with 'case', it's a property name
        if (line.startsWith("case")) {
            let colorName = line.slice(20).trim();

            // Clean the colorName by removing unwanted substrings
            colorName = colorName
                .replace(":", "")
            // Check subsequent lines until we find a line starting with 'return'
            let value = null;
            for (let j = i + 1; j < data["GetEffectColor"].length; j++) {
                let valueLine = data["GetEffectColor"][j].trim();
                if (valueLine.startsWith("return")) {
                    value = valueLine.slice(7).trim(); // Extract the value
                    break
                }
            }

            value = value
            .replace(/["+(){};]/g, '')

            // If a valid value is found, assign it to the property
            if (value !== null) {
                color[colorName] = value;
            }
        }
    }
    return color
}

function parseSpecialEffectsText(data) {
    let text = {};

    for (let i = 0; i < data["GetEffectText"].length; i++) {
        let line = data["GetEffectText"][i].trim();

        // If the line starts with 'case', it's a property name
        if (line.startsWith("case")) {
            let textName = line.slice(20).trim();

            // Clean the textName by removing unwanted substrings
            textName = textName
                .replace(":", "")
            // Check subsequent lines until we find a line starting with 'return'
            let value = null;
            for (let j = i + 1; j < data["GetEffectText"].length; j++) {
                let valueLine = data["GetEffectText"][j].trim();
                if (valueLine.startsWith("return")) {
                    value = valueLine.slice(7).trim(); // Extract the value
                    break
                }
            }

            value = value
            .replace(/["+(){};]/g, '')
            .replace(/\\n/g, '')
            .replace(/[\\]/g, '')
            .replace(`.replace0,this.itemData.LegendarySacrifices.replace1,this.itemData.DemonicSacrifices`, "")
            .replace(`     this.getMarkOfTheHuntressCooldown  s cooldown`, "")
            // last one is for favor of fortuna

            // If a valid value is found, assign it to the property
            if (value !== null) {
                text[textName] = value;
            }
        }
    }
    return text
}

function parseFunctions(data) {
    const lines = data.split('\n').map(line => line.trim());
    const result = {};

    let currentFunction = null;

    lines.forEach((line) => {
        const match = line.match(/\bfunction\b\s+(\w+)/); // Match "function" and capture the name
        if (match) {
            // Start a new function block
            currentFunction = match[1];
            result[currentFunction] = []; // Initialize a new key for this function name
        } else if (currentFunction) {
            // Add non-function lines to the current function's code
            result[currentFunction].push(line);
        }
    });

    return result;
}

function parseProjectileProperties(data) {
    let properties = {};

    for (let i = 0; i < data["makeProjProperties"].length; i++) {
        let line = data["makeProjProperties"][i].trim();

        // If the line starts with 'if', it's a property name
        if (line.startsWith("if")) {
            let propertyName = line.slice(3).trim();

            // Clean the propertyName by removing unwanted substrings
            propertyName = propertyName
                .replace(/proj\./g, "")  // Remove 'proj.'
                .replace(/ != null && /g, "")
                .replace(/Explode\.AimAtCursor/g, "")  // Remove ' != null && proj.Explode.AimAtCursor'
                .replace(/ > 0/g, "")  // Remove ' > 0'
                .replace(/\)/g, "");  // Remove ')'

            // Check subsequent lines until we find a line starting with 'this.attributes'
            let value = null;
            for (let j = i + 1; j < data["makeProjProperties"].length; j++) {
                let valueLine = data["makeProjProperties"][j].trim();
                if (valueLine.startsWith("this.attributes")) {
                    value = valueLine.slice(15).trim(); // Extract the value
                    break; // Stop checking after finding the first valid value
                }
            }

            value = value
                .replace(`+= TooltipHelper.wrapInFontTag(\"`,"")       
                .replace(`\",TooltipHelper.SPECIAL_COLOR) + \"\\n\";`,"")
                .replace(`\",TooltipHelper.NO_DIFF_COLOR) + \"\\n\";`, "")
                .replace(`+= noDiffColor(\"`, "")
                .replace(`\\n\");`, "")

            // If a valid value is found, assign it to the property
            if (value !== null) {
                properties[propertyName] = value;
            }
        }
    }
    return properties
}


function filterActivationTypeIndex(data) {
    const index = new Map();
    // Regex to capture constants in the format: static const CONSTANT_NAME:type = value;
    const constantRegex = /\bstatic\s*const\s+(\w+)\s*:\s*\w+\s*=\s*([^\;]+);/g;
    let match;

    // Match all constants in the file and store them as key-value pairs in the Map
    while ((match = constantRegex.exec(data)) !== null) {
        const constantName = match[1];  // The constant name (e.g., DISCOUNT_RATE)
        let constantValue = match[2].trim();  // The constant value (e.g., "0.1", "true", "Hello")

        // Determine the actual type of the constant value
        if (!isNaN(constantValue)) {
            // It's a numeric value
            constantValue = parseFloat(constantValue);
        } else if (constantValue === "true" || constantValue === "false") {
            // It's a boolean value
            constantValue = constantValue === "true";
        } else if (/^".*"$|^'.*'$/.test(constantValue)) {
            // It's a string (remove quotes)
            constantValue = constantValue.slice(1, -1);
        }

        // Store the constant in the Map
        indexActivateText[constantValue] = constantName
    }

    console.log("indexActivateText", indexActivateText)
}


function filterEffectsIndex(data) {
    index = new Map()
    // Regex to capture constants in the format: static const CONSTANT_NAME:type = value;
    const constantRegex = /\bstatic\s*const\s+(\w+)\s*:\s*\w+\s*=\s*([^\;]+);/g;
    let match;

    // Match all constants in the file and store them as key-value pairs in the Map
    while ((match = constantRegex.exec(data)) !== null) {
        const constantName = match[1];  // The constant name (e.g., DISCOUNT_RATE)
        const constantValue = match[2];  // The constant value (e.g., 0.1)

        indexSpecialEffects[constantValue] = constantName
    }
}