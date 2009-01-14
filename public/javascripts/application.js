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
  '.text-comment-button a:click': function(e) {
    EOL.slide_in(this);
    e.stop();
  },

  // Fade in the taxa comments! (TAB)
  '#taxa-comments a:click': function(e) {
    if (!$('taxaCommentsWrap').childNodes[2]) {
      var loaded = true;
      new Ajax.Updater('taxaCommentsWrap', '/comments/',
                       {asynchronous:true, evalScripts:true, method:'get',
                        parameters: { body_div_name: 'taxaCommentsWrap', taxon_concept_id: $('current_taxon_id').value },
                        onLoading:function() {
                          // onloading sometimes runs twice, and second time moves comment div down. 
                          // A bit hackish way to fix it is to run onloading function only when 
                          // taxaCommentsWrap is hidden
                          if ($('taxaCommentsWrap').style.display != 'none'){
                            EOL.Effect.appear('loading-comments');
                            $('taxaCommentsWrap').style.display = 'none';
                          }
                        },
                        onSuccess:function() {EOL.Effect.disappear('loading-comments');EOL.Effect.appear('taxaCommentsWrap');}
                       });
    }
  },

  // clicking on a thumbnail in the mediacenter
  'div#image-collection div#thumbnails a:click': function(e) {
    for(var i in EOL.popups) {
      EOL.popups[i].destroy();
    }
  },

  //clicking on maps link in mediacenter
  '#media-center #tab_media_center #maps a:click': function(e) {
    var map_div = $$('#media-maps div')[0];
    if (map_div.style.display == 'none') {
      var map_url = $('map-url').innerHTML
      var map_title = $('map-title').innerHTML;
      var map_id = map_div.identify().split("_")[2];
      map_div.innerHTML = '<img src="' + map_url + '" alt="' + map_title + '" title="' + map_title + '" />';
      map_div.style.display='block';
      eol_log_data_objects_for_taxon_concept( $('taxon_concept_to_log').value, $('map-data-object-id').value ); // we should have an EOL.function() that returns the taxon ID of the current page (if present) ...
    }
    e.stop();
  },

  // hide some of the text-object attribution ... should be able to expand to see these again, tho
  //
  // by default, we show the author(s), source(s), and right(s) but not anything else
  //
  'div.content-article div.attribution div.credit': function() {
    var classes = $(this).classNames();
    if (!classes.include('author') && !classes.include('source') && !classes.include('copyright') && !classes.include('datasupplier') && !classes.include('supplier'))
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
  }

  }).merge(EOL.Tagging.Behaviors).merge(EOL.Search.Behaviors).merge(EOL.Curation.Behaviors).toObject()
);

// Let's also register some Ajax callbacks
Ajax.Responders.register({
  onCreate: EOL.Ajax.start,
  onComplete: EOL.Ajax.finish
});

// We're still using some jQuery ... until we get rid of it, let's register the same callbacks for jQuery
$j().ajaxStart( EOL.Ajax.start );
$j().ajaxComplete( EOL.Ajax.finish );

// Make our links show up once behaviours have been attached:
document.observe("dom:loaded", function() {
  $$('a.popup-link,a.slide-in-link').invoke('show');
});
