if (!EOL) { EOL = {}; }
if (!EOL.fade_content_page_form) {
  EOL.fade_content_page_form = function() {
    $('#content_page').fadeTo(800, 0.3);
  };
  EOL.fade_in_content_page_form = function() {
    $('#content_page').fadeTo(300, 1.0, function() {$('#content_page').css({filter: ''});});
  };
}

$(document).ready(function() {
  // Reload the form when section changes
  $('select#content_section_id').change(function() {
    content_section_id = this.options[this.selectedIndex].value;
    $.ajax({
      beforeSend: function() { EOL.fade_content_page_form(); },
      complete: function() { EOL.fade_in_content_page_form(); },
      url: '/administrator/content_page/get_content_pages',
      type: 'POST',
      data: {id:content_section_id}
    });
  });
  // reload form when page changes
  $('select#content_pages_id').change(function() {
    page_id = this.options[this.selectedIndex].value;
    $.ajax({
      beforeSend: function() { EOL.fade_content_page_form(); },
      complete: function() { EOL.fade_in_content_page_form(); },
      url:'/administrator/content_page/get_page_content/'+ page_id
    });
    return false;
  });
  // reload form when archived version of page changes
  $('select#content_page_archive_id').change(function() {
    page_id = $('#content_pages_id').val();
    archieve_id = this.options[this.selectedIndex].value;
    $.ajax({
      url: '/administrator/content_page/get_archive_page_content/',
      type: 'POST',
      data: {page_id:page_id, archieve_id:archieve_id},
      success: function(){ $('#content_page_archive_id').val(archieve_id); }
    });
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
  $('input#page_active').unbind('click');
  $('input#page_active').click(function() {
    if ($('input#page_active').attr('checked')) {
      $('input#page_active').parent().removeClass('warn');
    } else {
      $('input#page_active').parent().addClass('warn');
    }
  });
});
