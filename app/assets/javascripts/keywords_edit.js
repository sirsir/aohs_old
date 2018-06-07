
var fnKeywords = {
  _maxTemplateLineCount: 10,
  _maxTemplateCharCount: 200,
  _detectionSettings: null,
  
  keywordTypes: [],
  
  getTypeFromOptions: function()
  {
    $("#keyword_keyword_type_id option").each(function(){
      fnKeywords.keywordTypes.push($(this).text());  
    });
  },
  
  addTypeOption: function(name)
  {
    $("#keyword_keyword_type_id option:selected").removeAttr("selected");
    $("#keyword_keyword_type_id").append(jQuery("<option>",{ value: 0, text: name, selected: 'selected' }));
    $("#selected_keyword_type").val(name);
    fnKeywords.keywordTypes.push(name);
  },
  
  keywordTypeDialog: function(url){
    function validName(name) {
      if (name.length > 0) {
        if (!fnKeywords.keywordTypes.includes(name)) {
          return true;
        }
      }
      return false;
    }
    
    var opts = {
      title: "Keyword Type",
      message: appl.getHTML("#keyword-type-template"),
      buttons: {
        ok: {
          label: "OK",
          className: "btn-primary",
          callback: function(){
            var o = $(this);
            var name = jQuery.trim($("input[name=type-name]",o).val());
            if (validName(name)) {
              fnKeywords.addTypeOption(name);
              return true;
            } else {
              var b = o.find(".form-group");
              b.addClass("has-error");
              b.find('.help-block').remove();
              b.append(jQuery("<span>",{ class: 'help-block', text: 'name is invalid or already taken' }));
              return false;
            }
          }
        },
        cancel: {
          label: "Cancel",
          className: "btn-default",
          callback: function(){ }
        }
      }
    };
    
    bootbox.dialog(opts);
  },

  validateTemplate: function(){
    function updateFields(){
      $("#keyword_detection_settings").val(JSON.stringify(fnKeywords._detectionSettings));
    }
    
    function valid(){
      return true;
    }
    
    updateFields();
    return valid();
  },
  
  validateForm: function(){
    function updateEditorField(){
      $("div.fd-content").each(function(){
        var o = $(this);
        var c_id = o.attr("data-input-content-id");
        var oi = $("input#notify_message_" + c_id);
        if(oi.length > 0){
          var code = o.summernote('code');
          oi.val(code);
        }
      });
    }
    updateEditorField();
    return fnKeywords.validateTemplate();
  },
  
  trySendAlert: function(){
    function content(){
      var data = {
        agent_name: $("#current_user_name").val(),
        content_type: 'keyword',
        detected_keyword: {
          keyword: $("#keyword_name").val(),
          keyword_type: $("#keyword_keyword_type_id option:selected").text(),
          keyword_id: gon.params.id,
          keyword_type_id: $("#keyword_keyword_type_id option:selected").val(),
          content_template: null
        }
      };
      return data;
    }
    
    function trySend(ds){
      appl.dialog.showWaiting();
      var url = Routes.client_notify_webapi_index_path({ do_act: 'send' });
      jQuery.post(url,ds,function(data){
        if(data.success){
          appl.noty.info("Message has been send.");
        } else {
          appl.noty.error("Error," + data.message.join(","));
        }
        appl.dialog.hideWaiting();
      });
    }
    
    trySend(content());
  },
  
  detectionSettings: function(){
    function getAndUpdate(){
      var oo = $("form#detection-setting-form");
      var data = {};
      data.speaker_type = $("input[name=fl-detection-channel]:checked",oo).val();
      data.delinquents = [];
      $("input[name=fl-detection-deln]:checked",oo).each(function(){
        data.delinquents.push($(this).val());  
      });
      fnKeywords._detectionSettings = data;
    }
    
    function openDialog(){
      var htm = appl.hbsTemplate("detection-settings-template");
      var opts = {
        title: "Keyword Dectection Settings",
        message: htm(),
        buttons: {
          ok: {
            label: "OK",
            className: "btn-primary",
            callback: function(){
              getAndUpdate();  
            }
          },
          close: {
            label: "Cancel",
            className: "btn-default",
            callback: function(){}
          }
        }
      };
      var dialog = bootbox.dialog(opts);
      dialog.init(function(){
        if(isNotNull(fnKeywords._detectionSettings)){
          $("input#fl-detection-channel_" + fnKeywords._detectionSettings.speaker_type).prop("checked",true);
          try {
            fnKeywords._detectionSettings.delinquents.forEach(function(d){
               $("input[name=fl-detection-deln][value=\"" + d + "\"").prop("checked",true);
            });
          } catch(e){}
        }
      });
    }
    
    openDialog();
  },
  
  init: function(){
    function setEditor(){
      var opts = {
        height: 100,
        maxHeight: 150,
        minHeight: 100,
        toolbar: [
          ['style', ['bold', 'italic', 'underline', 'clear']],
          ['font', ['strikethrough', 'superscript', 'subscript']],
          ['fontsize', ['fontsize']],
          ['color', ['color']],
          ['para', ['ul', 'ol']],
          ['misc',['codeview']]
        ]
      };
      $("div.fd-content").summernote(opts);
    }
    
    function setEvent(){
      $("#btn-try-alert").on('click',function(){
        fnKeywords.trySendAlert();  
      }).on('mouseover',function(){
        $(this).addClass('btn-primary').removeClass('btn-default');  
      }).on('mouseout',function(){
        $(this).removeClass('btn-primary').addClass('btn-default'); 
      });
      $("#btn-new-keyword-type").on('click',function(){
        fnKeywords.keywordTypeDialog();
      });
      $("#keyword_keyword_type_id").on('change',function(){
        $("#selected_keyword_type").val($('option:selected',this).text());
      });
      $("#btn-add-word").on('click',function(){
        $("#keyword-list-block").append(jQuery("<input>",{ type: "text", name: "word_list[]", class: "form-control" }));
      });
      $("#btn-change-detection").on('click',function(){
        fnKeywords.detectionSettings();
      });
      $("form").on("submit",function(){
        return fnKeywords.validateForm();  
      });      
    }
    
    function setFields(){
      try {
        fnKeywords._detectionSettings = jQuery.parseJSON($("#keyword_detection_settings").val());
      } catch(e){}
    }
    
    setFields();
    setEditor();
    fnKeywords.getTypeFromOptions();
    setEvent();
  }
};

jQuery(document).on('ready page:load',function(){ fnKeywords.init(); });