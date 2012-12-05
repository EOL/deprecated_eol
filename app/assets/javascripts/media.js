$(function() {
  (function($fieldsets) {
    var actions = {
      disableVisibility: function() {
        this.find(".visibility").val("hidden").prop("disabled", true);
      },
      trusted: function() {
        this.find(".visibility").prop("disabled", false).trigger("change");
        this.find("a").hide();
      },
      untrusted: function() {
        actions.disableVisibility.apply(this);
        this.find("a").show();
        this.closest("li").addClass("untrusted");
      },
      inappropriate: function() {
        actions.disableVisibility.apply(this);
        this.find("a").show();
        this.closest("li").addClass("inappropriate");
      },
      unreviewed: function() {
        actions.disableVisibility.apply(this);
        this.find("a").hide();
      }
    };

    $fieldsets.find("select").change(function() {
      var $e = $(this);
      if ($e.is(":enabled")) {
        $e.closest("li").removeClass(function() {
          return $(this).attr("class").replace(/first/, "");
        });
        actions[$e.find(":selected").val()].apply($e.closest("fieldset"));
      }
    }).trigger("change");

  })($(".review_status"));
});
