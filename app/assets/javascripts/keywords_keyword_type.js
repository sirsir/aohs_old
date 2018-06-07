var fnPage = {
  _maxTemplateLineCount: 10,
  _maxTemplateCharCount: 200,
  
  objMd: null,
  
  validateTemplate: function(){
    function valid(){
      var lc = fnPage.objMd.codemirror.lineCount();
      var cc = fnPage.objMd.value().length;
      return ((lc <= fnPage._maxTemplateLineCount) && (cc <= fnPage._maxTemplateCharCount));
    }
    return valid();
  },
  
  validateForm: function(){
    function updateFields(){
      var osub = $("div#notify_subject");
      if(osub.length > 0){
        var code = osub.summernote('code');
        $("input#kwtype_nofify_subject").val(code);
      }
    }
    updateFields();
    return fnPage.validateTemplate();
  },
  
  init: function(){    
    function setEditor(){
      var opts = {
        height: 80,
        maxHeight: 80,
        minHeight: 80,
        toolbar: [
          ['style', ['bold', 'italic', 'underline', 'clear']],
          ['font', ['strikethrough', 'superscript', 'subscript']],
          ['fontsize', ['fontsize']],
          ['color', ['color']],
          ['para', ['ul', 'ol']],
          ['misc',['codeview']]
        ]
      };
      $("div#notify_subject").summernote(opts);
    }
    
    setEditor();
    $("form").on('submit',function(){
      return fnPage.validateForm();  
    });
  }
};

jQuery(document).on('ready page:load',function(){
  fnPage.init();
});