
jQuery.fn.synchronizeScroll = function() {
	
	var elements = this;
	if (elements.length <= 1) return;
		elements.scroll(
			function() {
				var left = $(this).scrollLeft();
				var top = $(this).scrollTop();
				elements.each(
					function() {
						if ($(this).scrollLeft() != left) $(this).scrollLeft(left);
						if ($(this).scrollTop() != top) $(this).scrollTop(top);
					}
				);
			});
		}