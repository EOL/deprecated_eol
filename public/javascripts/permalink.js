EOL.init_curation_behaviours = function() {

  (function($form) {
    var actions = {
      trusted: function() {
        this.closest("fieldset").find("ul").hide()
          .end().find("select[name*=visibility]").prop("disabled", false).trigger("change");
      },
      unreviewed: function() {
        this.closest("fieldset").find("ul").hide()
          .end().find("select[name*=visibility]").prop("disabled", false).trigger("change");
      },
      untrusted: function() {
        this.closest("fieldset").find("select[name*=visibility]").val("hidden").prop("disabled", true)
          .end().find("ul").hide().filter(".untrusted").show();
      },
      inappropriate: function() {
        this.closest("fieldset").find("select[name*=visibility]").val("hidden").prop("disabled", true)
          .end().find("ul").hide();
      },
      hidden: function () {
        this.closest("fieldset").find("ul").hide().filter(".hidden").show();
      },
      visible: function() {
        this.closest("fieldset").find("ul").hide();
      }
    };

    $form.find("select").change(function() {
      var $e = $(this);
      if ($e.is(":enabled")) {
        actions[$e.find(":selected").text().toLowerCase()].apply($e);
      }
    }).trigger("change");

  })($("form.review_status"));

}
$(function() {

  (function($main) {
    $main.find("a.jp-play").each(function() {
      switch($(this).attr('data-mime_type')) {
        case 'audio/mpeg':
          var media = { mp3: $(this).attr('href') };
          var supplied = "mp3";
          break;
        default:
          // Mime type unknown
          var media = {};
      }
      $("#player").jPlayer({
        swfPath: "/javascripts/jplayer/js",
        supplied: supplied,
        cssSelectorAncestor: "#player_interface",
        ready: function () {
          $(this).jPlayer("setMedia", media);
        }
      });
    });
  })($("#main"));

  EOL.init_curation_behaviours();
  $('#tasks').ajaxSuccess(function() {
    EOL.init_curation_behaviours();
  });
});