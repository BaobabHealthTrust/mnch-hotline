var data;
var plot;
var graphToggled = false; // the graph is disabled by default
var tempData;
var tempDay;
var tempPageTitle;
var totalPatientsPresent;
var visits = {Table:{}, Graph:{}, Plot:{}, ShowGraph:{}, ShowTable:{}, PatientsList:{}};

function menu(tabType){

  switch(tabType){
    case visits.Table:
      displayTab(['visits-graph-tab'],['visits-table-tab', 'patients-list-tab'],'tabbed-content');
    break;

    case visits.Graph:
      displayTab(['visits-table-tab'],['visits-graph-tab', 'patients-list-tab'], 'tabbed-content');
    break;

    case visits.PatientsList:
      displayTab(['patients-list-tab'], ['visits-graph-tab', 'visits-table-tab'], 'tabbed-content');    
    break;

    case visits.Plot:
      drawGraph(data, "#placeholder", "#popup-dialog-box", "#message-box-text-area");
    break;

    case visits.ShowGraph:
    case visits.ShowTable:
      plotGraph(null, null, null);
    break;

    default:
      alert("Unknown tab type!");
    break;
  }
}

function plotGraph(graphData, dayName, pageTitle){
  var pageTitle;

  if(!graphToggled){
    data         = graphData;
    graphToggled = true;

    if(data      == null) data      = tempData;
    if(dayName   == null) dayName   = tempDay;
    if(pageTitle == null) pageTitle = tempPageTitle;

    menu(visits.Table);

    title = '<center><h3>Graphical Summary for ' + dayName + '</h3></center>';
    document.getElementById(pageTitle).innerHTML = title;

    menu(visits.Plot);

    // temporarily transfer data to avoid overwriting
    tempData      = data;
    tempDay       = dayName;
    tempPageTitle = pageTitle;
  }
  else {
    graphToggled = false;
    menu(visits.Graph);
  }
}

function listPatients(dialogBox, textArea){
  var visitDate = document.getElementById(textArea).innerHTML.split('<br>')[1];
  graphToggled  = false;

  closeDialogBox(dialogBox);
  menu(visits.PatientsList);
  generatePatientsList(visitingPatients[visitDate], visitDate);
}

function generatePatientsList(patients, date) {
  var patientsTable;
  var tableHeading;
  var tableDetails;
  var errorMessage;

  patientsTable =  document.getElementById("patients-table");

  // create table heading
  tableHeading = "<table class='solid-bolder-table'>\n\t";
  tableHeading += "<tr class='bold-table-header'>\n\t\t";
  tableHeading += "<td class='dotted-table-data'>ID</td> <td class='dotted-table-data'>ARV Number</td> <td class='dotted-table-data'>Name</td> ";
  tableHeading += "<td class='dotted-table-data'>National ID</td> <td class='dotted-table-data'>Gender</td> <td class='dotted-table-data'>Age</td> ";
  tableHeading += "<td class='dotted-table-data'>DOB</td> <td class='dotted-table-data'>Phone number</td> <td class='dotted-table-data'>Date Started</td>\n\t";
  tableHeading += "</tr>";

  // add patient details
  if(typeof(patients) != 'undefined'){

  document.getElementById("table-header").innerHTML= "<h3>Patients who came on " +date +"<br/>" + "Total: " + totalPatientsPresent + "</h3>"

  ShowGraphtableDetails = "";
  for(var i = 0; i < patients.length; i++){
    tableDetails += "<tr class='dotted-table-data'>\n\t";
    tableDetails += "<td class='dotted-table-data'> <input class='visit' type='button' ";
    tableDetails += "onmousedown='document.location=\"/patients/mastercard?patient_id=";
    tableDetails += patients[i]['patient_id'] + "\"' value=";
    tableDetails += patients[i]['patient_id'] + "> </td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['arv_number']    + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['name']          + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['national_id']   + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['gender']        + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['age']           + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['birthdate']     + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['phone_number']  + "</td>\n\t\t";
    tableDetails += "<td class='dotted-table-data'>" + patients[i]['start_date']    +"</td>\n\t";
    tableDetails += "</tr>";
  }
  tableDetails += "</table>";

  // put them together
  patientsTable.innerHTML = (tableHeading + tableDetails);
  }
  else{
    document.getElementById("table-header").innerHTML="";
    errorMessage = "</table><center><h2><i> Sorry, there is no patients data available for this day</i></h2></center>";
    // put them together
    patientsTable.innerHTML = errorMessage;
  }
}

function closeDialogBox(dialogBox){
  jQuery(dialogBox).hide(0);
}

function drawGraph(graphData, graphPlaceHolder, dialogBox, textArea){

  var maxValue = maximumValue(graphData);

  function getData(x1, x2) {
    var plotData = {
        color:  'green',
        data:   graphData,
        points: { show: true, selectedColor: '#ff0000', radius: 8 },
        lines:  { show: true, fill: true, fillColor: 'rgba(0, 255, 80, 0.2)'},
        bars:   { show: true }
      };

    plotData = [plotData];
    return plotData;
  }

  var plotOptions = {
    grid:   { clickable: true },
    yaxis:  { min:  0,  max: maxValue},
    xaxis:  { mode: 'time', timeformat: '%b %y', ticks: 10}
  };

  plot = jQuery.plot(jQuery(graphPlaceHolder), getData(null, null), plotOptions);

  jQuery(graphPlaceHolder).bind('plotclick', function (e, pos) {
    x = pos.x.toFixed(2);
    y = pos.y.toFixed(2);
    // Find the closest point to the one clicked
    selelectionIndex  = null;
    selelectionDiff   = null;

    for (var i = 0; i < graphData.length; i++){
      diffX = Math.abs(graphData[i][0] - x) * pos.hozScale;
      diffY = Math.abs(graphData[i][1] - y) * pos.vertScale;
      // Pythagoras
      diff = Math.sqrt((diffX * diffX) + (diffY * diffY));

      if (selelectionIndex == null || diff < selelectionDiff) {
        selelectionIndex  = i;
        selelectionDiff   = diff;
      }
    }

    // If there is no point leave
    if (selelectionIndex == null) return;
    // If the point is within in the radius
    if (selelectionDiff > 8) return;
    // Select the point
    plot.selectPoint(0, selelectionIndex);

    return;
  });

  jQuery(graphPlaceHolder).bind('selectpoint', function (e, point) {
    jQuery(dialogBox).get(0).style.left = point.pageX + 'px';
    jQuery(dialogBox).get(0).style.top  = point.pageY + 'px';
    jQuery(dialogBox).show(0);

    totalPatientsPresent = graphData[point.selectedIndex][1];

    if(totalPatientsPresent == 1)
      info = '1 patient seen on:</br>';
    else
      info = totalPatientsPresent + ' patients seen on:</br>';

    jQuery(textArea).get(0).innerHTML = info + graphData[point.selectedIndex][2];
  });
}

function maximumValue(values){
  var maxVal = values[0][1];

  for(var i =  0; i < values.length; i++){
    if (maxVal < values[i][1])
      maxVal = values[i][1];
  }

  return (maxVal + 1);
}

