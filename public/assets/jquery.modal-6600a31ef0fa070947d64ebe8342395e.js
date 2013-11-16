/*
  Modal Plugin by Shane Riley
  Calling:
  $("a").modal();
  Options:
  {
    ajax: true, // Whether to load the modal from the href or if it already exists in page
    duration: 500, // Fade in/out speed, in milliseconds
    position: {}, // An object containing CSS properties for positioning, i.e.: top, left, marginLeft
    modal_layer: "#modal_layer", // id selector for modal layer (full-page overlay)
    modal_container: "<div />", // HTML element used to construct modal
    modal: "#modal" // id selector for modal container
    modal_class: "user new" // Classes to be added to modal, separated by spaces
    ajaxCallback: function() // Called after Ajax request AND modal animation
    beforeSend: function() // Called before Ajax request
    beforeShow: function() // Called after Ajax request and before animation
    afterClose: function() // Called after closing animation
    bind_type: "live" // Method used to bind click event ("live" or "bind")
    align_to_trigger: "top" // Vertical alignment relative to trigger element. ("top", "middle", "bottom")
  };
  To load a specific part of a request into an Ajax modal, add a rel attribute with the
  css selector needed to access the parent element that you want to create a modal from.
  #modal_layer is always a div.
*/
(function(e){e.fn.modal=function(t){function a(){e(document).bind("keyup",function(t){t.keyCode===27&&e(r.modal).is(":visible")&&(p(e(r.modal),e(r.modal_layer)),e(document).unbind(t))})}function f(){var t=function(t,n,i){return t.attributes={id:r[n].charAt(0)==="#"?r[n].substring(1):null,"class":r[n].charAt(0)==="."?r[n].substring(1):null},e(i,t.attributes).appendTo(document.body)};return s.length||(s=t(s,"modal",r.modal_container)),i.length||(i=t(i,"modal_layer","<div />")),r.modal_class&&s.addClass(r.modal_class),s}function l(){s.css(e.extend({left:"50%",marginLeft:-(s.outerWidth()/2)},r.position))}function c(){return o=e(this),typeof r.beforeSend=="function"&&r.beforeSend(o),f.apply(this),l(),a(),h(),!1}function h(){s.innerHeight()>window.innerHeight?s.css({position:"absolute",top:r.position.top||window.pageYOffset+20}):s.css({position:"fixed",top:r.position.top||20}),r.align_to_trigger&&r.align_to_trigger in u&&(s.css("position","absolute"),u[r.align_to_trigger]()),typeof r.beforeShow=="function"&&r.beforeShow.apply(o),i.data("original_opacity")||i.data("original_opacity",i.css("opacity")),i.show().css({opacity:0}).animate({opacity:i.data("original_opacity")},r.duration),s.show().css({opacity:0}).animate({opacity:1},r.duration,function(){typeof r.ajaxCallback=="function"&&r.ajaxCallback.apply(o)}),e(r.modal_layer+", "+r.modal+" a.close").live("click",function(){return p(s,i),!1}),s.trigger("modal_open")}function p(){for(var e=0;e<arguments.length;e++)arguments[e].fadeOut(r.duration,function(){typeof r.afterClose=="function"&&r.afterClose(),r.modal_class&&s.removeClass(r.modal_class)})}function d(){s=e(r.modal),i=e(r.modal_layer),o=e(this),typeof r.beforeSend=="function"&&r.beforeSend(),f.apply(this),l(),a(),s.empty();var t=o.attr("rel")?o.attr("href")+" "+o.attr("rel"):o.attr("href");if(/.+\.(png|jpg|jpeg|gif)(\?.+)?$/i.test(t)){var n=new Image;n.src=t,n.onload=function(){n.width>s.width()&&(n.width=s.width()),s.html(n).css({width:n.width,left:"50%",marginLeft:-(n.width/2)}),h()}}else s.load(t,h);return!1}var n={ajax:!0,duration:500,position:{},modal_layer:"#modal_layer",modal_container:"<div />",modal:"#modal",modal_class:null,ajaxCallback:null,beforeSend:null,beforeShow:null,afterClose:null,bind_type:"live",align_to_trigger:null},r=e.extend(n,t);r.left=(parseInt(e("body").width())-r.width)/2;var i=e(r.modal_layer),s=e(r.modal),o,u={top:function(){s.css("top",o.offset().top)},bottom:function(){var e=o.offset().top-s.innerHeight();e<0&&(e=r.position.top||0),s.css("top",e)},middle:function(){var e=o.offset().top-s.innerHeight()/2;e<0&&(e=r.position.top||0),s.css("top",e)}};return this[r.bind_type]("click.modal",r.ajax?d:c)}})(jQuery);