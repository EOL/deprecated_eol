(function($){

var discover = {
	ondomready: function(){
		// page functions go here
		
		if (discover.isDiscoverPage()) {
			discover.buildGridHover();
			discover.buildOverlay();
			discover.buildColorbox();
			discover.buildPrint();
			discover.buildCalloutLasts();
			discover.buildSlideshow();
			discover.enable();
		}
		
	},
	
	isDiscoverPage: function() {
		if ($(".discover_content_section").length > 0) {
			// toggle parent class
			$(".article").toggleClass("discover_copy", true);
			return true;
		}
		return false;
	},

	handleSlideshowPaginator: function(e) {
		e.preventDefault();
		var page = $(this).attr("id");
		page = parseInt(page.replace("page-", ""));
		
		console.log(page);		
		
		var par = $(this).parent().parent().parent();;
		var meta = par.find(".discover_meta");
		var slideshow = par.find(".discover_slideshow_container");
		
		var slideWidth = parseInt(meta.find(".discover_width").html());
		var initialX = parseInt(meta.find(".discover_initialX").html());
		
		var slideMove = (page-1)*-1*slideWidth;
		slideMove = 0 + slideMove + initialX;
		slideshow.animate({left: slideMove+"px"}, 500);
		
		
		
		$(this).parent().find("a").toggleClass("current", false);
		$(this).toggleClass("current", true);
	},
	
	handleSlideshowPrevious: function(e) {
		e.preventDefault();

		
		var par = $(this).parent().parent();
		var meta = par.find(".discover_meta");
		var slideshow = par.find(".discover_slideshow_container");
		var nav = par.find(".discover_slideshow_paginator");
		
		var page = parseInt(par.find("a.current").attr("id").replace("page-", ""));
		
		console.log(page);
		
		if (page > 1) {
		
			page -= 1;
			
			var slideWidth = parseInt(meta.find(".discover_width").html());
			var initialX = parseInt(meta.find(".discover_initialX").html());
			
			var slideMove = (page-1)*-1*slideWidth;
			slideMove = 0 + slideMove + initialX;
			slideshow.animate({left: slideMove+"px"}, 500);
			
			
			
			nav.find("a").toggleClass("current", false);
			nav.find('a:eq('+(page)+')').toggleClass("current", true);
		}
	},
	
	handleSlideshowNext: function(e) {
		e.preventDefault();

		var par = $(this).parent().parent();
		var meta = par.find(".discover_meta");
		var slideshow = par.find(".discover_slideshow_container");
		var nav = par.find(".discover_slideshow_paginator");
		
		var page = parseInt(par.find("a.current").attr("id").replace("page-", ""));
		var pages = parseInt(meta.find(".discover_pages").html());
		
		if (page < pages) {
		
			page += 1;
			
			var slideWidth = parseInt(meta.find(".discover_width").html());
			var initialX = parseInt(meta.find(".discover_initialX").html());
			
			var slideMove = (page-1)*-1*slideWidth;
			slideMove = 0 + slideMove + initialX;
			slideshow.animate({left: slideMove+"px"}, 500);
			
			
			
			nav.find("a").toggleClass("current", false);
			nav.find('a:eq('+(page)+')').toggleClass("current", true);
		}		
	},
	
	buildSlideshow: function() {
		$(".discover_slideshow").each(function() {
			var obj = $(this);
			var meta = obj.find(".discover_meta");
			var paginator = obj.find(".discover_slideshow_paginator .pages");
			
			obj.find(".discover_slideshow_prev").click(discover.handleSlideshowPrevious);
			obj.find(".discover_slideshow_next").click(discover.handleSlideshowNext);
			
			var num = obj.find(".discover_slideshow_item").length;
			meta.append("<div class='discover_num'>"+num+"</div>"); // save it
			
			var numPer = obj.find(".discover_per").html();
			
			var pages = Math.ceil(num/numPer);
			meta.append("<div class='discover_pages'>"+pages+"</div>"); // save it
			
			var pageNum = 1;
			meta.append("<div class='discover_current'>"+pageNum+"</div>"); // save it

			var marginRight = obj.find(".discover_slideshow_item").css("marginRight");
			marginRight = parseInt(marginRight);
			meta.append("<div class='discover_marginRight'>"+marginRight+"</div>"); // save it			

			var slideWidth = numPer * obj.find(".discover_slideshow_item").outerWidth();
			slideWidth = parseInt(slideWidth)+marginRight*numPer;
			meta.append("<div class='discover_width'>"+slideWidth+"</div>"); // save it
			
			var initialX = obj.find(".discover_slideshow_container").css("left");
			initialX = parseInt(initialX);
			meta.append("<div class='discover_initialX'>"+initialX+"</div>"); // save it
			

			
			var insert = "current";
			for(i=1;i<=pages;i++) {
				paginator.append("<a class='"+insert+"' id='page-"+i+"' href='#'> &bull; </a>");
				insert = "";
			}
			
			paginator.find("a").click(discover.handleSlideshowPaginator);
		});
	},	
	
	buildCalloutLasts: function() {
		$("#discover_callout .discover_section").each(function() {
			$(this).find(".discover_item:last").toggleClass("last", true);
		});
	},
	
	buildPrint: function() {
		$("#discover_print").click(function(e) {
			e.preventDefault();
			window.print();
		});
	},
	
	buildColorbox: function() {
		// name the "galleries"
		$(".discover_gallery").each(function() {
			var id = $(this).attr("id");
			$(this).find("a").attr("rel", id);
		});
		
		// link the default link text to the first photo
		$(".discover_galleryLink").click(function(e) {
			e.preventDefault();
			var id = $(this).attr("id");
			$("#"+id+"_content a:first").click();
		});
		
		// connect colorbox
		$(".discover_gallery a").colorbox();
		
		
	},
	
	buildOverlay: function() {
		$(".image_overlay .overlay").each(function() {
			var x = $(this).find(".meta .x").html();
			var y = $(this).find(".meta .y").html();
						
			$(this).css({top: y+"px", left: x+"px"});
		});
		
		$(".image_overlay .overlay").hover(function() {
			$(this).find(".info").fadeIn("fast");
		}, function() {
			$(this).find(".info").fadeOut("fast");
		});
	},
	
	itemHoverOver: function() {
		//$(".hover_item").fadeOut();
		
		
		id = $(this).attr("id");
		var hoverId = "hover-"+id;
		var hover = $("#"+hoverId);
		
		//console.log(id);
		
		
		var pos = $(this).offset();
		
		var w = hover.width();
		
		var dW = ((hover.width()+60) - $(this).width())/2;
		
		//console.log(dW);
		
		$(".hover_item").not(hover).fadeOut("fast");
		
		hover.css({top: pos.top-17, left: (pos.left-dW)});
		hover.fadeIn("fast");
	},
	
	itemHoverOut: function() {
		$(this).fadeOut("fast");
		/*
		id = $(this).attr("id");
		var hoverId = "hover-"+id;
		$("#"+hoverId).hide();	
		*/
	},
	
	buildGridHover: function() {
		itemCount = 0;
		
		
		var doHover = 1;
		
		if (doHover) {
			$(".hover_info .item").each(function() {
				$(this).hover(discover.itemHoverOver, function() {});
				
				id = $(this).attr("id");
				
				if (id == undefined) {
					id = $(this).attr("id", "item-"+(itemCount++)).attr("id");
				}
			
				hoverId = "hover-"+id;
					
				var newHover = $(this).clone();
				//alert(newHover.html());
				
				newHover.attr("class", "hover_item item");
				newHover.attr("id", hoverId);
				
				var str = newHover.find(".item_link").html();
				newHover.find(".item_link").html(str+" &gt;&gt;");
				
				newHover.hover(function() {}, discover.itemHoverOut);
				
				$("body").append(newHover);
				
			});
		}
	},
	
	enable: function() {
		$("#content").delegate("ul.gallery_thumbnails a", "click.gallery_thumbnails", function(e) {
			e.preventDefault();
			var $e = $(e.target).closest("li"),
				$slides = $("#" + $e.closest("ul").attr("id") + "_content");
				$slides.find("a").eq($e.index()).click();
		});
	}
}

window.discover = discover;

$(document).ready(function(){discover.ondomready()});

})(jQuery);
