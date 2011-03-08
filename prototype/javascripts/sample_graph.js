 jQuery.noConflict();

  function setData() {

    var patient_weight = [
        
        [1270824483000, /* multiply 1000 to convert time stamp to javascript mode*/
        80.0],
        [1270824658000, /* multiply 1000 to convert time stamp to javascript mode*/
        56.9],
        [1270824711000, /* multiply 1000 to convert time stamp to javascript mode*/
        74.0],
        [1270824765000, /* multiply 1000 to convert time stamp to javascript mode*/
        36.0],
        [1275030984000, /* multiply 1000 to convert time stamp to javascript mode*/
        56.3],
        [1279873230000, /* multiply 1000 to convert time stamp to javascript mode*/
        59.0],
        [1290422655000, /* multiply 1000 to convert time stamp to javascript mode*/
        57.0],
        [1292243110000, /* multiply 1000 to convert time stamp to javascript mode*/
        56.0],
        ];

   var patient_height = [
        
        [1290422655000, /* multiply 1000 to convert time stamp to javascript mode*/
        142.0],
        ];

    var currentWeight = null;
    var currentHeight = null;
    if (patient_weight.length > 0) {
      currentWeight = patient_weight[patient_weight.length - 1][1];
    }
    if (patient_height.length > 0) {
      currentHeight = patient_height[patient_height.length - 1][1];
    }

    var patientBMIHistory = []

     /* TODO: Revise this code to allow for BMI rates over time */
    if(currentHeight > 1.0){
      patientBMIHistory.push([patient_weight[patient_weight.length - 1][0], calculateBMI(currentHeight, currentWeight)]);
    }
    else{
      for (var i=0;i<patient_height.length;i++) {
        if (patient_height[i] && patient_weight[i]) {
          patientBMIHistory.push([patient_weight[i][0],
                                  calculateBMI(patient_height[i][1], patient_weight[i][1])]);
        }
      }
    }

    var patientBMI = showBMI(currentHeight, currentWeight);

    var systolic = [
        
        [1290422655000, /* multiply 1000 to convert time stamp to javascript mode*/
        80.0],
        [1292243110000, /* multiply 1000 to convert time stamp to javascript mode*/
        89.0],
        ];

    var diastolic = [
        
        [1290422655000, /* multiply 1000 to convert time stamp to javascript mode*/
        79.0],
        [1292243110000, /* multiply 1000 to convert time stamp to javascript mode*/
        78.0],
        ];

    var fasting = [
        
        [1270824574000, /* multiply 1000 to convert time stamp to javascript mode*/
        162.0],
        [1275030994000, /* multiply 1000 to convert time stamp to javascript mode*/
        79.0],
        [1279123953000, /* multiply 1000 to convert time stamp to javascript mode*/
        48.6],
        [1279286970000, /* multiply 1000 to convert time stamp to javascript mode*/
        55.8],
        [1289986391000, /* multiply 1000 to convert time stamp to javascript mode*/
        0.0],
        [1290424597000, /* multiply 1000 to convert time stamp to javascript mode*/
        129.6],
        ];

    var random = [
        
        [1262092626000, /* multiply 1000 to convert time stamp to javascript mode*/
        270.0],
        [1266416200000, /* multiply 1000 to convert time stamp to javascript mode*/
        79.0],
        [1270824615000, /* multiply 1000 to convert time stamp to javascript mode*/
        258.0],
        [1270824927000, /* multiply 1000 to convert time stamp to javascript mode*/
        108.0],
        [1271318340000, /* multiply 1000 to convert time stamp to javascript mode*/
        50.0],
        [1274978515000, /* multiply 1000 to convert time stamp to javascript mode*/
        79.0],
        [1292243054000, /* multiply 1000 to convert time stamp to javascript mode*/
        142.2],
        ];

    var glycated = [
        
        [1266416179000, /* multiply 1000 to convert time stamp to javascript mode*/
        468.0],
        [1270824896000, /* multiply 1000 to convert time stamp to javascript mode*/
        5.0],
        [1290523841000, /* multiply 1000 to convert time stamp to javascript mode*/
        89.0],
        ];

    var bpGraphData = [{color: "green", points: { show: true }, lines: {show: true}, data: systolic,  label: "Systolic"},
                   {color: "red", points: { show: true }, lines: {show: true}, data: diastolic ,  label: "Diastolic"}];

    var bsGraphData = [ {color: "blue", points: { show: true }, lines: {show: true}, data: fasting ,  label: "Record 1"},
                    {color: "green", points: { show: true }, lines: {show: true}, data: random,  label: "Record 2"}];

    var weightLabel = "Weight <br/>("+ patientBMI +")";
    var weightGraphData = [{data: patient_weight, points: { show: true },lines: {show: true},  label:weightLabel}];
    
    var bmiLabel = patientBMI+"<br/>";
    if (currentWeight) {
      bmiLabel += "Weight: "+ currentWeight +" kg";
    }
    var bmiGraphData = [{data: patientBMIHistory, points: { show: true },lines: {show: true},  label:bmiLabel}];

    var hba1cGraphData  = [{color: "rgb( 0, 205, 0)", points: { show: true },lines: {show: true}, data: glycated,  label: "HbA1c"}];

    return [bsGraphData, bpGraphData, weightGraphData, bmiGraphData, hba1cGraphData];
  }

  function calculateBMI(height, weight) {
    return (weight/(height*height)*10000).toFixed(1);
  }

  function showBMI(height, weight) {
      var dispCurrentBmi = calculateBMI(height, weight);
      var displayBmiInfo = "BMI: ";
      if (dispCurrentBmi > 18.5) {
        displayBmiInfo += dispCurrentBmi;
      } else if (dispCurrentBmi > 17.0) {
        displayBmiInfo += "<font color ='red'><b>" + dispCurrentBmi + "--Eligible for counseling</b></font>";
      } else {
        displayBmiInfo += "<font color ='red'><b>" + dispCurrentBmi + "--Eligible for therapeutic feeding</b></font>";
      }

      return displayBmiInfo;
   }

  function setPlotOptions(key) {
    var options;

    max_x_axis = new Date();
    min_x_axis = new Date();

    min_x_axis.setYear( min_x_axis.getFullYear() - 2 );
    max_x_axis = (new Date(max_x_axis.getFullYear() +"/"+ (max_x_axis.getMonth() + 2) +"/"+ max_x_axis.getDate())).getTime();
    min_x_axis = (new Date(min_x_axis.getFullYear() +"/"+ (min_x_axis.getMonth() + 2) +"/"+ min_x_axis.getDate())).getTime();

    switch(key){
      case 0: /* blood sugar tab */
        y_axis = { min: 40, max: 500, ticks: 8};
      break;

      case 1:/* BP tab */
        y_axis = { min: 40, max: 240, ticks: 8};
      break;

      case 2: /*  Weight */
        y_axis = { min: 40, max: 250, ticks: 8};
      break;

      case 3: /* BMI */
        y_axis = {min: 10, max: 50, ticks: 8,
                  tickFormatter: function (v, axis) { return v.toFixed(axis.tickDecimals) },
                  tickDecimals: 1};
      break;

      case 4: /* HbA1c */
        y_axis = { min: 6, max: 20, ticks: 8};
      break;

    }

    options = {
      grid: { clickable: true },
      legend: {position:"nw"},
      xaxis:  {min:min_x_axis, max: max_x_axis, ticks: 8, mode: "time",timeformat: "%b-%Y"},
      yaxis:  y_axis
    };
    return options;
  }

  /* hard-code color indices to prevent them from shifting as
   the user switches among the graphs */

  var i = 0;
  var datasets = setData();

  jQuery.each(datasets, function(key, val) {
    val.color = i;
    ++i;
  });

  function plotAccordingToChoices(key) {
    if (typeof(key) == 'undefined') key = 0;
    jQuery('#choices div').attr('class', 'graph-button');
    jQuery('#graph'+key).attr('class', 'graph-button active');
    jQuery.plot(jQuery("#simplegraphholder"), datasets[key], setPlotOptions(key));
  }

  plotAccordingToChoices(0);
