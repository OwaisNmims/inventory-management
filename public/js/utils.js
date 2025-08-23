function createSelectOptions(selectOptions) {
    const selectElement = $(selectOptions.selector);
    selectElement.empty();

    if (selectOptions.data.length === 0) {
        const option = $('<option>');
        option.val('').text('No data found.');
        selectElement.append(option);
        return false;
    }

    const keys = Object.keys(selectOptions.data[0]);

    selectOptions.data.forEach(state => {

        const option = $('<option>');

        for (const key of keys) {
            option.attr(`data-${key}`, state[key]);
        }

        const textValue = state[selectOptions.textAttr];
        const valueValue = state[selectOptions.valueAttr];

        option.val(valueValue).text(textValue);
        selectElement.append(option);
    });
}

function updateSerialNumbers(elemSelector) {
    $(`${elemSelector}`).each(function (index) {
        $(this).find('td:first-child').text(index + 1);
    });
}


function formatISODateToCustom(dateString) {
    const date = new Date(dateString);

    const day = String(date.getDate()).padStart(2, '0');
    const month = String(date.getMonth() + 1).padStart(2, '0');
    const year = date.getFullYear();

    const hours = String(date.getHours()).padStart(2, '0');
    const minutes = String(date.getMinutes()).padStart(2, '0');
    const seconds = String(date.getSeconds()).padStart(2, '0');

    return `${day}-${month}-${year} ${hours}:${minutes}:${seconds}`;
}