// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/sstephenson/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require sugar.min
//= require jquery
//= require jquery_ujs
//= require twitter/bootstrap
//= require handlebars
//= require js-routes
//= require moment.min
//= require strftime-min
//= require js/noty/packaged/jquery.noty.packaged.min
//= require handlebars_ext
//= require js.cookie
//= require tooltip
//= require configs

var appcli = {};
jQuery.extend(appcli,{
  getHtmlTemplate: function(n,option){
    if ( typeof option !== 'undefined'){
      return Handlebars.compile($(n).html(),option);
    }else{
      return Handlebars.compile($(n).html());
    }
    
  }
});