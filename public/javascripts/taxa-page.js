// Behaviours
$(document).ready(function() {
  // Follow image-specific links in the URL:
  if (window.checked_for_image_hash_tag == null) {
    window.checked_for_image_hash_tag = true;
    var match = window.location.href.match(/image_id=(\d*)/);
    if (match != null) {
      var image_id = match[1];
      var image_hash = EOL.MediaCenter.image_hash[image_id];
      eol_update_image( image_hash.smart_image, image_hash );
    }
  }
  // Allow the user to show extra attribution information for text
  $('.expand-text-attribution').click(function(e) {
    $('div.' + $(this).attr('id').substring(4) +' div.credit').each(function(){ $(this).fadeIn(); });
    $(this).fadeOut();
    return false;
  });
  // clicking the large image shows its attribution
  $('img#main-image').click(function() {
    $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
  });
  // clicking map will show its attributions
  $('img#map').click(function (e) {
    $('map_attributions').click();
  });
  // slide in text comments (TEXT OBJECT - slides down, doesn't POPUP)
  $('div.text_buttons div.comment_button a').click(function(e) {
    data_object_id = $(this).attr('data-data_object_id');
    textCommentsDiv = "text-comments-wrapper-" + data_object_id;
    textCommentsWrapper = "#" + textCommentsDiv;
    $.ajax({
      url: $(this).attr('href'),
      data: { body_div_name: textCommentsDiv },
      success: function(result) {$(textCommentsWrapper).html(result);},
      error: function() {$(textCommentsWrapper).html("<p>Sorry, there was an error.</p>");},
      complete: function() { $(textCommentsWrapper).slideDown(); }
    });
    return false;
  });
  $('div.text_buttons div.curate_button a').click(function(e) {
    data_object_id = $(this).attr('data-data_object_id');
    textCuration = "text-curation-" + data_object_id;
    textCurationWrapper = "#text-curation-wrapper-" + data_object_id;
    $.ajax({
      url: $(this).attr('href'),
      data: { body_div_name: textCuration },
      success: function(result) { $('#'+textCuration).html(result) },
      error: function() {$(textCurationWrapper).html("<p>Sorry, there was an error.</p>");},
      complete: function() { $(textCurationWrapper).slideDown() }
    });
    return false;
  });
  // YOU WERE HERE ... trying to fix the tabs.
  $("ul#tab_media_center").tabs("div.tab-panes > div", {effect: 'ajax'});
  // clicking on a thumbnail in the mediacenter
  $('div#image-collection div#thumbnails a').click(function(e) {
    var image_id   = $(this).attr('id').match(/\d*$/)[0]; // eg. id="thumbnail_123"
    var image_hash = EOL.MediaCenter.image_hash[image_id];
    eol_update_image( image_hash.smart_image, image_hash );
    return(false);
  });
  //clicking on maps link in mediacenter
  $('#tab_media_center #maps a').click(function() {
  });
  $('#toc a.toc_item').click(function() {
    // TODO - do we need to dismiss the #insert_text_popup div when this happens?
    $.ajax({
      url: $(this).attr('href'),
      success: function(request) {updateReferences(); $('#toc a.toc_item').removeClass('active'); $(this).delay(100).addClass('active');},
      error: function(request) {$('#center-page-content').html('<p>Sorry, there was an error.</p>');}
    });
    return false;
  });
  // Contribution help popups:
  $('ul#contribute a.show_popup').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      complete: function(request) {$('#contribute-info').slideDown();},
      success: function(result) {$('#contribute-info').html(result);},
      error: function() {$('#contribute-info').html('<p>Sorry, there was an error.</p>');}
    });
    return false;
  });
});

// Displays the Photosynth interface in the image pane.
function load_photosynth_interface(source_url)
{
  // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
  synth = "<table id='main-image-table'><tr><td><iframe frameborder='0' src='" + source_url.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe><img id='main-image'></td></tr></table>";
  $('#main-image-bg').html = synth;  
}

