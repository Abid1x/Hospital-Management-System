document.addEventListener("DOMContentLoaded", () => {
    const tables = document.querySelectorAll("table");

    tables.forEach(table => {
        enhanceTable(table);
    });
});

function enhanceTable(table) {
    addSearch(table);
    makeSortable(table);
    stripeRows(table);
}

function addSearch(table) {
    const wrapper = document.createElement("div");
    wrapper.style.margin = "15px 0";

    const input = document.createElement("input");
    input.type = "text";
    input.placeholder = "Search table...";
    input.style.padding = "8px";
    input.style.width = "250px";

    input.addEventListener("input", () => {
        const filter = input.value.toLowerCase();
        const rows = table.querySelectorAll("tbody tr");

        rows.forEach(row => {
            const text = row.innerText.toLowerCase();
            row.style.display = text.includes(filter) ? "" : "none";
        });
    });

    wrapper.appendChild(input);
    table.parentNode.insertBefore(wrapper, table);
}

function makeSortable(table) {
    const headers = table.querySelectorAll("th");

    headers.forEach((th, index) => {
        let asc = true;

        th.style.cursor = "pointer";
        th.addEventListener("click", () => {
            sortTable(table, index, asc);
            asc = !asc;
        });
    });
}

function sortTable(table, columnIndex, asc) {
    const tbody = table.querySelector("tbody");
    const rows = Array.from(tbody.querySelectorAll("tr"));

    rows.sort((a, b) => {
        const aText = a.children[columnIndex].innerText;
        const bText = b.children[columnIndex].innerText;
        return asc
            ? aText.localeCompare(bText, undefined, { numeric: true })
            : bText.localeCompare(aText, undefined, { numeric: true });
    });

    rows.forEach(row => tbody.appendChild(row));
}

function stripeRows(table) {
    const rows = table.querySelectorAll("tbody tr");
    rows.forEach((row, index) => {
        row.style.background = index % 2 === 0 ? "#f9f9f9" : "white";
    });
}
