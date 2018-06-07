//= require js/jquery.ui.widget.js
//= require js/jquery.iframe-transport.js
//= require js/jquery.fileupload.js

var FileUpload = {
  initUploader: function(upload_id, fn_success)
  {
    var fip = upload_id;
    if($(fip).length){
      
      var fn_done = function (e, data)
      {
        if (data.result.errors.length <= 0) {
          $("#btn-selectfile").css("display","none");
          $("#btn-upload").css("display","none");
          $("#upload-status").text("Upload finished");
          fn_success(data.result);
        } else {
          $("#upload-status").text("Upload failed");
        }
      }
      
      var fn_add  = function (e, data)
      {
        
        var btn_upload_opts = {
          class: "btn btn-success",
          text: "Upload"
        }
        
        var correctExtension = function(name){
          var exts = (name).match(/\.([0-9a-z]+)(?:[\?#]|$)/i);
          console.log(exts);
          if (exts) {
            return exts.some("csv");
          }
          return false;
        }
        
        var correctInputFile = function(finput){
          //console.log(finput);
          if(!(finput.type == "application/vnd.ms-excel" || finput.type == "text/csv")){
            appl.noty.error("Invalid file type, Please select again.");
            return false;
          }
          
          if (!correctExtension(finput.name)) {
            appl.noty.error("Invalid file type, Please select again.");
            return false;
          }
          
          if (finput.size > (1024*1024*10)) {
            appl.noty.error("The file size exceeds the limit allowed.");
            return false;
          }
          return true;
        }
        
        var inFiles = data.fileInput[0];
        var inFile = data.files[0];
        
        $("#btn-upload").html("");
        if (correctInputFile(inFile)) {  
          data.context = $('<button/>',btn_upload_opts)
                      .appendTo($("#btn-upload"))
                      .click(function(){
                        $("#upload-status").text("Uploading");
                        data.submit();
                      });        
        }
      }
      
      var fn_progressbar = function (e, data) {
        var progress = parseInt(data.loaded/data.total * 100, 10);
        $('#upload-progressbar').attr('aria-valuenow',progress);
      }
      
      $(fip).fileupload({
        dataType: 'json',
        done: fn_done,
        add: fn_add,
        progressall: fn_progressbar
      });
      
    } else {
      //alert("Object " + upload_id + " for uploader not found.");
    }
  }
  
}