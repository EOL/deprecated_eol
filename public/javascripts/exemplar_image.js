$(function() {
  $("#media_list form.taxon_concept_exemplar_image").each(function() {
    var $form = $(this)
    $form.find('label').click(function() {
      $(this).find('input[type="radio"]').attr('checked', true);
      $form.submit();
    });
    $form.find('input[type="radio"]').click(function() {
      $form.submit();
    });
  });
});