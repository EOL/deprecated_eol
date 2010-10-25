$(document).ready(function() {
  // Reload the form when section changes
  $('select#content_section_id').change(function() {
    content_section_id = this.options[this.selectedIndex].value;
    $.ajax({
      url: '/administrator/content_page/get_content_pages',
      type: 'POST',
      data: {id:content_section_id}
    });
  });
  // reload form when page changes
  $('select#content_pages_id').change(function() {
    page_id = this.options[this.selectedIndex].value;
    $.ajax({url:'/administrator/content_page/get_page_content/'+ page_id});
    return false;
  });
  // preview the page:
  $('#page_form input#preview').click(function() {
		$('#page_form').attr('target', "_blank");
		$('#page_form').attr('action', '/administrator/content_page/preview/'+$('#page_form').attr('data-page_id'));
		$('#page_form').submit();
  });
  // Submit the form, properly:
  $('#page_form input#publish').click(function() {
		$('#page_form').attr('target', "_self");
		$('#page_form').attr('action', '/administrator/content_page/update/'+$('#page_form').attr('data-page_id'));
		$('#page_form').submit();
  });
});
