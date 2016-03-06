$( document ).ready(function() {
  // Get the context of the canvas element we want to select
  var ctx = document.getElementById("myChart").getContext("2d");
  var myNewChart = new Chart(ctx).Line(data, options);
});
