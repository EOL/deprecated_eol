/*
 * Unobtusive javascript, using Lowpro
 *
 * ... looking for the functions / global variables?  see misc.js (for cleaning up javascript, a bit)
 *
 * To reload these behaviors (for instance, after changing part of the DOM via Ajax), use: Event.addBehavior.reload();
 *
 * I'm not sure if there's an easy way to just reload a *subset* of these behaviors ... I would like to find out, though!
 *
 */ 
Event.addBehavior(
  $H({
  
  'a.static-popup-link': function() {
    new EOL.PopupLink(this, {is_static:true});
  },

  'a.popup-link': function() {
    new EOL.PopupLink(this);
  },

  // toggle image attribution on click
  'img#main-image:click': function() {
    EOL.popup_links['large-image-attribution-button-popup-link'].click(); // "click" the PopupLink
  },

  // slide in text comments (TEXT OBJECT - slides down, doesn't POPUP)
  'div.text_buttons div.comment_button a:click': function(e) {
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
  },

  'div.text_buttons div.curate_button a:click': function(e) {
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
  },

  // Fade in the taxa comments! (TAB)
  '#taxa-comments a:click': function(e) {
    if (!$('taxaCommentsWrap').childNodes[2]) {
      var loaded = true;// TODO - I think this is unused and should be deleted, but I am a chicken and won't do it myself (JRice)
      EOL.load_taxon_comments_tab();
    }
  },

  // when the image collection is loaded, this means we have images so ... check the location to see if #image-1234 is being requested
  'div#image-collection': function() {
    if (window.checked_for_image_hash_tag == null) {
      window.checked_for_image_hash_tag = true;
      var match = window.location.href.match(/image_id=(\d*)/);
      if (match != null) {
        var image_id = match[1];
        var image_hash = EOL.MediaCenter.image_hash[image_id];
        eol_update_image( image_hash.smart_image, image_hash );
      }
    }
  },

  // clicking on a thumbnail in the mediacenter
  'div#image-collection div#thumbnails a:click': function(e) {
    var image_id   = $(this).id.match(/\d*$/)[0]; // eg. id="thumbnail_123"
    var image_hash = EOL.MediaCenter.image_hash[image_id];
    eol_update_image( image_hash.smart_image, image_hash );

    for(var i in EOL.popups) {
      EOL.popups[i].destroy();
    }
    e.stop();
  },

  //clicking on maps link in mediacenter
    '#media-center #tab_media_center #maps a:click': function(e) {
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

          so.write("media-maps");

          map_div.style.display = 'block';
      }
      e.stop();
    },

  // Hides text-object attribution
  //
  // By default, we only authors, sources, copyrights, datasuppliers, and sourceurls
  //
  'div.content-article div.attribution div.credit': function() {
    var classes = $(this).classNames();
    
    if (!(
        classes.include('author') ||
        classes.include('source') ||
        classes.include('copyright') ||
        classes.include('datasupplier') ||
        classes.include('supplier') ||
        classes.include('sourceurl')
        ))
      $(this).hide();
  },
  
  'div.content-article div.attribution .expand-text-attribution:click': function(e) {
    $$('div.content-article div.'+this.id.substring(4) +' div.credit').each(function(e){ e.appear(); });
    $(this.id).fade();
    e.stop();
  },

  //clicking map will show attributions
  'img#map:click': function (e) {
    EOL.popup_links['map_attributions'].click();
  },

  'a.external_link:click':function(e) {
    e.stop();

    show_popup = false;
    if (EOL.USE_EXTERNAL_LINK_POPUPS) {
      var agree = confirm("The link you have clicked will take you to an external website.  Are you sure you wish to proceed?");
    } else {
      var agree = true;
    }
    if (agree) {
      window.open('/external_link?url=' + escape(this.href));
    } else {
      return false ;
    }
  },

  'a.return_to:click':function() {
    EOL.addReturnTo(this);
  }

  }).merge(EOL.Tagging.Behaviors).merge(EOL.Search.Behaviors).merge(EOL.Curation.Behaviors).merge(EOL.MediaCenter.Behaviors).merge(EOL.TextObjects.Behaviors).merge(EOL.Rating.Behaviors).merge(EOL.Comments.Behaviors).merge(EOL.Admin.Behaviors).toObject()
);

// Let's also register some Ajax callbacks
Ajax.Responders.register({
  onCreate: EOL.Ajax.start,
  onComplete: EOL.Ajax.finish
});

// We're still using some jQuery ... until we get rid of it, let's register the same callbacks for jQuery
$j().ajaxStart( EOL.Ajax.start );
$j().ajaxComplete( EOL.Ajax.finish );

// Things to do once all other behaviours have been attached:
document.observe("dom:loaded", function() {
  // Make our links show up
  $$('a.popup-link,a.slide-in-link').invoke('show');
});

var RecaptchaOptions = { theme : 'clean'};
