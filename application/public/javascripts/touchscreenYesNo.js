var confirmation = null;
var confirmationTimeout = null;

function confirmYesNo(message, yes, no) {  
  hideConfirmation();
  if (confirmation == null) {
    confirmation = document.createElement("div");
    confirmation.setAttribute('id', 'confirmation');
    confirmation.setAttribute('style', 'display:none');
    document.body.appendChild(confirmation);
  }
  confirmation.innerHTML = ''+
  '<div class="confirmation">'+ message+ '<div>'+
  '<button id="yes"><span>Yes</span></button>'+
  '<button id="no"><span>No</span></button></div>'+
  '</div>';
  $("#yes").mousedown(yes);
  $("#no").mousedown(no);
  confirmation.setAttribute('style', 'display:block');
  confirmationTimeout = window.setTimeout("hideConfirmation()", 5000);
}

function hideConfirmation(){ 
  if (confirmation != null) confirmation.setAttribute('style', 'display:none');
  if (confirmationTimeout != null) window.clearTimeout(confirmationTimeout);
}
