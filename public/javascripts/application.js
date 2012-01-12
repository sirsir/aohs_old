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
	},
	call_blank: function(v,df) {
		var df = df || "&nbsp;";
		var v = v || "";
		if(jQuery.trim(v.toString()).length <= 0)
			return df;
		else
			return v;
	},
	to_boolean: function(b){
		if((b == "true") || (b == 1) || (b == '1'))
			return true;
		else
			return false
	},
	isBlank: function(variable){
      if(variable == null){
          return true;
      } else if(variable.length <= 0){
          return true;
      } else {
          return false;
      }
    },
	validThaiCarNo2: function(c){
		var c = c || "";
		var chr = "[0-9a-zA-Zกขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬ]";
		var th_pattern = new RegExp("^(*{1,4}-*{1,5} *{1,4})$".replace(/\*/g,chr));
		if(c.length > 0){
			result = th_pattern.test(jQuery.trim(c));
			return result;
		} else {
			return true;
		}		
	},
	validThaiCarNo: function(c){
		var c = c || "";
		var chr = "[0-9a-zA-Zกขฃคฅฆงจฉชซฌญฎฏฐฑฒณดตถทธนบปผฝพฟภมยรลวศษสหฬ]";
		var th_pattern = new RegExp("^(****-***** ****)$".replace(/\*/g,chr));
		if(c.length > 0){
			var a = jQuery.trim(c).split(",");
			var l=a.length,i=0;
			var result = true;
			while((i<l) && result){
				result = th_pattern.test(jQuery.trim(a[i]));
				//alert(jQuery.trim(a[i]) + ":=" + result);
				i++;
			}
			return result;
		} else {
			return true;
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

function zeroPadAfter(num,count)
{
	var count = count || 0;
	var numZeropad = num.toString() + '';
	while(numZeropad.length < count) {
		numZeropad = numZeropad + "0";
	}
	return numZeropad;
}

function number_with_delimiter(number, delimiter) {
	number = number + '', delimiter = delimiter || ',';
	var split = number.split('.');
	split[0] = split[0].replace(/(\d)(?=(\d\d\d)+(?!\d))/g, '$1' + delimiter);
	return split.join('.');
}
	
$(document).ready(function(){
	rowTblHover();
	subMenuHover();
})
