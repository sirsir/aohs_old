
var range = ['2010','2011','2012','2013','2014','2015'];
var ana_perform = {
  getWidthHeight: function(){
    var w = $(window).width()/2 - $(".cl-form-filter").width();
    var h = $(window).height() - 250;
    return { w: w, h: h}
  },
  getDataTrend: function(string, flag){
    var data = {
      columns: [],
      sums: []
    };
    
    data.columns.push(['x'].concat(range));
    
    var sum=[];
    for(var i=0; i<range.length; i++){
      sum[i] = 0;
    }
        
    string.forEach(function(a){
      var x = [a];
      for(var i=0; i<range.length; i++){ 
        var v = Math.round(Math.random()*40)+60;
        sum[i] += v;
        x.push(v);
      };
      data.columns.push(x);
    });
    if (flag) {
      for(var i=0; i<sum.length; i++){
        sum[i] = Math.round((sum[i])/5);
      }
      data.columns.push(['Total'].concat(sum));
    }
    console.log(data);
    return data;
  },
  
  chartF1Load: function(){
    var wd = ana_perform.getWidthHeight();
    var chart = c3.generate({
      bindto: "#graphp1",
      size: { height: wd.h, width: wd.w },
      data: {
        columns: [
          ['Agent 1', 75, 80, 70, 75, 73, 82],
          ['Agent 2', 77, 78, 80, 73, 75, 77],
          ['Agent 3', 70, 75, 84, 85, 73, 82]
        ],
        type: 'bar'
      },
      color: {
        pattern: ['#a1d391', '#6ab9b5', '#6ab975']
      },
      axis: {
        x: {
          label: {
            text: 'Factor',
            position: 'outer-right',
          },
          type: 'category',
          position: 'outer-left',
          categories: ['Total', 'Greeting', 'Manner', 'Wording', 'Service', 'Ending']
        },
        y: {
          label: {
            text: 'Point',
            position: 'outer-middle',
          },
        }
      },
      bar: {
        width: {
          ratio: 0.6 // this makes bar width 50% of length between ticks
        }
        // or
        //width: 100 // this makes bar width 100px
      }
    });
    return chart;
  },
  
  chartA1Load: function(){
    var wd = ana_perform.getWidthHeight();
    var data = ana_perform.getDataTrend(['Greeting','Manner','Wording','Service','Ending'],true);
    var chart = c3.generate({
      bindto: "#graphp1",
      size: { height: wd.h, width: wd.w },
      data: {
        columns: [
          ['Greeting', 82, 78, 83],
          ['Manner', 76, 74, 79],
          ['Wording', 92, 90, 87],
          ['Service', 75, 70, 75],
          ['Ending', 77, 80, 78]
        ],
        type: 'bar'
      },
      color: {
        pattern: ['#a1d391', '#6ab9b5', '#6ab975', '#a67875', '#7b615c']

      },
      axis: {
        x: {
          label: {
            text: 'Agent',
            position: 'outer-right'
          },
          type: 'category',
          categories: ['Agent 1', 'Agent 2', 'Agent 3']
        },
        y: {
          label: 'Point'
        }
      },
      bar: {
        width: {
          ratio: 0.8
        }
      }
    });
    return chart;
  },
  
  chartF2Load: function(){
    var wd = ana_perform.getWidthHeight();
    var data = ana_perform.getDataTrend(['Greeting','Manner','Wording','Service','Ending'],true);
    var chart = c3.generate({
      bindto: "#graphp2",
      size: { height: wd.h, width: wd.w }, 
      data: {
        x: 'x',
        columns: data.columns,
        labels: true,
        type: 'line'
      },
      padding: {
        top: 20,
        left: 20,
        right: 20,
        bottom: 20
      },
      color: {
        pattern: ['#D2691E', '#6ab975', '#a1d391', '#6ab9b5', '#a67875', '#5687d1']
      },
      axis: {
        x: {
            type: 'categories'
        },
        y: {
          label: 'Point',
          show: false
        }
      }
    });
    return chart;
  },
  
  chartA2Load: function(){
    var wd = ana_perform.getWidthHeight();
    var data = ana_perform.getDataTrend(['Agent 1','Agent 2','Agent 3'],false);
    var chart = c3.generate({
      bindto: "#graphp2",
      size: { height: wd.h, width: wd.w }, 
      data: {
        x: 'x',
        columns: data.columns,
        labels: true,
        type: 'line'
      },
      padding: {
        top: 5,
        left: 15,
        right: 20,
        bottom: 20
      },
      color: {
        pattern: ['#D2691E', '#5687d1', '#a1d391', '#6ab9b5',]
      },
      axis: {
        x: {
            type: 'categories'
        },
        y: {
          label: 'Point',
          show: false
        }
      }
    });
    return chart;
  },
  
  init: function(){
    
    var wd = ana_perform.getWidthHeight();
    var chartp1 = ana_perform.chartF1Load();
    var chartp2 = ana_perform.chartF2Load();
    var view = "Monthly";
    var agent = "all";
    var group = "Factor"
    $('#view-type').on('change',function(){
      view = $("#view-type").val();
      console.log(view);
      if (view == "Monthly") {
        range = ['2015-Jun','2015-Jul','2015-Aug','2015-Sep','2015-Oct','2015-Nov','2015-Dec'];   
      }
      else if (view == "Year") {
        range = ['2010','2011','2012','2013','2014','2015'];
      }
      else if (view == "Quater") {
        range = ['3rd 2014','4th 2014','1st 2015','2nd 2015','3rd 2015','4th 2015'];
      }
      else if (view == "Weekly") {
        range = ['46th 2015','47th 2015','48th 2015','49th 2015','50th 2015','51st 2015','52nd 2015'];
      }
      console.log(range);
    });
    $('#agent-type').change(function(){
      agent = $("#agent-type").val();
    });
    $('#perform-type').change(function(){
      group = $("#perform-type").val();
    });
    
    $('#submit-btn').on('click',function(){
      document.getElementById("p1topic").innerHTML = group;
      document.getElementById("p2topic").innerHTML = "Trend of "+ group;
      if (group=="Agent") {
        setTimeout(function () {
          chartp1 = ana_perform.chartA1Load();
          chartp2 = ana_perform.chartA2Load();
        });
      }
      else if (group=="Factor") {
        setTimeout(function () {
          chartp1 = ana_perform.chartF1Load();
          chartp2 = ana_perform.chartF2Load();
        });
      }
    });
  }
}
