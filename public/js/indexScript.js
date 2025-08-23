//================================== Sagar Js START ==================================//

//  Step form script START
var currentTab = 0;
// Current tab is set to be the first tab (0)
showTab(currentTab);
// Display the current tab

function showTab(n) {
  // This function will display the specified tab of the form...
  var x = document.getElementsByClassName("tab"); // all tab class selected in array
  x[n].style.display = "block";
  //... and fix the Previous/Next buttons:
  if (n == 0) {
    document.getElementById("prevBtn").style.display = "none";
  } else {
    document.getElementById("prevBtn").style.display = "inline";
  }
  if (n == x.length - 1) {
    document.getElementById("nextBtn").innerHTML = "Submit";
  } else {
    document.getElementById("nextBtn").innerHTML = "Next";
  }
  //... and run a function that will display the correct step indicator:
  fixStepIndicator(n);
}

function nextPrev(n) {
  // This function will figure out which tab to display
  var x = document.getElementsByClassName("tab");
    console.log("currentTab >>>>>>>",currentTab);
    console.log("x >>>>>>>",x);
  // Exit the function if any field in the current tab is invalid:
  //   if (n == 1 && !validateForm()) return false;
  // Hide the current tab:
  x[currentTab].style.display = "none";
  // Increase or decrease the current tab by 1:
  currentTab = currentTab + n;
  // if you have reached the end of the form...
  if (currentTab >= x.length) {
    // ... the form gets submitted:
    document.getElementById("regForm").submit();
    return false;
  }
  // Otherwise, display the correct tab:
  showTab(currentTab);
}

// function validateForm() {
//   // This function deals with validation of the form fields
//   var x, y, i, valid = true;
//   x = document.getElementsByClassName("tab");
//   y = x[currentTab].getElementsByTagName("input");
//   // A loop that checks every input field in the current tab:
//   for (i = 0; i < y.length; i++) {
//     // If a field is empty...
//     if (y[i].value == "") {
//       // add an "invalid" class to the field:
//       y[i].className += " invalid";
//       // and set the current valid status to false
//       valid = false;
//     }
//   }
//   // If the valid status is true, mark the step as finished and valid:
//   if (valid) {
//     document.getElementsByClassName("step")[currentTab].className += " finish";
//   }
//   return valid; // return the valid status
// }

function fixStepIndicator(n) {
  // This function removes the "active" class of all steps...
  var i,
    x = document.getElementsByClassName("step");

  for (i = 0; i < x.length; i++) {
    x[i].className = x[i].className.replace(" active", "");
  }
  //... and adds the "active" class on the current step:
  x[n].className += " active";
}
//  Step form script END

//  CUSTOM JS SCRIPT

const actionBtn = `
  <div class="action-btns">
      <a href="javascript:void(0);"
          class="action-btn btn-edit bs-tooltip me-2"
          data-toggle="tooltip" data-placement="top" title="Edit">
          <svg xmlns="http://www.w3.org/2000/svg" width="24"
              height="24" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" stroke-width="2"
              stroke-linecap="round" stroke-linejoin="round"
              class="feather feather-edit-2">
              <path
                  d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z">
              </path>
          </svg>
      </a>
      <a href="javascript:void(0);"
          class="action-btn btn-delete bs-tooltip"
          data-toggle="tooltip" data-placement="top"
          title="Delete">
          <svg xmlns="http://www.w3.org/2000/svg" width="24"
              height="24" viewBox="0 0 24 24" fill="none"
              stroke="currentColor" stroke-width="2"
              stroke-linecap="round" stroke-linejoin="round"
              class="feather feather-trash-2">
              <polyline points="3 6 5 6 21 6"></polyline>
              <path
                  d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2">
              </path>
              <line x1="10" y1="11" x2="10" y2="17"></line>
              <line x1="14" y1="11" x2="14" y2="17"></line>
          </svg>
      </a>
  </div>`

// ========== passenger js START ========== //
let addPassenger = document.querySelector(".add-passenger");

let passengerType;
let noOfPassengers;
let occupancy;
let isPayabal;
let addTable = document.querySelector("#add-passenger-table tbody");

let tableRow = ``;
let count = 0;

$(document).on("click",'.add-passenger', function (e) {
  e.preventDefault();

  passengerType = document.querySelector("#passenger-type").value;
  noOfPassengers = document.querySelector("#no-passengers").value;
  occupancy = document.querySelector("#occupancy").value;
  isPayabal = document.querySelector("#is-payable").checked ? "Yes" : "No";
  payableAmount = document.querySelector("#payable-amount").value ;
  payablePercentage = document.querySelector("#payable-percentage").value + "%";
  if(isPayabal == "No") {
    payableAmount = "--"
    payablePercentage = "--"
  } 

  tableRow = `<tr>
                        <td>${++count}</td>
                        <td>${passengerType}</td>
                        <td>${noOfPassengers}</td>
                        <td>${occupancy}</td>
                        <td>${isPayabal}</td>
                        <td>${payableAmount}</td>
                        <td>${payablePercentage}</td>
                        

                        <td class="text-center">
                    <div class="action-btns">
                        <a href="javascript:void(0);"
                            class="action-btn btn-delete bs-tooltip"
                            data-toggle="tooltip" data-placement="top"
                            title="Delete">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24"
                                height="24" viewBox="0 0 24 24" fill="none"
                                stroke="currentColor" stroke-width="2"
                                stroke-linecap="round" stroke-linejoin="round"
                                class="feather feather-trash-2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path
                                    d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2">
                                </path>
                                <line x1="10" y1="11" x2="10" y2="17"></line>
                                <line x1="14" y1="11" x2="14" y2="17"></line>
                            </svg>
                        </a>
                    </div>
                </td>
                    </tr>`;
  addTable.innerHTML += tableRow;
  // console.log('clicked!!', addPassenger)
});

// payabal div show script START

function payebleFunction() {
  const payableDiv = document.getElementById("payable-div");
  payableDiv.classList.toggle("hidden");
}
// payabal div show script END

// ========== passenger js END ========== //

//  hotel js start

let addHotel = document.querySelector(".add-hotel");

let country;
let state;
let city;
let stayDay;
let stayNight;
let hotelPassengerType;
let hotelNoOfPassengers;
let hotelOccupancy;
let hotelName;
let roomType;
let roomCapacity;
let maxCapacity;

let hotelAddTable = document.querySelector("#add-hotel-table tbody");

let hotelTableRow = ``;
let hotelCount = 0;

addHotel.addEventListener("click", function (e) {
  e.preventDefault();

  country = document.querySelector("#hotel-country").value;
  state = document.querySelector("#hotel-state").value;
  city = document.querySelector("#hotel-city").value;
  stayDay = document.querySelector("#stay-day").value;
  stayNight = document.querySelector("#stay-night").value;
  hotelPassengerType = document.querySelector("#hotel-passenger-type").value;
  hotelNoOfPassengers = document.querySelector("#hotel-no-passengers").value;
  hotelOccupancy = document.querySelector("#hotel-occupancy").value;
  hotelName = document.querySelector("#hotel-name").value;
  roomType = document.querySelector("#hotel-room-type").value;
  roomCapacity = document.querySelector("#room-capacity").value;
  maxCapacity = document.querySelector("#max-capacity").value;

  hotelTableRow = `<tr>
                        <td>${++hotelCount}</td>
                        <td>${country}</td>
                        <td>${state}</td>
                        <td>${city}</td>
                        <td>${stayDay} Days ${stayNight} Night</td>
                        <td>${hotelPassengerType}</td>
                        <td>${hotelNoOfPassengers}</td>
                        <td>${hotelOccupancy}</td>
                        <td>${hotelName}</td>
                        <td>${roomType}</td>
                        <td>${roomCapacity}</td>
                        <td>${maxCapacity}</td>
                        <td class="text-center">${actionBtn} </td>
                    </tr>`;
  hotelAddTable.innerHTML += hotelTableRow;
  // console.log('clicked!!', addPassenger)
});

// hotel js end

// ==transport script START== //

// Function to create a new div with a delete button
function createDiv() {
  var div = document.createElement("div");
  // div.className = 'alert alert-info mt-2';
  // div.textContent = 'New div';
  div.innerHTML = `<div class="row mb-1 py-2" style="background-color: #e0e6ed;">
                <div class="col-lg-3 col-md-6">
                    <div class="input-group mb-3 d-flex flex-column">
                        <label>Mode of transport</label>
                        <select class="input" id="student-mode">
                            <option value="">Select mode of
                                transport...
                            </option>
                            <option value="Flight">Flight
                            </option>
                            <option value="Train">Train
                            </option>
                            <option value="Bus">Bus</option>
                        </select>
                    </div>
                </div>

                <div class="col-lg-3 col-md-6">
                    <div class="input-group mb-3 d-flex flex-column">
                        <label>Carrier</label>
                        <select class="input" id="student-carrier">
                            <option value="">Select
                                Carrier...
                            </option>
                            <option value="Indigo">Indigo
                            </option>
                        </select>
                    </div>
                </div>

                <div class="col-lg-2 col-md-6">
                    <div class="input-group mb-3 d-flex flex-column">
                        <label>Fare Class</label>
                        <select class="input" id="student-fare-class">
                            <option value="">Select Fare
                                Class...</option>
                            <option value="Economy">Economy
                            </option>
                            <option value="Business">
                                Business
                            </option>
                        </select>
                    </div>
                </div>

                <div class="col-lg-2 col-md-6">
                    <div class="input-group mb-3 d-flex flex-column">
                        <label>No. of Passengers</label>
                        <input type="text" name="no-of-students" id="no-of-students"
                            placeholder="Enter No. of passengers" class="w-100" value="">
                    </div>
                </div>

                <div class="col-lg-2 col-md-6">
                    <div class="input-group mb-3 d-flex flex-column">
                        <label class="form-label">Fare</label>
                        <input type="number" name="student-fare" id="student-fare" placeholder="" value=""
                            class="w-100" readonly>
                    </div>
                </div>
            </div>`;

  var deleteButton = document.createElement("button");
  deleteButton.className = "btn btn-danger btn-sm m-2";
  deleteButton.textContent = "-";
  deleteButton.onclick = function () {
    divContainer.removeChild(div);
  };

  div.appendChild(deleteButton);
  return div;
}

// Add a new div when the "Add Div" button is clicked

// document.getElementById("addDivButton").addEventListener("click", function () {
//   var divContainer = document.getElementById("divContainer");
//   divContainer.appendChild(createDiv());
// });

// ==transport script END== //

// ========== Expenses script START ========== //

let addExpenses = document.querySelector(".add-expenses");

let expensesType;
let expensesPassengerType;
let quantity;
let currency;
let unitPrice;
let totalAmount;
let dailyExpenses;
let addExpensesTable = document.querySelector("#add-expenses-table tbody");

let expensesTableRow = ``;
let expensescount = 0;

addExpenses.addEventListener("click", function (e) {
  e.preventDefault();

  expensesType = document.querySelector("#expenses-type").value;
  expensesPassengerType = document.querySelector(
    "#expenses-passenger-type"
  ).value;
  quantity = document.querySelector("#quantity").value;
  currency = document.querySelector("#currency").value;
  unitPrice = document.querySelector("#unit-price").value;
  totalAmount = document.querySelector("#total-amount").value;
  //   dailyExpenses = document.querySelector("#daily-expenses").value;

  dailyExpenses = document.querySelector("#daily-expenses").checked
    ? "Yes"
    : "No";
  expensesTableRow = `<tr>
                        <td>${++expensescount}</td>
                        <td>${expensesType}</td>
                        <td>${expensesPassengerType}</td>
                        <td>${quantity}</td>
                        <td>${currency}</td>
                        <td>${unitPrice}</td>
                        <td>${totalAmount}</td>
                        <td>${dailyExpenses}</td>
                        <td class="text-center">
                    <div class="action-btns">
                        <a href="javascript:void(0);"
                            class="action-btn btn-edit bs-tooltip me-2"
                            data-toggle="tooltip" data-placement="top" title="Edit">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24"
                                height="24" viewBox="0 0 24 24" fill="none"
                                stroke="currentColor" stroke-width="2"
                                stroke-linecap="round" stroke-linejoin="round"
                                class="feather feather-edit-2">
                                <path
                                    d="M17 3a2.828 2.828 0 1 1 4 4L7.5 20.5 2 22l1.5-5.5L17 3z">
                                </path>
                            </svg>
                        </a>
                        <a href="javascript:void(0);"
                            class="action-btn btn-delete bs-tooltip"
                            data-toggle="tooltip" data-placement="top"
                            title="Delete">
                            <svg xmlns="http://www.w3.org/2000/svg" width="24"
                                height="24" viewBox="0 0 24 24" fill="none"
                                stroke="currentColor" stroke-width="2"
                                stroke-linecap="round" stroke-linejoin="round"
                                class="feather feather-trash-2">
                                <polyline points="3 6 5 6 21 6"></polyline>
                                <path
                                    d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2">
                                </path>
                                <line x1="10" y1="11" x2="10" y2="17"></line>
                                <line x1="14" y1="11" x2="14" y2="17"></line>
                            </svg>
                        </a>
                    </div>
                </td>
                    </tr>`;
  addExpensesTable.innerHTML += expensesTableRow;
  // console.log('clicked!!', addPassenger)
});

// ========== Expenses script END ========== //

// END CUSTOM JS SCRIPT

// ================================== Sagar Js End ==================================//

//================================== Ram Js START ==================================//
// Tour Js Starts

const addTour = document.querySelector(".add-tour");
tourObj = {
    tourName: '',
    tourDays: '',
    tourNights: ''
}

const tourTable = document.querySelector('#add-tour-table tbody');


// addTour.addEventListener('click', function() {
//     tourObj.tourName = document.querySelector('.tour-name').value;
//     tourObj.tourDays = document.querySelector('.tour-days').value;
//     tourObj.tourNights = document.querySelector('.tour-nights').value;

    
// })

// Tour Js Ends




//Transport Js Start
  // Counter to give each added element a unique ID
  let elementCounter = 0;

// Add Element
$("#contain").on("click", ".add-button", function () {
  elementCounter++;
  const newElement = `<div class="pb-3 mb-4">
                            <div id="contain">
                                <div class="dynamic-element" id="element ${elementCounter}">
                                    
                                    <div class="row mb-3">
                                            <div class="col-lg-6 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label class="form-label">From</label>
                                                    <input type="text" name="from-one" id="from-one"
                                                        placeholder="Enter location" class="w-100">
                                                </div>
                                            </div>
    
                                            <div class="col-lg-6 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label class="form-label">To</label>
                                                    <input type="text" name="to-one" id="to-one"
                                                        placeholder="Enter location" class="w-100">
                                                </div>
                                            </div>
                                            <div class="my-2">
                                                <h4>Student</h4>
                                            </div>
    
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Mode of transport</label>
                                                    <select class="input" id="student-mode">
                                                        <option value="">Select mode of transport...</option>
                                                        <option value="Flight">Flight</option>
                                                        <option value="Train">Train</option>
                                                        <option value="Bus">Bus</option>
                                                    </select>
                                                </div>
                                            </div>
    
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Carrier</label>
                                                    <select class="input" id="student-carrier">
                                                        <option value="">Select Carrier...</option>
                                                        <option value="Indigo">Indigo</option>
                                                    </select>
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Fare Class</label>
                                                    <select class="input" id="student-fare-class">
                                                        <option value="">Select Fare Class...</option>
                                                        <option value="Economy">Economy</option>
                                                        <option value="Business">Business</option>
                                                    </select>
                                                </div>
                                            </div>
                                            
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>No. of Passengers</label>
                                                    <input type="text" name="no-of-students" id="no-of-students"
                                                        placeholder="Enter No. of passengers" class="w-100" value="100">
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label class="form-label">Fare</label>
                                                    <input type="number" name="student-fare" id="student-fare" placeholder="" value="3050"
                                                        class="w-100" readonly>
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Transport Type</label>
                                                    <select class="input" id="student-transport-type">
                                                        <option value="">Select Transport Type...</option>
                                                        <option value="Transfer">Transfer</option>
                                                        <option value="Local">Local</option>
                                                    </select>
                                                </div>
                                            </div>

                                            <div class="my-2">
                                                <h4>Teacher</h4>
                                            </div>
    
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Mode of transport</label>
                                                    <select class="input" id="mode-teacher">
                                                        <option value="">Select mode of transport...</option>
                                                        <option value="Flight">Flight</option>
                                                        <option value="Train">Train</option>
                                                        <option value="Bus">Bus</option>
                                                    </select>
                                                </div>
                                            </div>
    
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Carrier</label>
                                                    <select class="input" id="teacher-carrier">
                                                        <option value="">Select Carrier...</option>
                                                        <option value="Indigo">Indigo</option>
                                                    </select>
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Fare Class</label>
                                                    <select class="input" id="teacher-fare-class">
                                                        <option value="">Select Fare Class...</option>
                                                        <option value="Economy">Economy</option>
                                                        <option value="Business">Business</option>
                                                    </select>
                                                </div>
                                            </div>
                                            
                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>No. of Passengers</label>
                                                    <input type="text" name="no-of-teachers" id="no-of-teachers"
                                                        placeholder="Enter No. of passengers" class="w-100" value="2">
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label class="form-label">Fare</label>
                                                    <input type="number" name="teacher-fare" id="teacher-fare" placeholder="" value="3050"
                                                        class="w-100" readonly>
                                                </div>
                                            </div>

                                            <div class="col-lg-2 col-md-6">
                                                <div class="input-group mb-3 d-flex flex-column">
                                                    <label>Transport Type</label>
                                                    <select class="input" id="teacher-transport-type">
                                                        <option value="">Select Transport Type...</option>
                                                        <option value="Transfer">Transfer</option>
                                                        <option value="Local">Local</option>
                                                    </select>
                                                </div>
                                            </div>
                                        </div>
                             
                                        <button class="add-button btn btn-success"> + </button>
                                        <button class="delete-button btn btn-danger"> - </button>
                                    
                                </div>
                            </div>
                        </div>`;

  $("#contain").append(newElement);
});

  // Delete Element
  $("#contain").on("click", ".delete-button", function () {
    $(this).parent(".dynamic-element").remove();
    elementCounter--;
  });

  const addTransportTableBtn = document.querySelector(".add-transport");

const transportObj = {
  fromOne: "",
  toOne: "",
  transportType: "",
  student: {
    mode: "",
    carrier: "",
    fareClass: "",
    noOfPassengers: "",
    fare: "",
  },
  teacher: {
    mode: "",
    carrier: "",
    fareClass: "",
    noOfPassengers: "",
    fare: "",
  },
};

//   transportObj['student']['noOfPassengers'] = document.querySelector("#no-of-students").value;
 
  let noOfStudent = document.querySelectorAll("#no-of-students");
//   console.log("array[0]",noOfStudent[0].value)
    let totalStudent = 0;
    noOfStudent.forEach(e => {
        // console.log("E ............",e);
        totalStudent += Number(e.value); 
    });



//   console.log("node list>>>>>>",noOfStudent);
  if(totalStudent < 100) {
    const addMoreStudent = `
                            <div class="col-lg-3 col-md-6">
                                <div class="input-group mb-3 d-flex flex-column">
                                    <label>Mode of transport</label>
                                    <select class="input" id="student-mode">
                                        <option value="">Select mode of transport...</option>
                                        <option value="Flight">Flight</option>
                                        <option value="Train">Train</option>
                                        <option value="Bus">Bus</option>
                                    </select>
                                </div>
                            </div>

                            <div class="col-lg-3 col-md-6">
                                <div class="input-group mb-3 d-flex flex-column">
                                    <label>Carrier</label>
                                    <select class="input" id="student-carrier">
                                        <option value="">Select Carrier...</option>
                                        <option value="Indigo">Indigo</option>
                                    </select>
                                </div>
                            </div>

                            <div class="col-lg-2 col-md-6">
                                <div class="input-group mb-3 d-flex flex-column">
                                    <label>Fare Class</label>
                                    <select class="input" id="student-fare-class">
                                        <option value="">Select Fare Class...</option>
                                        <option value="Economy">Economy</option>
                                        <option value="Business">Business</option>
                                    </select>
                                </div>
                            </div>

                            <div class="col-lg-2 col-md-6">
                                <div class="input-group mb-3 d-flex flex-column">
                                    <label>No. of Students</label>
                                    <input type="text" name="no-of-students" id="no-of-students"
                                        placeholder="Enter No. of passengers" class="w-100"
                                        value=${Math.abs(totalStudent - 100)}>
                                </div>
                            </div>

                            <div class="col-lg-2 col-md-6">
                                <div class="input-group mb-3 d-flex flex-column">
                                    <label class="form-label">Fare</label>
                                    <input type="number" name="student-fare" id="student-fare"
                                        placeholder="" value="3050" class="w-100" readonly>
                                </div>
                            </div>`
    
    
    const parentElement = document.querySelector('.dynamic-element .student');
    const addMore = parentElement.innerHTML + addMoreStudent;
    // console.log(addMore);
    // console.log("addmore >>>>>>>>>>>>>>",parentElement.innerHTML);
    parentElement.innerHTML = addMore;                    
}

  

let addTransportTable = document.querySelector("#add-transport-table tbody");
let transportTableRow;
let transportTableRowCount = 0;

  addTransportTableBtn.addEventListener("click", function () {
      console.log("add btn clicked!!");
    transportObj.fromOne = document.querySelector("#from-one").value;
    transportObj.toOne = document.querySelector("#to-one").value;
    transportObj.transportType = document.querySelector("#transport-type").value;
    transportObj['student']['mode'] = document.querySelector("#student-mode").value;
    transportObj['student']['carrier'] = document.querySelector("#student-carrier").value;
    transportObj['student']['fareClass'] = document.querySelector("#student-fare-class").value;
    transportObj['student']['noOfPassengers'] = document.querySelector("#no-of-students").value;
    transportObj['student']['fare'] = document.querySelector("#student-fare").value;
    transportObj['teacher']['mode'] = document.querySelector("#teacher-mode").value;
    transportObj['teacher']['carrier'] = document.querySelector("#teacher-carrier").value;
    transportObj['teacher']['fareClass'] = document.querySelector("#teacher-fare-class").value;
    transportObj['teacher']['noOfPassengers'] = document.querySelector("#no-of-teachers").value;
    transportObj['teacher']['fare'] = document.querySelector("#teacher-fare").value;

  transportTableRow = `<tr>
                            <td>${++transportTableRowCount}</td>
                            <td>Student</td>
                            <td>${transportObj.fromOne}</td>
                            <td>${transportObj.toOne}</td>
                            <td>${transportObj.transportType}</td>
                            <td>${transportObj['student']['mode']}</td>
                            <td>${transportObj['student']['carrier']}</td>
                            <td>${transportObj['student']['fareClass']}</td>
                            <td>${transportObj['student']['noOfPassengers']}</td>
                            <td>${transportObj['student']['fare']}</td>  
                            <td class="text-center">${actionBtn} </td>                    
                       </tr>
                        <tr>
                            <td>${++transportTableRowCount}</td>
                            <td>Teacher</td>
                            <td>${transportObj.fromOne}</td>
                            <td>${transportObj.toOne}</td>
                            <td>${transportObj.transportType}</td>
                            <td>${transportObj['teacher']['mode']}</td>
                            <td>${transportObj['teacher']['carrier']}</td>
                            <td>${transportObj['teacher']['fareClass']}</td>
                            <td>${transportObj['teacher']['noOfPassengers']}</td>
                            <td>${transportObj['teacher']['fare']}</td>  
                            <td class="text-center">${actionBtn} </td>                    
                       </tr>`

    addTransportTable.innerHTML += transportTableRow; 
                

  });

  
// transport Js Ends

//================================== Ram Js END ==================================//
