function move_to_post_if_available(e,t){if(m=e.match(/\/posts\/([0-9]+)$/)){var i=m[1];if($("#post_"+i).length>0)return t&&history.pushState(null,null,e),move_to_post(i),!1}}function move_to_post(e){$("html,body").animate({scrollTop:$("#post_"+e).offset().top},300)}$(function(){$("a.button.link").on("click",function(){$(".permalink").css({display:"none"}).hide();var e=$(this).closest("ul").siblings(".permalink");return e.css({display:"block"}).show(),!1}),$(".permalink .close").on("click",function(){var e=$(this).closest(".permalink");return e.css({display:"none"}).hide(),!1}),$(".permalink input[type=text]").on("click",function(){$(this).select()}),$("a:not(.close a):not(.button.link)").on("click",function(){var e=$(this).attr("href");return move_to_post_if_available(e,!0)}),move_to_post_if_available(window.location.pathname,!1)}),"undefined"!=typeof CKEDITOR&&(CKEDITOR.config.contentsCss="https://media.eol.org//assets/forum.css",CKEDITOR.config.bodyClass="post_text");