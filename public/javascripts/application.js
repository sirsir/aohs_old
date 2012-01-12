// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults

var App = {
	make_query: function(data){
		var p = new Array();
		$.each(data,function(k,v){
			var v = jQuery.trim(v);
			if(v.length > 0)
				p.push(k + "=" + v);
		});
		return p.join("&");
	},
	switch_order : function(order){
		var order = order || "asc";
		if (order == "asc") {
			return "desc";
		}
		else 
			if (order == "desc") {
				return "asc"
			} else {
				return "asc";
			}
	}
};

var Msg = {
	confirm: function(msg,yesf,nof){
		var yesf = yesf || null;
		var nof = nof || null;
		$("#confirmDialog .message").html(msg);
		$("#confirmDialog").dialog({
			modal: true,
			bgiframe: true,
			buttons: {
				"No": function(){ 
					try {
						nof();
					} catch(e) { }; 
					$(this).dialog('destroy'); },
				"Yes": function() { 
					try { 
						yesf();
					} catch(e) { }; 
					$(this).dialog('destroy'); 
				}
			}
		});
	}	
};

function rowTblHover(){
	try {
		$(".tbl-hover tr").mouseover(function(){
			$(this).addClass('hover');
		}).mouseout(function(){
			$(this).removeClass('hover');
		});			
	} catch(e) {}
}

function subMenuHover(){
	try {
		$(".div-menu-block li").mouseover(function(){
			$(this).addClass('hover');
		}).mouseout(function(){
			$(this).removeClass('hover');
		});			
	} catch(e) {}	
}

function validInputNumeric(){
	$(".input-int").numeric();	
}

function checkPeriodCond(st,ed){
    var st = st.replace(/-/g,'/');
	var ed = ed.replace(/-/g,'/');
	var st = new Date(st),ed = new Date(ed);
	if(isNaN(st)) { st = null; }
	if(isNaN(ed)) { ed = null; }
	if((st != null) && (ed != null)){
		if(st <= ed)
			return true;
		else
			return false;
	} else 
		return true;
}

$(document).ready(function(){
	rowTblHover();
	subMenuHover();
})
