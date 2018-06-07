var _fnAutoCompleteInput = {
  
  setAgentAutoCompleteField: function(f_id, f_opts){
    var fdname = f_id || "fl-user-name";
    var opts = f_opts || {};
    
    var options = {
      url: function(phrase) {
        var params = { q: phrase };
        if(opts.unknown === true){
          params.unknown = true;
        }
        return Routes.list_users_path(params);
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      list: {
        maxNumberOfElements: 10  
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },

  setGroupAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-group-name";
    
    var options = {
      url: function(phrase) {
        return Routes.list_groups_path() + "?q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },

      list: {
        maxNumberOfElements: 10  
      },
      
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  },
    
  setTagAutoCompleteField: function(f_id)
  {
    var fdname = f_id || "fl-tag-call";
    
    var options = {
      
      url: function(phrase) {
        return Routes.autocomplete_tags_path() + "?q=" + phrase;
      },
      
      getValue: function(element) {
        return element.name;
      },
      
      ajaxSettings: {
        dataType: "json",
        method: "GET",
        data: {
          dataType: "json"
        }
      },
      
      preparePostData: function(data) {
        data.phrase = $("#" + fdname).val();
        return data;
      },
      
      list: {
        maxNumberOfElements: 10  
      },
            
      requestDelay: 300
    };
    
    $("#" + fdname).easyAutocomplete(options);    
  }
}
jQuery.extend(appl.autocomplete, _fnAutoCompleteInput);