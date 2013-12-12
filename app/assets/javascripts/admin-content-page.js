$(document).ready(function() {
  // preview the page:
  $('#page_form input#preview').on('click', function() {
    $('#page_form').attr('target', "_blank");
    var original_action = $('#page_form').attr('action');
    $('#page_form').attr('action', '/administrator/content_page/preview/'+$('#page_page_name').val());
    $('#page_form').submit();
    $('#page_form').attr('target', "_self");
    $('#page_form').attr('action', original_action);
  });
  
  // Submit the form, properly:
  $('#page_form input#publish').on('click', function() {
    $('#page_form').attr('target', "_self");
    $('#page_form').attr('action', '/administrator/content_page/save_new_page/');
    $('#page_form').submit();
  });
});
