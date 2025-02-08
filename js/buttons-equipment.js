let searchTerm = ""
let btnValue = ""
let btnSlot = "All"
let btnRarity = "All"
let btnCategory = "All"

const allButtons = document.querySelectorAll('input[type="radio"]')
allButtons.forEach(btn => {
    btn.addEventListener("click", () => {
        if (btn.name == "slot") {
            btnSlot = btn.value
            renderRow3(btn.value)
            btnCategory = "All"
        }
        if (btn.name == "rarity") btnRarity = btn.value
        revealItem()
    })
});

document.getElementById('search-input').addEventListener('input', function () {
    searchTerm = this.value.toLowerCase().trim();
    revealItem()
});

function revealItem() {

    const equipmentArray = document.querySelectorAll('.equipment')
    equipmentArray.forEach(container => {
        const itemName = container.querySelector('.h2').textContent.toLowerCase().trim();
        const itemSlot = container.getAttribute('data-slot')
        const itemRarity = container.getAttribute('data-rarity')
        const itemCategory = container.getAttribute('data-category')

        const labelElement = container.parentElement

        itemName.includes(searchTerm) ? visible(labelElement) : invis(labelElement);

        // Look only for the current visible items
        if (labelElement.classList.contains('visible')) {
            const shouldBeVisible =
                (btnSlot === "All" || itemSlot == btnSlot) &&
                (btnRarity === "All" || itemRarity == btnRarity) &&
                (btnCategory === "All" || itemCategory == btnCategory);

            shouldBeVisible ? visible(labelElement) : invis(labelElement);
        }

    });
}

function visible(element) {
    element.classList.add('visible');
    element.classList.remove('invis');

    setTimeout(() => {
        element.classList.remove('visible'); // Remove after 0.5s
    }, 500);
}


function invis(element) {
    element.classList.add('invis');
    element.classList.remove('visible');
}

function renderRow3(row1Value) {
    const rowDiv = document.getElementById("equipment-buttons-row-3")
    rowDiv.innerHTML = ""

    if (row1Value == "Ring" || row1Value == "Consumable" || row1Value == "All") return
    createButton("All", 0, rowDiv)


    let delay = 0
    const slotMapping = normalizeSlotType("all")
    for (const key in slotMapping) {
        if (slotMapping[key].slot === row1Value) {
            createButton(slotMapping[key].category, delay, rowDiv)

            // Increase the delay for the next button
            delay += 0.05;  // Adjust this value for faster/slower animation
        }
    }
}

function createButton(category, delay, rowDiv) {
    // Create the input element
    const inputElement = document.createElement('input');
    inputElement.type = 'radio';
    inputElement.name = 'category';
    inputElement.value = category;
    logicForRow3(inputElement, category)

    // Create the div
    const createdDiv = document.createElement('div')
    createdDiv.classList.add("equipment-radio")
    createdDiv.classList.add("equipment-row-3")
    createdDiv.textContent = category;

    // Create the label element
    const buttonCreated = document.createElement('label');

    // Append the input to the label
    buttonCreated.prepend(createdDiv);
    buttonCreated.prepend(inputElement);

    // Apply the animation with a delay
    buttonCreated.classList.add('button-slide');
    buttonCreated.style.animationDelay = `${delay}s`;

    // Append the button to the container
    rowDiv.appendChild(buttonCreated, delay);
}

function logicForRow3(element, category) {
    element.onclick = function () {
        btnCategory = category
        revealItem()
    }
}