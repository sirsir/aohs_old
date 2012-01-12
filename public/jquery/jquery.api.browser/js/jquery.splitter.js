/*
 * jquery.splitter.js - two-pane splitter window plugin
 *
 * version 1.02 (01/09/2007) 
 * 
 * Dual licensed under the MIT and GPL licenses: 
 *   http://www.opensource.org/licenses/mit-license.php 
 *   http://www.gnu.org/licenses/gpl.html 
 */

/**
 * The splitter() plugin implements a two-pane resizable splitter window.
 * The selected elements in the jQuery object are converted to a splitter;
 * each element should have two child elements which are used for the panes
 * of the splitter. The plugin adds a third child element for the splitbar.
 * 
 * For more details see: http://methvin.com/jquery/splitter/
 *
 *
 * @example $('#MySplitter').splitter();
 * @desc Create a vertical splitter with default settings 
 *
 * @example $('#MySplitter').splitter({direction: 'h', accessKey: 'M'});
 * @desc Create a horizontal splitter resizable via Alt+Shift+M
 *
 * @name splitter
 * @type jQuery
 * @param Object options Options for the splitter (not required)
 * @cat Plugins/Splitter
 * @return jQuery
 * @author Dave Methvin (dave.methvin@gmail.com)
 */
 jQuery.fn.splitter = function(opts){
	opts = jQuery.extend({
		type: 'v',				// v=vertical, h=horizontal split
		outline: false,			// use outlined splitbar for moving
		activeClass: 'active',	// class name for active splitter
		pxPerKey: 8,			// splitter px moved per keypress
		tabIndex: 0,			// tab order indicator
		accessKey: ''			// accelerator key for splitter
	},{
		v: {					// Vertical splitters:
			keyGrowA: 39, keyShrinkA: 37, cursor: "e-resize",
			splitbarClass: "vsplitbar", outlineClass: "voutline",
			eventPos: "pageX", set: "left", 
			adjust: "width",  offsetAdjust: "offsetWidth",  adjSide1: "Left", adjSide2: "Right",
			fixed:  "height", offsetFixed:  "offsetHeight", fixSide1: "Top",  fixSide2: "Bottom"
		},
		h: {					// Horizontal splitters:
			keyGrowA: 40, keyShrinkA: 38, cursor: "n-resize",
			splitbarClass: "hsplitbar", outlineClass: "houtline",
			eventPos: "pageY", set: "top", 
			adjust: "height", offsetAdjust: "offsetHeight", adjSide1: "Top",  adjSide2: "Bottom",
			fixed:  "width",  offsetFixed:  "offsetWidth",  fixSide1: "Left", fixSide2: "Right"
		}
	}[((opts||{}).type||'v').charAt(0).toLowerCase()], opts||{});

	return this.each(function() {
		function startSplitMouse(e) {
			if ( opts.outline )
				ghostbar.css(opts.set, splitbar.css(opts.set)).show();
			else
				splitbar.addClass(opts.activeClass);
			paneA._posAdjust = paneA[0][opts.offsetAdjust] - e[opts.eventPos];
			jQuery(document)
				.bind("mousemove", doSplitMouse)
				.bind("mouseup", endSplitMouse);
		}
		function doSplitMouse(e) {
			moveSplitter(paneA._posAdjust+e[opts.eventPos], opts.outline);
		}
		function endSplitMouse(e) {
			if ( opts.outline ) {
				ghostbar.hide();
				moveSplitter(paneA._posAdjust+e[opts.eventPos], false);
			}
			else
				splitbar.removeClass(opts.activeClass);
			jQuery(document)
				.unbind("mousemove", doSplitMouse)
				.unbind("mouseup", endSplitMouse);
		}
		function moveSplitter(np, ol) {
			// Constrain new position to fit pane size limits; 16=scrollbar fudge factor
// TODO: enforce group width in IE6 since it lacks min/max css properties?
			np = Math.max(paneA._min+paneA._padAdjust, group._adjust - (paneB._max||9999), 16,
				Math.min(np, paneA._max||9999, group._adjust - splitbar._adjust - 
					Math.max(paneB._min+paneB._padAdjust, 16)));

			// If in outline mode, only need to move the ghostbar and leave
			if ( ol ) { ghostbar.css(opts.set, np+"px"); return; }
			
			// Resize/position the two panes and splitbar
			splitbar.css(opts.set, np+"px");
			paneA.css(opts.adjust, np-paneA._padAdjust+"px");
			paneB.css(opts.set, np+splitbar._adjust+"px")
				.css(opts.adjust, group._adjust-splitbar._adjust-paneB._padAdjust-np+"px");

			// IE fires resize for us; all others pay cash
			if ( !jQuery.browser.msie ) {
				paneA.trigger("resize");
				paneB.trigger("resize");
			}
		}
		function cssCache(jq, n, pf, m1, m2) {
			// IE backCompat mode thinks width/height includes border and padding
			jq[n] = jQuery.boxModel? (parseInt(jq.css(pf+m1))||0) + (parseInt(jq.css(pf+m2))||0) : 0;
		}
		function optCache(jq, pane) {
			// Opera returns -1px for min/max dimensions when they're not there!
			jq._min = Math.max(0, opts["min"+pane] || parseInt(jq.css("min-"+opts.adjust)) || 0);
			jq._max = Math.max(0, opts["max"+pane] || parseInt(jq.css("max-"+opts.adjust)) || 0);
		}

		// Create jQuery object closures for splitter group and both panes
		var group = jQuery(this).css({position: "relative"});
		var divs = jQuery(">*", group[0]).css({
			position: "absolute", 			// positioned inside splitter container
			margin: "0", border: "0",		// remove margin/border added for non-script scenario
			"-moz-user-focus": "ignore"		// disable focusability in Firefox
		});
		var paneA = jQuery(divs[0]);		// left  or top
		var paneB = jQuery(divs[1]);		// right or bottom

		// Focuser element, provides keyboard support
		var focuser = jQuery('<a href="javascript:void(0)"></a>')
			.attr({accessKey: opts.accessKey, tabIndex: opts.tabIndex})
			.bind("focus", function(){ ghostbar.css(opts.set, splitbar.css(opts.set)).show(); })
			.bind("keydown", function(e){
				var key = e.which || e.keyCode;
				var dir = key==opts.keyGrowA? 1 : key==opts.keyShrinkA? -1 : 0;
				if ( !dir ) return;
				var pos = paneA[0][opts.offsetAdjust]+dir*opts.pxPerKey;
				moveSplitter(pos, true);	// ghostbar
				moveSplitter(pos, false);	// splitbar
			})
			.bind("blur", function(){ ghostbar.hide(); });

		// Splitbar element, displays actual splitter bar
		var splitbar = jQuery('<div></div>')
			.insertAfter(paneA).append(focuser)
			.attr({"class": opts.splitbarClass, unselectable: "on"})
			.css({position: "absolute",
				"-khtml-user-select": "none", "-moz-user-select": "none"})
			.bind("mousedown", startSplitMouse);
		if ( /^(auto|default)$/.test(splitbar.css("cursor") || "auto") )
			splitbar.css("cursor", opts.cursor);

		// Ghostbar element, used for outlined splitbar movement option
		if ( opts.outline ) {
			var ghostbar = splitbar.clone(false).insertAfter(paneB)
				.attr({"class": opts.outlineClass}).hide();
		}

		// Cache several dimensions for speed--assume these don't change
		splitbar._adjust = splitbar[0][opts.offsetAdjust];
		cssCache(group, "_borderAdjust", "border", opts.adjSide1+"Width", opts.adjSide2+"Width");
		cssCache(group, "_borderFixed",  "border", opts.fixSide1+"Width", opts.fixSide2+"Width");
		cssCache(paneA, "_padAdjust", "padding", opts.adjSide1, opts.adjSide2);
		cssCache(paneA, "_padFixed",  "padding", opts.fixSide1, opts.fixSide2);
		cssCache(paneB, "_padAdjust", "padding", opts.adjSide1, opts.adjSide2);
		cssCache(paneB, "_padFixed",  "padding", opts.fixSide1, opts.fixSide2);
		optCache(paneA, 'A');
		optCache(paneB, 'B');

		// Initial splitbar position as measured from left edge of splitter
		paneA._init = (opts.initA==true? parseInt(jQuery.curCSS(paneA[0],opts.adjust)) : opts.initA) || 0;
		paneB._init = (opts.initB==true? parseInt(jQuery.curCSS(paneB[0],opts.adjust)) : opts.initB) || 0;
		if ( paneB._init )
			paneB._init = group[0][opts.offsetAdjust] - group._borderAdjust - paneB._init - splitbar._adjust;

		// Set up resize event handler and trigger immediately to set initial position
		group.bind("resize", function(e,size){
			// Determine new width/height of splitter container
			group._fixed  = group[0][opts.offsetFixed]  - group._borderFixed;
			group._adjust = group[0][opts.offsetAdjust] - group._borderAdjust;
			// Bail if splitter isn't visible or content isn't there yet
			if ( group._fixed <= 0 || group._adjust <= 0 ) return;
			// Set the fixed dimension (e.g., height on a vertical splitter)
			paneA.css(opts.fixed, group._fixed-paneA._padFixed+"px");
			paneB.css(opts.fixed, group._fixed-paneB._padFixed+"px");
			splitbar.css(opts.fixed, group._fixed+"px");
			if ( opts.outline )
				ghostbar.css(opts.fixed, group._fixed+"px");
			// Re-divvy the adjustable dimension; maintain size of the preferred pane
			moveSplitter(size || (!opts.initB? paneA[0][opts.offsetAdjust] :
				group._adjust-paneB[0][opts.offsetAdjust]-splitbar._adjust));
		}).trigger("resize" , [paneA._init || paneB._init || 
			Math.round((group[0][opts.offsetAdjust] - group._borderAdjust - splitbar._adjust)/2)]);
	});
};
