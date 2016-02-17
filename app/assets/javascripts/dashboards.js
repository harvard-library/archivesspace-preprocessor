$(function () {
  // Ajaxify calls to reporting API because you're a PROFESSIONAL, dang it
  $.getJSON('/ajax/issues-per-repo').done(function (data, status, jqXHR) {
    var idx = 0;
    $.each(data, function (message, issues) {
      var ticks = [],
          datas = [];
      $.each(issues, function (code, value) {
        ticks.push(code);
        datas.push(value);
      });
      $('body').append('<h2>' + message + '</h2>');
      $('body').append('<div id="chart-' + idx + '" />');

      var max = Math.max.apply(null, datas),
          mean =  Math.round(datas.reduce(function (a,b) {return a + b}) / datas.length),
          delta = max - mean,
          use_log = (delta > 10000),
          yrenderer = use_log ? $.jqplot.LogAxisRenderer : $.jqplot.LinearAxisRenderer;

      $.jqplot('chart-' + idx, [datas], {
        Animate: !$.jqplot.use_excanvas,
        seriesDefaults:{
          renderer: $.jqplot.BarRenderer,
          pointLabels: { show: true },
          rendererOptions: {
            varyBarColor: true
          }
        },
        axisDefaults: { base: 2},
        tickDefaults:
        {
          syncTicks:       true,
          useSeriesColor:  true,
          autoscale:       true,
          alignTicks: true,
          forceTickAt0: true
        },
        axes: {
          xaxis: {
            renderer: $.jqplot.CategoryAxisRenderer,
            ticks: ticks
          },
          yaxis: {
            renderer: yrenderer,
            label: use_log ? "Log Scale" : "Point Scale"
          }
        },
        highlighter: { show: false, showTooltip: true }
      });
      idx++;
    });
  });
});
