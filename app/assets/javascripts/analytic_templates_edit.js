var fnEdit = {
  
  init: function()
  {
    $("#btn-add-text-match").on('click',function(){
      $("#tbl-text-match tbody").append("<tr><td><textarea name=\"textmatch[]\" class=\"form-control\" row=\"1\"></textarea></td></tr>");  
    });
    $("#btn-add-text-similar").on('click',function(){
      $("#tbl-text-similar tbody").append("<tr><td><textarea name=\"textsimilar[]\" class=\"form-control\" row=\"1\"></textarea></td></tr>");  
    });
  }
}
jQuery(document).on('ready page:load',function(){ fnEdit.init(); });
