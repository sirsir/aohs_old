//= require 'js/jquery.dataTables.min.js'
//= require 'js/dataTables.bootstrap.min'
//= require 'js/fixed_columns/dataTables.fixedColumns.min'

var dtTable = {
  width: 'auto',
  options: {
    voicelogs: function(o){
      return Object.merge(o,{
        columnDefs: [{
          targets: "nosort",
          orderable: false
        }],
        "order": [[2, 'desc']],
        //"scrollY": h_tbl,
        "scrollX": true,
        "paging": false,
        "searching": false,
        "info": false,
        "ordering": false     
      });
    },
    ableSort: function(o) {
      return Object.merge(o,{
        //"scrollY": 'auto',
        "scrollX": true,
        "paging": false,
        "searching": false,
        "info": false,
        "ordering": true,
      });
    },
    callBrowser: function(o){
      return Object.merge(o,{
        "scrollX": true,
        "paging": false,
        "searching": true,
        "info": false,
        "ordering": true,
        dom: 'lrtp'
      });
    }
  }
}

jQuery.extend(appl.dtTable,dtTable);