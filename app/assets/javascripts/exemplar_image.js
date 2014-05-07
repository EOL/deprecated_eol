$(function() {
  $('#media_list form.taxon_concept_exemplar_image').each(function() {
    // NOTE - Don't add 'label' to the find, here, because then you'll have TWO events when the user clicks on the
    // actual button.
    $(this).find(":submit").hide().end().find('label').unbind('click').accessibleClick(function() {
      $(this).addClass('busy').parent().find('input[type="radio"]').attr('checked', true).closest('form').submit();
    });
  });
});
