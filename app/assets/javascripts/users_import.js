var fn_user_import = {
  init: function(){
    
    function showStatus(s){
      $("#import-status").html(s);
    }
    
    function doImport(){
      showStatus("Importing");
      $("#import-options").css("display","none");
      $("#import-logs").css("display","block");   
      $("#btn-doimport").css("display","none");
      $(".form-import-options").css("display","none"); 
      jQuery.getJSON(Routes.import_users_path({
        step: "importdata",
        ca: gon.params.ca,
        update_replace: $("input#replace").prop("checked")
      }),function(data){
        appl.dialog.hideWaiting();
        showStatus("");
        if (data) {
          var r = $("#import-result");
          r.text(data.results.messages.join("\r\n"));
          r.autosize();
        } else {
          showStatus(data.err);
        }
      });
    }
    
    function checkUploadedFile(){
      if (gon.params.step == "verify"){
        // verify uploaded file
        showStatus("Preparing your uploaded file.");
        jQuery.getJSON(Routes.import_users_path({
          step: "verifydata",
          ca: gon.params.ca
        }),function(data){
          if (data.error === "") {
            showStatus("");
            $("#import-options").css("display","block");
            $("#btn-doimport").removeClass("btn-hidden");
            $("#btn-doimport").click(function(){
              appl.dialog.showWaiting();
              doImport();
            });
          } else {
            showStatus(data.err);
          }
        });
      }
    }
    
    function initUpload(){
      var fn_success = function(rs){
        appl.redirectTo(Routes.import_users_path({ step: 'verify', ca: rs.cache_name}));
      };
      FileUpload.initUploader("#fileupload",fn_success);
      checkUploadedFile();
    }
    
    initUpload();
  }
}

jQuery(document).on('ready page:load',function(){ fn_user_import.init(); });

