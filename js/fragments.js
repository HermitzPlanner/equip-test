let innerhtml = ''

const canvas = (obj) => {
    const canvas = document.createElement('canvas')
    renderCanvas(obj, canvas)
    return canvas
}

const addElement = (tag, classes = "no-class", text = "", fontSize = '100%') => {
    e = document.createElement(tag)
    e.classList.add(classes)
    e.innerHTML = text
    if (tag == 'p') e.style.fontSize = fontSize
    return e
}

const statColor = (txt, isArmorPiercing) => `<span class="text-outline ${isArmorPiercing ? 'untiered' : 'stat-color'}">${txt}</span>`

const showOrHideClass = (obj, selector) => obj.querySelector(selector) ? selector : 'no-display';

const getBool = (obj, key) => !!obj.querySelector(key);

const getText = (obj, key) => obj.querySelector(key)?.textContent.trim() || null;

const getAwakeningText = (obj) => getBool(obj, 'AwakenedEffects') ? 'This item can be awakened' : 'No awakening available';

const getReskinOfText = (obj) => {
    const reskin = getText(obj, 'ReskinOf');
    //const effectInfo = obj.querySelector('EffectInfo');
    return reskin ? `Reskin of: ${statColor(reskin)}` : "No reskin"
    /*return reskin
        ? `<b>${reskin}<b> ${effectInfo ? effectInfo.getAttribute('description') : ''}`
        : "No reskin";*/
};

const getOnEquipStats = (obj) => {
    const ActivateOnEquipArray = obj.querySelectorAll('ActivateOnEquip');

    if (!ActivateOnEquipArray.length) return 'No equip stat'; // Return empty string if no stats

    return 'On Equip: <br>' +
        Array.from(ActivateOnEquipArray)
            .map(el => {
                let amount = parseInt(el.getAttribute('amount'), 10);
                let stat = el.getAttribute('stat');

                // Check if stat is one of the special ones that require percentage conversion
                if (["132", "138", "139", "140"].includes(stat)) {
                    const colorMap = {
                        "116": "#C0C0C0", // Maximum Shield
                        "125": "#f2f287", // Loot Boost
                        "132": "#495DCC", // Damage Reduction
                        "138": "#e27b2d", // Critical Hit Chance
                        "139": "#FFBB32", // Critical Hit Multiplier
                        "140": "#8899FF", // Dodge Chance
                        "144": "#72BF26"  // Shield Recharge Time
                    };
                    return `<span class="text-outline" style="color: ${colorMap[stat]};">+${(amount * 0.1)}% ${normalizeStatType(stat)}</span>`;
                }

                // Handle negative amounts correctly
                return statColor(`${amount < 0 ? '-' : '+'}${Math.abs(amount)} ${normalizeStatType(stat)}`);
            })

            .join('<br>') + '<br>';
};

const getOnInventoryText = (obj) => {
    const ActivateOnInventoryArray = obj.querySelectorAll('ActivateOnInventory');

    if (!ActivateOnInventoryArray.length) return 'No equip stat'; // Return empty string if no stats

    return '<b>While in Inventory:</b> <br>' +
        Array.from(ActivateOnInventoryArray)
            .map(el => {
                let amount = parseInt(el.getAttribute('amount'), 10);
                let stat = el.getAttribute('stat');

                // Check if stat is one of the special ones that require percentage conversion
                if (["132", "138", "139", "140"].includes(stat)) {
                    return `+${(amount * 0.1)}% ${normalizeStatType(stat)}`;
                }

                // Handle negative amounts correctly
                return `${amount < 0 ? '- ' : '+ '}${Math.abs(amount)} ${normalizeStatType(stat)}`;
            })

            .join('<br>') + '<br>';
}

const getItemEffectText = (obj) => {
    const txt = equipmentTooltip.specialEffectsText[indexSpecialEffects[getText(obj, 'ItemEffect')]]
    const color = equipmentTooltip.specialEffectsColors[indexSpecialEffects[getText(obj, 'ItemEffect')]]
    return `<span class="text-outline" style="color: ${color};">${txt}</span>`
}


const getActivateText = (obj) => {
    const ActivateArray = obj.querySelectorAll('Activate');

    if (!ActivateArray.length) return 'No equip stat';

    if (getText(obj, 'Activate') !== 'Mask') return 'On Use: <br>' +
        Array.from(ActivateArray)
            .map(el => {
                const key = indexActivateText[el.textContent] || 'GENERIC_ACTIVATE';

                // Extract attributes from XML
                const params = {
                    stat: el.getAttribute('stat') || "",
                    amount: Number(el.getAttribute('amount')) || 0,
                    duration: Number(el.getAttribute('duration')) || 0,
                    range: Number(el.getAttribute('range')) || 0,
                    condition: el.getAttribute('effect') || "",
                    totalDamage: Number(el.getAttribute('totalDamage')) || 0,
                    impactDmg: Number(el.getAttribute('impactDmg')) || 0,
                    radius: Number(el.getAttribute('radius')) || 0,
                    healAmount: Number(el.getAttribute('healAmount')) || 0,
                    maxTargets: Number(el.getAttribute('maxTargets')) || 0,
                    name: el.getAttribute('name') || "",
                    className: el.getAttribute('className') || "",
                    currencyName: el.getAttribute('currencyName') || "",
                    objectId: el.getAttribute('objectId') || "",
                    chance: Number(el.getAttribute('chance')) || 0,
                    pieceName: el.getAttribute('pieceName') || "",
                    stacking: el.getAttribute('stacking') || "",
                    airTime: Number(el.getAttribute('airTime')) || 0,
                    type: el.getAttribute('type') || ""
                };

                // Get text from the dictionary function
                let txt = ''
                if (el.textContent !== 'GenericActivate') {
                    txt = parseActivateText(params)[key]
                }
                if (el.textContent == 'GenericActivate') {
                    const target = el.getAttribute('target')
                    const effect = el.getAttribute('effect')
                    const duration = el.getAttribute("duration")
                    const hasArea = el.getAttribute("range") ? ` within <b>${el.getAttribute("range")}</b> sqrs` : ""
                    const where = el.getAttribute("center") ? ` at ${el.getAttribute("center")}` : ""

                    txt = `On ${target.replace('y', 'ies')}: ${statColor(effect)}${hasArea}${where} for ${statColor(duration)} secs`
                }

                return txt || null;
            })
            .filter(Boolean) // Remove null/empty values
            .join('<br>');

    if (getText(obj, 'Activate') == 'Mask') return `Mask: ${statColor(`Applies Rage for ${getText(obj, 'MaskDesc Duration')} secs`)} <br>
    Rage: ${statColor("Gain small amount of Rage every time you hit a boss")}<br>
    During Rage: <br>` +
        Array.from(obj.querySelectorAll('MaskBoost'))
            .map(el => {
                let amount = parseInt(el.getAttribute('amount'), 10);
                let stat = el.getAttribute('stat');

                if (["132", "138", "139", "140"].includes(stat)) {
                    const colorMap = {
                        "116": "#C0C0C0", // Maximum Shield
                        "125": "#f2f287", // Loot Boost
                        "132": "#495DCC", // Damage Reduction
                        "138": "#e27b2d", // Critical Hit Chance
                        "139": "#FFBB32", // Critical Hit Multiplier
                        "140": "#8899FF", // Dodge Chance
                        "144": "#72BF26"  // Shield Recharge Time
                    };
                    return `<span class="text-outline" style="color: ${colorMap[stat]};">+${(amount * 0.1)}% ${normalizeStatType(stat)}</span>`;
                }

                // Handle negative amounts correctly
                return statColor(`${amount < 0 ? '-' : '+'}${Math.abs(amount)} ${normalizeStatType(stat)}`);
            })

            .join('<br>') + '<br>';

};

const getProjectileText = (obj) => {
    const NumProjectiles = getText(obj, 'NumProjectiles') || '1'
    let Damage = getText(obj, 'Damage')
    const MinDamage = getText(obj, "MinDamage") || getText(obj, 'Damage') + ' <b>-></b> ' + getText(obj, 'AlternativeDamage')
    const MaxDamage = getText(obj, "MaxDamage") || MinDamage
    const LifetimeMS = getText(obj, "LifetimeMS")
    const Speed = getText(obj, "Speed")
    const RateOfFire = getText(obj, 'RateOfFire')
    const Range = Math.round(Speed * LifetimeMS / 10000 * 100) / 100
    const ArcGap = getText(obj, 'ArcGap')

    let projProperties = ''

    if (obj.querySelector('Projectile')) {
        obj.querySelector('Projectile').childNodes.forEach(node => {
            if (!equipmentTooltip.projectileProperties[node.nodeName]) return
            let isArmorPiercing = false
            if (node.nodeName == "ArmorPiercing") isArmorPiercing = true
            projProperties += statColor(`${equipmentTooltip.projectileProperties[node.nodeName]}<br>`, isArmorPiercing)
        });
    }

    let ConditionEffectArray = obj.querySelectorAll('Projectile:not([id="1"]) ConditionEffect');

    let condEffText = '<br>'

    if (obj.querySelector('ConditionEffect')) {
        ConditionEffectArray.forEach(ce => {
            if (ce.textContent) {
                condEffText += `Inflicts <b>${ce.textContent}</b> for <b>${ce.getAttribute('duration')}</b> secs<br>`
            }
        });
    }

    if (!getBool(obj, 'Explode')) {
        return `
        <span class="">Shots:  ${statColor(NumProjectiles)}<br></span> 
            <span class="${showOrHideClass(obj, 'ConditionEffect')}">Shot Effects: ${statColor(condEffText)}</span> 
        <span class="">Damage: ${statColor(MinDamage == MaxDamage ? MinDamage : `${MinDamage} - ${MaxDamage}`)}<br></span> 
        <span class="">Range: ${statColor(getBool(obj, 'Boomerang') ? Range / 2 : Range)}<br></span> 
        <span class="${showOrHideClass(obj, 'RateOfFire')}">Rate of Fire: ${statColor(RateOfFire * 100 + '%')}<br></span> 
        <span class="${showOrHideClass(obj, 'ArcGap')}">Arc Gap: ${statColor(ArcGap)}<br></span> 
        ${projProperties}
        `
    } else {
        const ExplodeSpeed = getText(obj, 'Explode Speed')
        const ExplodeLifetimeMS = getText(obj, 'Explode LifetimeMS')
        const explodeRange = Math.round(ExplodeSpeed * ExplodeLifetimeMS / 10000 * 100) / 100
        const shotstxt = `${NumProjectiles} <b>=></b> ${obj.querySelector('Explode').getAttribute('numProjectiles')}`
        const dmgtxt = `${MinDamage == MaxDamage ? MinDamage : `${MinDamage} - ${MaxDamage}`} <b>=></b> ${obj.querySelector('Explode Damage')?.textContent}`
        const rangetxt = `${getBool(obj, 'Boomerang') ? Range / 2 : Range} <b>=></b> ${explodeRange}`
        return `
        <span class="">Shots: ${statColor(shotstxt)}<br></span> 
        <span class="">Damage: ${statColor(dmgtxt)}<br></span> 
        <span class="">Range: ${statColor(rangetxt)}<br></span> 
        <span class="${showOrHideClass(obj, 'RateOfFire')}">Rate of Fire: ${statColor(RateOfFire * 100 + '%')}<br></span> 
        <span class="${showOrHideClass(obj, 'ArcGap')}">ArcGap: ${statColor(ArcGap)}<br></span> 
        ${projProperties}
        `
    }

}

getEffectInfoText = (obj) => {
    const EffectInfoArray = obj.querySelectorAll('EffectInfo')
    if (!EffectInfoArray.length) return 'No effect'; // Return empty string if no stats

    return Array.from(EffectInfoArray)
        .map(el => {
            const color = el.getAttribute('descriptionColor');
            const htmlColor = `#${parseInt(color, 16).toString(16).padStart(6, '0')}`;
            return `${el.getAttribute('name') ? `${el.getAttribute('name')}: ` : ''} 
                        <span class="text-outline" style="color: ${htmlColor == '#000NaN' ? '#f2f287' : htmlColor};">${el.getAttribute('description')}</span>`;
        })

        .join('<br>') + '<br>';
}

getTransformResultText = (obj) => {
    if (getBool(obj, 'Transformed')) {
        return `Transformed from: <b>${getText(obj, 'TransformResult')}</b>`
    } else {
        return `Transforms into: <b>${getText(obj, 'TransformResult')}</b>`
    }
}

getMpCostText = (obj) => 'MP Cost: ' + statColor(getText(obj, 'MpCost'))
getHpDrainCostText = (obj) => 'HP Drain: ' + statColor(getText(obj, 'HpDrainCost') + ' <b>-></b> ' + getText(obj, 'AlternativeHpDrainCost'))
const geth3Text = obj => {
    const rarity = normalizeBagType(getText(obj, 'BagType'))
    const slot = normalizeSlotType(getText(obj, 'SlotType'))
    return `<span class="${rarity} text-outline">${rarity} ${slot.category}</span>`
}


const separator = () => addElement('div', 'separator')
const containerFragment = () => addElement('div', 'equipment')
const h2 = (obj) => addElement('h2', 'h2', obj.getAttribute('id'))
const h3 = (obj) => addElement('h3', 'h3', geth3Text(obj))
const Description = (obj) => addElement('p', 'Description', `“${getText(obj, 'Description')}”`)
const AwakenedEffects = (obj) => addElement('p', showOrHideClass(obj, 'AwakenedEffects'), getAwakeningText(obj));
const ReskinOf = (obj) => addElement('p', showOrHideClass(obj, 'ReskinOf'), getReskinOfText(obj))
const Projectile = (obj) => addElement('p', showOrHideClass(obj, 'Projectile'), getProjectileText(obj))

const onEquip = (obj) => addElement('p', showOrHideClass(obj, 'ActivateOnEquip'), getOnEquipStats(obj))
const FameBonus = (obj) => addElement('p', showOrHideClass(obj, 'FameBonus'), 'Fame Bonus: ' + statColor(getText(obj, 'FameBonus') + '%'))
const ItemEffect = (obj) => addElement('p', showOrHideClass(obj, 'ItemEffect'), getItemEffectText(obj))
const Activate = (obj) => addElement('p', showOrHideClass(obj, 'Activate'), getActivateText(obj))
const ActivateOnInventory = (obj) => addElement('p', showOrHideClass(obj, 'ActivateOnInventory'), getOnInventoryText(obj))
const Cooldown = (obj) => addElement('p', showOrHideClass(obj, 'Cooldown'), `Cooldown: ${statColor(`${getText(obj, 'Cooldown')} secs`)}`)

const EffectInfo = (obj) => addElement('p', showOrHideClass(obj, 'EffectInfo'), getEffectInfoText(obj))
/* follows template */
const TransformResult = (obj) => addElement('p', showOrHideClass(obj, 'TransformResult'), getTransformResultText(obj))
const MpCost = (obj) => addElement('p', showOrHideClass(obj, 'MpCost'), getMpCostText(obj))

const HpDrainCost = (obj) => addElement('p', showOrHideClass(obj, 'HpDrainCost'), getHpDrainCostText(obj))


//const template = (obj) => addElement('p', showOrHideClass(obj, 'template'), gettemplateText(obj))
//gettemplateText = (obj) => {}

const DefaultCooldown = (obj) => addElement('p', '-', `Cooldown: ${statColor('0.5 secs')}`)