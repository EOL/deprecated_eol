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
  // Allow the user to show extra attribution information for text - TODO - this could be far more elegant.
  $('div.content-article div.attribution .expand-text-attribution').click(function(e) {
    $('div.content-article div.'+$(this).attr('id').substring(4) +' div.credit').each(function(e){ e.fadeIn(); });
    $(this).fadeOut();
    return false;
  });
  // toggle image attribution on click
  $('img#main-image').click(function() {
    $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
  });
  //clicking map will show attributions
  $('img#map').click(function (e) {
    $('map_attributions').click();
  });
  // slide in text comments (TEXT OBJECT - slides down, doesn't POPUP)
  $('div.text_buttons div.comment_button a').click(function(e) {
    data_object_id = $(this).attr('data-data_object_id');
    textCommentsDiv = "text-comments-wrapper-" + data_object_id;
    textCommentsWrapper = "#" + textCommentsDiv;
    if (true) { // TODO!  This needs to check whether it's open now or not.
      $.ajax({
        url: $(this).attr('href'),
        data: { body_div_name: textCommentsDiv },
        success: function(result) {$(textCommentsWrapper).html(result);},
        error: function(result) {$(textCommentsWrapper).html("<p>Sorry, there was an error.</p>");},
        complete: function() { $(textCommentsWrapper).slideDown(); }
      });
    } else {
      $('#'+textComments).slideUp();
    }
    return false;
  });
  $('div.text_buttons div.curate_button a').click(function(e) {
    data_object_id = $(this).attr('data-data_object_id');
    textCuration = "text-curation-" + data_object_id;
    textCurationWrapper = "text-curation-wrapper-" + data_object_id;
    if ($(textCurationWrapper).style.display == 'none') {
      new Ajax.Updater(textCuration, this.href,
                       {asynchronous:true, evalScripts:true, method:'get',
                        parameters: { body_div_name: textCuration },
                        onLoading: Effect.BlindDown(textCurationWrapper),
                        onComplete: EOL.reload_behaviors
                        });
    } else {
      Effect.DropOut(textCurationWrapper);
    }
    return false;
  });
  // Fade in the taxa comments! (TAB)
  $('#taxa-comments a').click(function(e) {
    if (!$('taxaCommentsWrap').childNodes[2]) {
      var loaded = true;// TODO - I think this is unused and should be deleted, but I am a chicken and won't do it myself (JRice)
      EOL.load_taxon_comments_tab();
    }
  });
  // clicking on a thumbnail in the mediacenter
  $('div#image-collection div#thumbnails a').click(function(e) {
    var image_id   = $(this).attr('id').match(/\d*$/)[0]; // eg. id="thumbnail_123"
    var image_hash = EOL.MediaCenter.image_hash[image_id];
    eol_update_image( image_hash.smart_image, image_hash );
    return(false);
  });
  //clicking on maps link in mediacenter
  $('#tab_media_center #maps a').click(function(e) {
    var map_div = $$('#media-maps div')[0];
    if (map_div && map_div.style.display == 'none') {
        var taxon_concept_id = $('map-taxon-concept-id').value;
        var data_server_endpoint = $('map-data-server-endpoint').value;
        var gmap_key = $('map-gmap-key').value;
        var tile_server_1 = $('map-tile-server-1').value;
        var tile_server_2 = $('map-tile-server-2').value;
        var tile_server_3 = $('map-tile-server-3').value;
        var tile_server_4 = $('map-tile-server-4').value;
        var so = new SWFObject("/EOLSpeciesMap.swf", "swf", "100%", "100%", "9"); 
        so.addParam("allowFullScreen", "true");
        so.addVariable("swf", "");
        //var taxon_concept_id = $('map-taxon-concept-id').value;
        //var taxon_concept_id = 13839800;
        so.addVariable("taxon_id", taxon_concept_id);
        so.addVariable("data_server_endpoint", data_server_endpoint);
        so.addVariable("gmap_key", gmap_key);
        var tileServers = new Array();
        tileServers[0] = tile_server_1;
        tileServers[1] = tile_server_2;
        tileServers[2] = tile_server_3;
        tileServers[3] = tile_server_4;
        so.addVariable("tile_servers", tileServers);
        so.write("map-image");
        map_div.style.display = 'block';
    }
    return false;
  });
});
