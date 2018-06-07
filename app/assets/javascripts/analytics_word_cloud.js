var anaWordCloudFn = {
  
  getFilter: function()
  {
    var pams = {};
    pams.date_range = getVal($("#fl-date-range").val());
    pams.speaker_type = getVal($("#fl-speaker-type").val());
    pams.top_view = getVal($("#fl-top option:selected").val());
    pams.call_categories = [];
    $("select[name=cs-flag]").each(function(){
      var os = $("option:selected",this);
      if(os.val().length > 0){
        pams.call_categories.push(os.val());
      }
    });
    return pams;
  },
  
  getDateRange: function()
  {
    var pams = anaWordCloudFn.getFilter();
    return appl.dateSplit(pams.date_range);
  },
  
  loadWordCloud: function()
  {
    function renderWordCloud(data){
      WordCloud(document.getElementById('box-wordcloud'), {
        list: data,
        fontWeight: 'bold',
        click: function(item){
          var w = item[0];
          var t = anaWordCloudFn.getDateRange();
          window.open(Routes.search_index_path()+"?word=" + w +"&fr_d=" + t.fr_d + "&to_d=" + t.to_d);
        }
      });
    }
    
    function renderTopWord(data){
      var htm = appl.getHtmlTemplate("#template-word-row");
      $("#box-topwords table").html(htm(data));
    }
    
    function getResult(){
      var pams = anaWordCloudFn.getFilter();
      jQuery.getJSON(Routes.word_cloud_analytics_path({ format: 'json'}), pams, function(data){
        renderWordCloud(data.wordcloud);
        renderTopWord(data.top);
        appl.dialog.hideWaiting();
      });
    }
    
    getResult();
  },
  
  init: function()
  {
    fn_reports.setDateRangePickerField();
    $("#btn-search").on('click',function(){
      appl.dialog.showWaiting();
      anaWordCloudFn.loadWordCloud();  
    });
  }
  
};

jQuery(document).on('ready page:load',function(){
  anaWordCloudFn.init();
});