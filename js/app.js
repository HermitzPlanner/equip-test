function loadXML() {
    // Change 'data.xml' to the path of your XML file
    fetch('assets/11_rotmg.assets.EmbeddedData_CustomEquipCXML.xml')
        .then(response => {
            if (!response.ok) {
                throw new Error('Network response was not ok');
            }
            return response.text();
        })
        .then(xmlString => {
            // Parse the XML string into an XML Document
            const parser = new DOMParser();
            const xmlDoc = parser.parseFromString(xmlString, "application/xml");
            displayEquipment(xmlDoc);
        })
        .catch(error => console.error('Error loading the XML:', error));
}

function filterEquipment(objects) {
    const equipmentArray = Array.from(objects).filter(object => {
        const classElement = object.querySelector("Class");
        return classElement && classElement.textContent.trim() === "Equipment";
    });

    // Remove admin items code
    const adminFilteredObjectsArray = equipmentArray.filter(object => {
        const effectInfo = object.querySelector("EffectInfo");

        if (effectInfo) {
            const nameAttribute = effectInfo.getAttribute("name");
            const descriptionAttribute = effectInfo.getAttribute("description");

            // Remove object if either attribute equals "Admin Item"
            return nameAttribute !== "Admin Item" && descriptionAttribute !== "Admin Item";
        }

        return true; // Keep objects without an EffectInfo element
    });

    const priorityOrder = [13, 12, 14, 10, 6, 4]; // Define priority order

    const sortedEquipmentArray = adminFilteredObjectsArray.sort((a, b) => {
        const aBagTypeElement = a.querySelector("BagType");
        const bBagTypeElement = b.querySelector("BagType");

        const aBagType = aBagTypeElement ? parseInt(aBagTypeElement.textContent.trim(), 10) : 0;
        const bBagType = bBagTypeElement ? parseInt(bBagTypeElement.textContent.trim(), 10) : 0;

        const aPriority = priorityOrder.indexOf(aBagType);
        const bPriority = priorityOrder.indexOf(bBagType);

        // Sort based on priority; items not in priorityOrder will be pushed to the end
        if (aPriority === -1 && bPriority === -1) return 0; // Both not in priorityOrder
        if (aPriority === -1) return 1;  // a not in priorityOrder
        if (bPriority === -1) return -1; // b not in priorityOrder
        return aPriority - bPriority;    // Sort by priority index
    })

    const reskinsMovedArray = adminFilteredObjectsArray.sort((a, b) => {
        const aHasTransformed = a.querySelector('Transformed') !== null;
        const aHasReskinOf = a.querySelector('ReskinOf') !== null;

        const bHasTransformed = b.querySelector('Transformed') !== null;
        const bHasReskinOf = b.querySelector('ReskinOf') !== null;

        // Assign a priority value: 0 = no selector, 1 = Transformed, 2 = ReskinOf
        const aPriority = aHasReskinOf ? 2 : aHasTransformed ? 1 : 0;
        const bPriority = bHasReskinOf ? 2 : bHasTransformed ? 1 : 0;

        return aPriority - bPriority;
    });



    return reskinsMovedArray
}

function displayEquipment(xmlDoc) {
    const objects = xmlDoc.getElementsByTagName('Object');
    const array = filterEquipment(objects)
    // .slice(0, 200)
    array.forEach(obj => {
        if (obj.id && obj.id.includes("Test")) return

        const label = document.createElement('label')
        label.htmlFor = normalizeId(obj.getAttribute('id'))

        const input = document.createElement('input')
        input.type = 'checkbox'
        input.classList.add('cbox-equip')
        input.id = normalizeId(obj.getAttribute('id'))

        label.append(input)

        const container = containerFragment()
        const getText = (key) => obj.querySelector(key)?.textContent.trim() || null;
        const slot = normalizeSlotType(getText("SlotType"))
        const bag = normalizeBagType(getText("BagType"))

        container.append(canvas(obj))
        container.append(h2(obj))
        container.append(h3(obj))
        // container.append(Description(obj))
        container.append(separator())
        container.append(TransformResult(obj))
        container.append(AwakenedEffects(obj))
        container.append(ReskinOf(obj))
        container.append(EffectInfo(obj))
        container.append(Projectile(obj))
        container.append(Activate(obj))
        container.append(onEquip(obj))
        container.append(ActivateOnInventory(obj))
        container.append(FameBonus(obj))
        container.append(MpCost(obj))
        container.append(HpDrainCost(obj))
        container.append(Cooldown(obj))
        if (slot.slot == "Ability" && !obj.querySelector('Cooldown')) container.append(DefaultCooldown(obj))
        if (obj.querySelector('ItemEffect')) container.append(separator())
        container.append(ItemEffect(obj))
        container.append(separator())
        container.append(Description(obj))
        container.setAttribute('data-slot', slot.slot)
        container.setAttribute('data-category', slot.category)
        container.setAttribute('data-rarity', bag)

        label.append(container)

        document.getElementById('equipment-container').append(label);


    });

    // clickDiv('equip-abilities-filter')
     
    clickDiv('equip-weapons-filter')
    clickDiv('equip-legendary-filter')
    cboxLogic()


    console.log("Array.from(objects).length", Array.from(objects).length)
}

function cboxLogic() {
    const cboxArray = document.querySelectorAll('.cbox-equip');
    const viewer = document.getElementById('viewer');
    const main = document.getElementById('main');

    cboxArray.forEach(cbox => {
        cbox.addEventListener('click', () => {

            hideInfoLogic(cbox)

            //viewerLogic(cbox)

        });
    });
}

function hideInfoLogic(cbox) {
    const separators = cbox.nextElementSibling.querySelectorAll('.separator');
    const pElements = cbox.nextElementSibling.querySelectorAll('p:not(.no-display)');
    const displayValue = cbox.checked ? 'block' : 'none';

    separators.forEach(sep => sep.style.display = displayValue);
    pElements.forEach(p => p.style.display = displayValue);
}

function viewerLogic(cbox) {
    if (getComputedStyle(main).display !== 'none') {
        main.style.display = 'none'; // Hide main
        viewer.style.display = 'flex'; // Show viewer
    }

    // Grab the sibling of the clicked cbox
    const sibling = cbox.nextElementSibling;

    if (sibling) {
        // Clone the sibling and append it to the viewer
        const clonedSibling = sibling.cloneNode(true);
        viewer.appendChild(clonedSibling);

        // Get all <p> elements inside the cloned sibling and remove display: none
        const pElements = clonedSibling.querySelectorAll('p:not(.no-display)');
        pElements.forEach(p => {
            p.style.display = 'block'; // Reset display to default (block or inline)
        });

        // If there is a canvas element inside the sibling, copy the canvas content
        const originalCanvas = sibling.querySelector('canvas');
        const clonedCanvas = clonedSibling.querySelector('canvas');

        if (originalCanvas && clonedCanvas) {
            const context = originalCanvas.getContext('2d');
            const clonedContext = clonedCanvas.getContext('2d');

            // Copy the content of the original canvas to the cloned canvas
            clonedContext.drawImage(originalCanvas, 0, 0);
        }
    }
}

function quitViewer() {
    if (getComputedStyle(main).display == 'none') {
        main.style.display = 'block'; // Hide main
        viewer.style.display = 'none'; // Show viewer
        viewer.querySelector('.equipment').remove()
    }
}





function clickDiv(s) {
    document.getElementById(s).click()
}

// Load the XML when the page is loaded
document.addEventListener('DOMContentLoaded', loadXML);
