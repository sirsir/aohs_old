// extend of handlebars

Handlebars.registerHelper('ifEqual', function(v1, v2, options) {
  if(v1 == v2) {
    return options.fn(this);
  }
  return options.inverse(this);
});

Handlebars.registerHelper('ifGe', function(v1, v2, options) {
  if(v1 >= v2) {
    return options.fn(this);
  }
  return options.inverse(this);
});

Handlebars.registerHelper('ifLe', function(v1, v2, options) {
  if(v1 <= v2) {
    return options.fn(this);
  }
  return options.inverse(this);
});

Handlebars.registerHelper('ifDefined', function(v1, options) {
  if(v1 !== undefined && v1 !== null && v1.length > 0) {
    return options.fn(this);
  }
  return options.inverse(this);
});

Handlebars.registerHelper('html_safe', function(context) {
  var html = context;
  // context variable is the HTML you will pass into the helper
  // Strip the script tags from the html, and return it as a Handlebars.SafeString
  if(html === undefined || html === null){
    return context;
  }
  return new Handlebars.SafeString(html);
});

Handlebars.registerHelper('select', function(selected, options){
  // to option select
  return options.fn(this).replace(new RegExp(' value=\"' + selected + '\"'),'$& selected=\"selected\"');
});

Handlebars.registerHelper('lastElement', function(eles) {
  var lastEle = eles.pop();
  return [lastEle];
});

Handlebars.registerHelper('icon', function(name, options){
  // icon
  function checkName(name) {
    // for evaluation status
    if (name == "evaluated") {
      return "circle";
    } else if (name == "checked") {
      return "circle";
    } else if (name == "checked-correct") {
      return "check-circle";
    } else if (name == "checked-wrong") {
      return "times-circle";
    } else if (name == "not-evaluate") {
      return "";
    } else {
      return name;
    }
  }
  var className = checkName(name);
  if (className === "") {
    return "";
  } else {
    return new Handlebars.SafeString("<i class=\"fa fa-" + className + "\"></i>");
  }
});

Handlebars.registerHelper('reportThCell', function(title) {
  if(title.length >= 15){
    return new Handlebars.SafeString("<div class=\"th-lmtstr\" title=\"" + title + "\">" + title + "</div>");
  } else {
    return title;
  }
});

Handlebars.registerHelper('fillText', function(context) {
  if(context !== undefined && context !== null && context.length > 0) {
    return context.replace(/\"/g,"'");
  }
  return context;
});

Handlebars.registerHelper('minToHr', function(context) {
  if(context !== undefined && context !== null) {
    return (parseInt(context)/60).toFixed(1);
  }
  return context;
});