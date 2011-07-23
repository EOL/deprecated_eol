$(function() {
  $('#media_list form.taxon_concept_exemplar_image').each(function() {
    $(this).find(":submit").hide().end().find('label, input[type="radio"]').accessibleClick(function() {
      $(this).addClass('busy').parent().find('input[type="radio"]').attr('checked', true).closest('form').submit();
    });
  });
});
