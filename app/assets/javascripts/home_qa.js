//= require 'charts'

var fnQa = {
  //_loadEvaluationCount: function(){
  //  var url = Routes.qa_manager_dashboard_index_path();
  //  jQuery.getJSON(url,function(data){
  //    var chart = c3.generate({
  //      bindto: "#chart-evaluation-count",
  //      size: {
  //        height: 120
  //      },
  //      legend: {
  //        show: false
  //      },
  //      data: {
  //        columns: [
  //          ['data'].concat(data.evaluation_count[1])
  //        ],
  //        type: 'bar',
  //        onclick: function(e) {
  //          //console.log(e);
  //        }
  //      },
  //      axis: {
  //        y: {
  //          show: false
  //        },
  //        x: {
  //          type: 'category',
  //          categories: data.evaluation_count[0],
  //          tick: {
  //            count: 10,
  //            culling: {
  //              max: 5
  //            }
  //          }
  //        }
  //      }
  //    });
  //    var htm = appl.getHtmlTemplate("#template-list-qaagent");
  //    $("#tbl-qa-agent tbody").html(htm(data.evaluation_count_qaagent));      
  //  });
  //},
  
  _bindButton: function(){
    $("button.btn-open-voicelog").off('click').on('click',function(){
      var o = $(this);
      appl.openUrl(Routes.call_history_path(o.attr("data-voice-log-id")));
    });
  },
  
  _loadTask: function(){
    function renderView(){
      var htm1 = appl.getHtmlTemplate("#template-assigend-table");
      $("#block-assigned-detail").html(htm1(fnQa.dsAgent.assigned_list));
      $("#lb_total_assigned").html(fnQa.dsAgent.assigned_count);
      var htm2 = appl.getHtmlTemplate("#template-evaluated-table");
      $("#block-evaluated-detail").html(htm2(fnQa.dsAgent.evaluated_list));
      $("#lb_total_evaluated").html(fnQa.dsAgent.evaluated_count);
      if($("#template-team-table").length > 0){
        var htm3 = appl.getHtmlTemplate("#template-team-table");
        $("#tbl-team").html(htm3(fnQa.dsAgent.team_list));        
      }
      fnQa._bindButton();
    }
    function renderChart(){
      var chart1 = c3.generate({
        bindto: "#chart-task-status",
        size: {
          height: 150
        },
        donut: {
          label: {
            show: false
          }
        },
        data: {
          columns: fnQa.dsAgent.chart_usages,
          type : 'donut'
        }
      });
      $("#chart-task-daily-sum").sparkline(fnQa.dsAgent.chart_task_daily_summary,{ type: 'bar', barColor: '#FF8C00' });
    }
    jQuery.getJSON(Routes.assignment_info_evaluation_tasks_path(),{},function(data){
      fnQa.dsAgent = data;
      renderView();
      renderChart();
    });
  },
  
  agentload: function(){
    fnQa._loadTask();
  },
  
  init: function(){
    fnQa.agentload();
  }
};

jQuery(document).on('ready page:load',function(){fnQa.init();});