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
(function($) {
  $.fn.modal = function(options) {
    var defaults = {
      ajax: true,
      duration: 500,
      position: {},
      modal_layer: "#modal_layer",
      modal_container: "<div />",
      modal: "#modal",
      modal_class: null,
      ajaxCallback: null,
      beforeSend: null,
      beforeShow: null,
      afterClose: null,
      bind_type: "live",
      align_to_trigger: null
    };
    var opts = $.extend(defaults, options);
    opts.left = (parseInt($("body").width()) - opts.width) / 2;
    var $modal_layer = $(opts.modal_layer),
        $modal = $(opts.modal),
        $a;
    var align_modal = {
      top: function() { $modal.css("top", $a.offset().top); },
      bottom: function() {
        var top = $a.offset().top - $modal.innerHeight();
        if (top < 0) { top = opts.position.top || 0; }
        $modal.css("top", top);
      },
      middle: function() {
        var top = $a.offset().top - $modal.innerHeight() / 2;
        if (top < 0) { top = opts.position.top || 0; }
        $modal.css("top", top);
      }
    };
    return this[opts.bind_type]("click.modal", (opts.ajax) ? create : open);
    function escBind() {
      $(document).bind("keyup", function(e) {
        if (e.keyCode === 27 && $(opts.modal).is(":visible")) {
          close($(opts.modal), $(opts.modal_layer));
          $(document).unbind(e);
        }
      });
    }
    function configureModal() {
      var createModalElement = function($e, selector, container) {
        $e.attributes = {
          "id": (opts[selector].charAt(0) === "#") ? opts[selector].substring(1) : null,
          "class": (opts[selector].charAt(0) === ".") ? opts[selector].substring(1) : null
        }
        return $(container, $e.attributes).appendTo(document.body);
      };
      if (!$modal.length) {
        $modal = createModalElement($modal, "modal", opts.modal_container);
      }
      if (!$modal_layer.length) {
        $modal_layer = createModalElement($modal_layer, "modal_layer", "<div />");
      }
      if (opts.modal_class) { $modal.addClass(opts.modal_class); }
      return $modal;
    }
    function positionModal() {
      $modal.css($.extend({
        left: "50%",
        marginLeft: -($modal.outerWidth() / 2)
      }, opts.position));
    }
    function open() {
      $a = $(this);
      if (typeof opts.beforeSend === "function") {
        opts.beforeSend($a);
      }
      configureModal.apply(this);
      positionModal();
      escBind();
      animateModal();
      return false;
    }
    function animateModal() {
      if ($modal.innerHeight() > window.innerHeight) {
        $modal.css({
          position: "absolute",
          top: opts.position.top || window.pageYOffset + 20
        });
      }
      else {
        $modal.css({
          position: "fixed",
          top: opts.position.top || 20
        });
      }
      if (opts.align_to_trigger && opts.align_to_trigger in align_modal) {
        $modal.css("position", "absolute");
        align_modal[opts.align_to_trigger]();
      }
      if (typeof opts.beforeShow === "function") { opts.beforeShow.apply($a); }
      if (!$modal_layer.data("original_opacity")) {
        $modal_layer.data("original_opacity", $modal_layer.css("opacity"));
      }
      $modal_layer.show().css({opacity: 0}).animate({opacity: $modal_layer.data("original_opacity")}, opts.duration);
      $modal.show().css({opacity: 0}).animate({opacity: 1}, opts.duration, function() {
        if (typeof opts.ajaxCallback === "function") {
          opts.ajaxCallback.apply($a);
        }
      });
      $(opts.modal_layer + ", " + opts.modal + " a.close").live("click", function() {
        close($modal, $modal_layer);
        return false;
      });
      $modal.trigger("modal_open");
    }
    function close() {
      for (var i = 0; i < arguments.length; i++) {
        arguments[i].fadeOut(opts.duration, function() {
          if (typeof opts.afterClose === "function") {
            opts.afterClose();
          }
          if (opts.modal_class) { $modal.removeClass(opts.modal_class); }
        });
      }
    }
    function create() {
      $modal = $(opts.modal);
      $modal_layer = $(opts.modal_layer);
      $a = $(this);
      if (typeof opts.beforeSend === "function") {
        opts.beforeSend();
      }
      configureModal.apply(this);
      positionModal();
      escBind();
      $modal.empty();
      var url = $a.attr("rel") ? $a.attr("href") + " " + $a.attr("rel") : $a.attr("href");
      if (/.+\.(png|jpg|jpeg|gif)(\?.+)?$/i.test(url)) {
        var img = new Image();
        img.src = url;
        img.onload = function() {
          if (img.width > $modal.width()) { img.width = $modal.width(); }
          $modal.html(img).css({
            width: img.width,
            left: "50%",
            marginLeft: -(img.width / 2)
          });
          animateModal();
        };
      } else {
        $modal.load(url, animateModal);
      }
      return false;
    }
  };
})(jQuery);