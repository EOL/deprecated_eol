$(document).ready(function() {
  // preview the page:
  $('#page_form input#preview').click(function() {
		$('#page_form').attr('target', "_blank");
		$('#page_form').attr('action', '/administrator/content_page/preview/'+$('#page_form').attr('data-page_id'));
		$('#page_form').submit();
  });
  // Submit the form, properly:
  /*$('#page_form input#publish').click(function() {
		$('#page_form').attr('target', "_self");
		$('#page_form').attr('action', '/administrator/content_page/save_translation/');
		$('#page_form').submit();
  });*/
});
