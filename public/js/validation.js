function isNumber(input) {
    if(!input || input === '') {
        return false;
    }

    for (let i = 0; i < input.length; i++) {
        const charCode = input.charCodeAt(i);
        if (charCode < 48 || charCode > 57) {
            return false;
        }
    }
    return true;
}

function isAlphabet(input) {
    if(!input || input.trim() === '') {
        return false;
    }

    for (let i = 0; i < input.length; i++) {
        const charCode = input.charCodeAt(i);
        if (
            !(charCode === 32 || (charCode >= 65 && charCode <= 90) || (charCode >= 97 && charCode <= 122))
          ) {
            return false;
          }
    }
    return true;
}

function isAlphabetWords(input) {
    if (!input || input.trim() === '') {
        return false;
    }

    const words = input.split(' ');

    for (const word of words) {
        for (let i = 0; i < word.length; i++) {
            const charCode = word.charCodeAt(i);
            if ((charCode < 65 || charCode > 90) && (charCode < 97 || charCode > 122)) {
                return false;
            }
        }
    }

    return true;
}


function isAlphaNumeric(input) {
    if(!input || input === '') {
        return false;
    }

    for (let i = 0; i < input.length; i++) {
        const charCode = input.charCodeAt(i);
        if (
            (charCode < 48 || charCode > 57) && // Numeric characters
            (charCode < 65 || charCode > 90) && // Uppercase letters
            (charCode < 97 || charCode > 122)   // Lowercase letters
        ) {
            return false;
        }
    }
    return true;
}

function isValidEmail(input) {
    if(!input || input === '') {
        return false;
    }
    
    // Check for a valid format
    if (input.indexOf('@') === -1) {
      return false;
    }
  
    const parts = input.split('@');
    if (parts.length !== 2 || parts[0].length === 0 || parts[1].length === 0) {
      return false;
    }
  
    // Check the domain part
    const domainParts = parts[1].split('.');
    if (domainParts.length < 2) {
      return false;
    }
    for (const part of domainParts) {
      if (part.length === 0) {
        return false;
      }
    }
  
    return true;
}
  
function parseNumberZeroToHundred(input) {
    const numberInput = parseFloat(input);
    if (isNaN(numberInput) || numberInput < 0) {
      return 0;
    }
    return Math.min(numberInput, 100);
}

function parseNumberGreaterThanZero(input) {
    const numberInput = parseFloat(input);
    if (isNaN(numberInput) || numberInput < 0) {
      return 1;
    }
    return numberInput;
}

function parsePositiveNumber(input) {
    const numberInput = parseFloat(input);
    if (isNaN(numberInput) || numberInput < 0) {
      return 0;
    }
    return numberInput;
}
  