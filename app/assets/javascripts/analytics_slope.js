//= require 'slopegraph'

var ana_slope = {
  getWidthHeight: function(){
    var w = $(window).width()/2 - $(".cl-form-filter").width();
    var h = $(window).height() - 250;
    return { w: w, h: h}
  },
  
  init: function(){
    var wd = ana_perform.getWidthHeight();
  
    var data = {
      "data":[[1, 2, 3, 4, 5], [3, 2, 5, 1, 4], [2, 4, 3, 5, 1]],
      "label":[['apple', 'banana', 'carrot', 'bacon', 'egg']]
    };
    
    var slopeGraph = d3.custom.slopegraph();
    d3.select('#slopegraph')
        .datum(data)
        .call(slopeGraph);
    
    slopeGraph.width(500);
    
    d3.select('#slopegraph')
        .call(slopeGraph);
    d3.custom = {};
    
  }
}
