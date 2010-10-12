if (!EOL) EOL = {};
if (!EOL.change_toc) EOL.change_toc = function(new_id) {
  updateReferences();
  $('#current_content').val(new_id);
  $('#toc a.toc_item').removeClass('active');
  $('#toc a#category_id_'+new_id).addClass('active');
  $('#new_text_toc_text').attr('href', $('#new_text_toc_text').attr('href').replace(/toc_id=\d+/, 'toc_id='+new_id));
  $('select#data_objects_toc_category_toc_id').val(new_id);
  $('#center-page-content').css({height:'auto'});
  try {
    EOL.Rating.init_links('#center-page-content');
  } catch(err) {}
};

$(document).ready(function() {
  // TODO - move to its own js (for maps view)
  // clicking map will show its attributions
  $('img#map').click(function (e) {
    $('map_attributions').click();
  });
  // when clicking on any tab in the media center - replace the pane DIV with the response
  $('#tab_media_center a').click(function() {
    link = $(this);
    $.ajax({
      url: link.attr('href'),
      success: function(response) {
        $('div.tab-panes').html(response);
        $('#tab_media_center a').removeClass('active');
        EOL.log(this);
        link.addClass('active');
        EOL.log("This: "+link.attr('id'));
        EOL.log("Parent: "+link.parent().attr('id'));
        EOL.log("Grampa: "+link.parent().parent().attr('id'));
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

// Displays the Photosynth interface in the image pane.
function load_photosynth_interface(source_url) {
  // TODO - put this in the view, and just show/hide it.  We CANNOT HAVE html here, it blows up the images.  Also, note I
  // changed the id on the table to a class (of the same name).  Same with main-image-bg!
  synth = "<table id='main-image-table'><tr><td><iframe frameborder='0' src='" + source_url.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe><img id='main-image'></td></tr></table>";
  $('#main-image-bg').html = synth;
  // This will display a photosynth icon if a thumbnail photosynth image is clicked.
  var string = params.source_url; //source_url is from [views/taxa/_image_collection]
  if(string.search(/photosynth.net/) == -1) { //regular static image    
      $('#photosynth-message').html = "";          
  } else { //photosynth image
    // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
    $('#photosynth-message').html = "<a href=javascript:load_photosynth_interface('" + escape(params.source_url) + "')><img src='http://mslabs-999.vo.llnwd.net/e1/inc/images/master/logo.png' height='27' alt='Photosynth' title='Image is part of a Photosynth'></a>";    
  }
}

// Show some spinners when we're doing stuff:
$('#ajax-indicator').ajaxStart(function() {
  $(this).fadeIn();
});
$('#center-page-content-loading').ajaxStart(function() {
  $(this).fadeIn();
});
$('#ajax-indicator').ajaxComplete(function() {
  $(this).fadeOut();
});
$('#center-page-content-loading').ajaxComplete(function() {
  $(this).fadeOut();
});
