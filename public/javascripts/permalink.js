$(function() {
  (function($form) {
    var actions = {
      trusted: function() {
        this.closest("form").find("select[name=visibility]").prop("disabled", false);
      },
      untrusted: function() {
        this.closest("form").find("select[name=visibility]").prop("disabled", true);
      }
    };
    actions.inappropriate = actions.untrusted;

    $form.find("select[name=status]").change(function() {
      var $e = $(this);
      actions[$e.find(":selected").val()].apply($e);
    });
  })($("form.review_status"));
});
