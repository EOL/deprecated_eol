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
  // toggle image attribution on click
  $('img#main-image').click(function() {
    EOL.popup_links['large-image-attribution-button-popup-link'].click(); // "click" the PopupLink
  });
  // slide in text comments (TEXT OBJECT - slides down, doesn't POPUP)
  $('div.text_buttons div.comment_button a').click(function(e) {
    data_object_id = this.readAttribute('data-data_object_id');
    textComments = "text-comments-" + data_object_id;
    textCommentsWrapper = "text-comments-wrapper-" + data_object_id;
    if ($(textCommentsWrapper).style.display == 'none') {
      new Ajax.Updater(textComments, this.href,
                       {asynchronous:true, evalScripts:true, method:'get',
                        parameters: { body_div_name: textComments },
                        onLoading: Effect.BlindDown(textCommentsWrapper)
                        });
    } else {
      Effect.DropOut(textCommentsWrapper);
    }
    e.stop();
  });
  $('div.text_buttons div.curate_button a').click(function(e) {
    data_object_id = this.readAttribute('data-data_object_id');
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
    e.stop();
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
    var image_id   = $(this).id.match(/\d*$/)[0]; // eg. id="thumbnail_123"
    var image_hash = EOL.MediaCenter.image_hash[image_id];
    eol_update_image( image_hash.smart_image, image_hash );

    for(var i in EOL.popups) {
      EOL.popups[i].destroy();
    }
    e.stop();
  });
  //clicking on maps link in mediacenter
  '#tab_media_center #maps a').click(function(e) {
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
    e.stop();
  });
  $('div.content-article div.attribution .expand-text-attribution').click(function(e) {
    $$('div.content-article div.'+this.id.substring(4) +' div.credit').each(function(e){ e.appear(); });
    $(this.id).fade();
    e.stop();
  });
  //clicking map will show attributions
  $('img#map').click(function (e) {
    EOL.popup_links['map_attributions'].click();
  });
});
