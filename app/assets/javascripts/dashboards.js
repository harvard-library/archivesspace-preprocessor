$(function () {
  // Ajaxify calls to reporting API because you're a PROFESSIONAL, dang it
  $.jqplot('chartjunk',  [AspaceProc.issues_per_repo.data], {
    // Only animate if we're not using excanvas (not in IE 7 or IE 8)..
    animate: !$.jqplot.use_excanvas,
    seriesDefaults:{
      renderer:$.jqplot.BarRenderer,
      pointLabels: { show: true }
    },
    axes: {
      xaxis: {
        renderer: $.jqplot.CategoryAxisRenderer,
        ticks: ASpaceProc.issues_per_repo.ticks
      }
    },
    highlighter: { show: false }
  });
})
