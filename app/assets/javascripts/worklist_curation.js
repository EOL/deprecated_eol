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
      hide: function () {
        this.closest("fieldset").find("ul").hide().filter(".hidden").show();
      },
      show: function() {
        this.closest("fieldset").find("ul").hide();
      }
    };

    $form.find("select").change(function() {
      var $e = $(this);
      if ($e.is(":enabled")) {
        // NOTE - this *relies* on the curation select options having the english name--and ONLY that name--in the
        // class:
        actions[$e.find(":selected").attr('class')].apply($e);
      }
    }).trigger("change");

    $form.find("fieldset").each(function() {
      if ($(this).find('select').length === 0) {
        $(this).find('ul').hide();
      }
    });

  })($("form.review_status"));

};
