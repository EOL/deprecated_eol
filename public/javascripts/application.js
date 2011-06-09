$(function() {
  $(".thumbnails li").hover(function() {
    var $e = $(this),
        $thumbs = $e.closest(".thumbnails"),
        margin = $thumbs.find("li").eq(0).outerWidth(true) - $e.outerWidth();
        direction = ($e.index() > $thumbs.find("li").length / 2 - 1) ? "right" : "left",
        pos = $e.position();
    pos.right = $thumbs.find("ul").width() - $e.outerWidth() - pos.left + margin;
    $thumbs.find(".term p").css({
      margin: 0,
      textAlign: direction
    }).css("margin-" + direction, pos[direction]).text($e.find("img").attr("alt"));
  }).eq(0).mouseover();

  $(".heading form.filter").find(":submit").hide().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });

  (function($ss) {
    $ss.each(function() {
      var $gallery = $(this),
          thumbs = [];
      $("<ul />", { "class": "thumbnails" }).insertBefore($gallery.find("p.all"));
      $gallery.find(".image > img").each(function() {
        var $e = $(this);
        thumbs.push("<li><a href=\"#\"><img src=\"" +
                    $e.attr("data-thumb") + "\" alt=\"" + $e.attr("alt") +
                    "\" /></a></li>");
      });
      $gallery.find(".thumbnails").html(thumbs.join(""));
      $gallery.find(".thumbnails li").eq(0).addClass("active");
    });

    var loading_complete = $ss.find(".image").length;
    $ss.find(".image > img").each(function() {
      this.onload = function() {
        if (!--loading_complete) {
          var h = $ss.find(".images").height();
          h -= parseInt($ss.find(".image").css("padding-bottom"), 10);
          $ss.find(".image > img").each(function() {
            $(this).css("top", (h / 2 - this.height / 2) + "px");
          });
        };
      };
    });

    $ss.find(".thumbnails").delegate("a", "click", function() {
      var $e = $(this).closest("li");
      $e.closest("ul").find(".active").removeClass("active");
      $e.addClass("active");
      return false;
    });
    if ("cycle" in $.fn) {
      $ss.find(".images").cycle({
        speed: 500,
        timeout: 0,
        pagerAnchorBuilder: function(idx) {
          return $ss.selector + " .thumbnails a:eq(" + idx + ")";
        }
      });
    }
  })($(".gallery"));

  (function($language) {
    $language.find("p a").click(function() {
      var $e = $(this),
          $ul = $e.closest($language.selector).find("ul");
      if ($ul.is(":visible")) {
        $ul.hide();
        return false;
      }
      $ul.show();
      $(document).click(function(e) {
        if (!$(e.target).closest($language.selector).length) {
          $language.find("ul").hide();
          $(this).unbind(e);
        }
      });
      return false;
    });

    // Remove once language links wired up
    $language.find("ul a").click(function() {
      $(this).closest("ul").hide();
      return true;
    });
  })($(".language"));

  $("input[placeholder]").each(function() {
    var $e = $(this),
        placeholder = $e.attr("placeholder");
    $e.removeAttr("placeholder").val(placeholder);
    $e.bind("focus blur", function(e) {
      if (e.type === "focus" && $e.val() === placeholder) { $e.val(""); }
      else { if (!$e.val()) { $e.val(placeholder); } }
    });
  });
});
