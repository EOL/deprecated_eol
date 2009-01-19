if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

EOL.Curation.quick_curate = function(url,vetted_id, data_object_id) {
  $$('#right-image-buttons #spinner img')[0].appear();
  new Ajax.Request(url, {asynchronous:true, evalScripts:true, onComplete:function () {EOL.Curation.after_quick_curate(vetted_id, data_object_id);}.bind(vetted_id, data_object_id)});
};

EOL.Curation.after_quick_curate = function(vetted_id, data_object_id) {
  $$('#right-image-buttons #spinner img')[0].disappear();
  $('large-image-trust-button').disappear();
  $('large-image-untrust-button').disappear();
  EOL.MediaCenter.image_hash[data_object_id].vetted_id = vetted_id;
  EOL.MediaCenter.image_hash[data_object_id].curated = true;
  eol_update_credit(EOL.MediaCenter.image_hash[data_object_id]);
  EOL.Curation.update_thumbnail_background(vetted_id, data_object_id);
};

EOL.Curation.update_thumbnail_background = function(vetted_id, data_object_id) {
  $('thumbnail_'+data_object_id).removeClassName('unknown-background-image');
  $('thumbnail_'+data_object_id).removeClassName('untrusted-background-image');
  if(vetted_id == EOL.Curation.TRUSTED_ID) {
    //no background
  } else if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('thumbnail_'+data_object_id).addClassName('untrusted-background-image');
  } else if (vetted_id == EOL.Curation.UNKNOWN_ID) {
    $('thumbnail_'+data_object_id).addClassName('unknown-background-image');
  }
};

EOL.Curation.after_curate = function(id) {
  console.log('after');
  $$('#large-image-curator-button-popup-link_popup_content .vetted form')[0].enable();
  $$('#large-image-curator-button-popup-link_popup_content .vetted form img')[0].fade();
  EOL.MediaCenter.image_hash[id].curated = true;
  if ($('curate_trust').checked) {
      EOL.MediaCenter.image_hash[id].vetted_id = EOL.Curation.TRUSTED_ID;
      EOL.Curation.update_thumbnail_background(EOL.Curation.TRUSTED_ID, id);
  } else if ($('curate_untrust').checked) {
      EOL.MediaCenter.image_hash[id].vetted_id = EOL.Curation.UNTRUSTED_ID;
      EOL.Curation.update_thumbnail_background(EOL.Curation.UNTRUSTED_ID, id);
  }
  eol_update_credit(EOL.MediaCenter.image_hash[id]);
}

EOL.Curation.Behaviors = {
  '#large-image-curator-button-popup-link_popup_content .visibility input:click': function(e) {
    $$('#large-image-curator-button-popup-link_popup_content .visibility form')[0].onsubmit();
    $$('#large-image-curator-button-popup-link_popup_content .visibility form img')[0].appear();
    $$('#large-image-curator-button-popup-link_popup_content .visibility form')[0].disable();
  },
  
  '#large-image-curator-button-popup-link_popup_content .vetted input:click': function(e) {
    $$('#large-image-curator-button-popup-link_popup_content .vetted form')[0].onsubmit();
    $$('#large-image-curator-button-popup-link_popup_content .vetted form img')[0].appear();
    $$('#large-image-curator-button-popup-link_popup_content .vetted form')[0].disable();
  },
  
  '#large-image-trust-button a:click': function(e) {
    EOL.Curation.quick_curate(this.href,EOL.Curation.TRUSTED_ID, this.readAttribute('data-data_object_id'));
    e.stop();
  },
  
  '#large-image-untrust-button a:click': function(e) {
    EOL.Curation.quick_curate(this.href,EOL.Curation.UNTRUSTED_ID, this.readAttribute('data-data_object_id'));
    e.stop();
  }
};

EOL.Curation.UNKNOWN_ID = 0;
EOL.Curation.UNTRUSTED_ID = 1;
EOL.Curation.TRUSTED_ID = 2;
