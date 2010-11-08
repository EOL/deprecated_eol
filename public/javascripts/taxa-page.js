if (!EOL) { EOL = {}; }
if (!EOL.change_toc) {
  EOL.change_toc = function(new_id) {
    updateReferences();
    $('#current_content').val(new_id);
    $('#toc a.toc_item').removeClass('active');
    $('#toc a#category_id_'+new_id).addClass('active');
    $('#new_text_toc_text').attr('href', $('#new_text_toc_text').attr('href').replace(/toc_id=\d+/, 'toc_id='+new_id));
    $('select#data_objects_toc_category_toc_id').val(new_id);
    $('#center-page-content').css({height:'auto'});
    try {
      EOL.Rating.init_links('#center-page-content');
    } catch(err) {
      EOL.log('EOL.Rating was not loaded.');
    }
    try {
      EOL.Text.init_edit_links();
    } catch(err) {
      EOL.log('EOL.Text was not loaded.');
    }
  };
}

$(document).ready(function() {
  // TODO - move to its own js (for maps view)
  // clicking map will show its attributions
  $('img#map').click(function () {
    $('map_attributions').click();
  });
  // "view/edit" common names link for curators should open that toc item and jump down there:
  $('#curate-common-names').click(function() {
    if (EOL.common_names_toc_id) {
      $(window).scrollTop($('#center-page-content').offset().top - 30);
      $('a#category_id_'+EOL.common_names_toc_id).click();
    }
  });
  // when clicking on any tab in the media center - replace the pane DIV with the response
  $('#tab_media_center a').click(function() {
    $('.overlay a.close').click();
    link = $(this);
    $.ajax({
      url: link.attr('href'),
      success: function(response) {
        $('div.tab-panes').html(response);
        $('#tab_media_center a').removeClass('active');
        link.addClass('active');
      },
      error: function() {$('div.tab-panes').html('<p>Sorry, there was an error.</p>');}
    });
    return false;
  });
  // Change TOC item:
  $('#toc a.toc_item').click(function() {
    id = $(this).attr('id').replace(/\D+/, '');
    $.ajax({
      url: $(this).attr('href'),
      beforeSend: function() { $('#center-page-content').fadeTo(800, 0.3); $('#center-page-content-loading').fadeIn(); },
      complete: function() {
        // I'm removing the filter after the fade.  In IE7, fonts are NOT aliased when filtered!
        $('#center-page-content').fadeTo(300, 1.0, function() {$('#center-page-content').css({filter: ''});});
        $('#center-page-content-loading').fadeOut();
      },
      success: function(response) {
        $('#center-page-content').html(response);
        EOL.change_toc(id);
      },
      error: function(request) {$('#center-page-content').html('<p>Sorry, there was an error.</p>');}
    });
    return false;
  });
  // Contribution section popups:
  $('ul#contribute a.show_popup').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      complete: function(request) {$('#contribute-info').slideDown();},
      success: function(result) {$('#contribute-info').html(result);},
      error: function() {$('#contribute-info').html('<p>Sorry, there was an error.</p>');}
    });
    return false;
  });
  $('a.ajax_delay_click').removeClass('ajax_delay_click').attr('onclick', ''); // No more need for the delay.
  // TODO - the click() here isn't working.  For the moment, I'm okay with that; the greying-out is indication that something
  // is happening.  But eventually, it would be best if we could get the click to work so the user doesn't have to do it again!
  $('a.delayed_click').removeClass('delayed_click').click(); // Click anything that was clicked prematurely.
  // If we did something on page load to show the ajax indicator, hide it now:
  $('#ajax-indicator').fadeOut();
  // Tell developers we're ready:
  EOL.log("EOL Log enabled.");
});

// Show some spinners when we're doing stuff:
$('#ajax-indicator, #center-page-content-loading').ajaxStart(function() {
  $(this).fadeIn();
});
$('#ajax-indicator, #center-page-content-loading').ajaxComplete(function() {
  $(this).fadeOut();
});

// Show some spinners when we're doing stuff:
$('#ajax-indicator').ajaxStart(function() {
  $(this).show();
});
$('#center-page-content-loading').ajaxStart(function() {
  $(this).show();
});
$('#ajax-indicator').ajaxComplete(function() {
  $(this).hide();
});
$('#center-page-content-loading').ajaxComplete(function() {
  $(this).hide();
});
