if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

EOL.Curation.quick_curate = function(element,vetted_id) {
  element.ancestors()[1].down('div.spinner img').appear();
  new Ajax.Request(element.href, {asynchronous:true, evalScripts:true, onComplete:function () {EOL.Curation.after_quick_curate(element,vetted_id);}.bind(element, vetted_id)});
};

EOL.Curation.after_quick_curate = function(element, vetted_id) {
  data_object_id = element.readAttribute('data-data_object_id');
  data_object_type = element.readAttribute('data-data_object_type');

  element.ancestors()[1].down('div.spinner img').disappear();
  element.ancestors()[1].down('div.trust_button').disappear();
  element.ancestors()[1].down('div.untrust_button').disappear();

  if(data_object_type == EOL.Curation.IMAGE_ID) {
    EOL.MediaCenter.image_hash[data_object_id].vetted_id = vetted_id;
    EOL.MediaCenter.image_hash[data_object_id].curated = true;
    eol_update_credit(EOL.MediaCenter.image_hash[data_object_id]);
    EOL.Curation.update_thumbnail_background(vetted_id, data_object_id);
  } else if(data_object_type == EOL.Curation.TEXT_ID) {
    EOL.Curation.update_text_background(data_object_id, vetted_id);
  }
};

EOL.Curation.update_thumbnail_background = function(vetted_id, data_object_id) {
  $('thumbnail_'+data_object_id).removeClassName('trusted-background-image');
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

EOL.Curation.update_text_background = function(data_object_id, vetted_id) {
  $('text_'+data_object_id).removeClassName('untrusted-background-image');
  $('text_'+data_object_id).removeClassName('unknown-background-image');
  $('text_'+data_object_id).removeClassName('trusted-background-image');
  if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('text_'+data_object_id).addClassName('untrusted-background-image');
  }
}

EOL.Curation.update_text_icons = function(data_object_id) {
  
};

EOL.Curation.after_curate = function(form,vetted_id) {
  id = form.readAttribute('data-data_object_id');
  type = form.readAttribute('data-data_object_type');
  form.enable();
  form.down('div.label img').fade();
  if(type == EOL.Curation.IMAGE_ID) {
    $('large-image-trust-button').disappear();
    $('large-image-untrust-button').disappear();
    EOL.MediaCenter.image_hash[id].curated = true;

    if ($('curate_trust_'+id).checked) {
      EOL.MediaCenter.image_hash[id].vetted_id = EOL.Curation.TRUSTED_ID;
      EOL.Curation.update_thumbnail_background(EOL.Curation.TRUSTED_ID, id);
    } else if ($('curate_untrust_'+id).checked) {
      EOL.MediaCenter.image_hash[id].vetted_id = EOL.Curation.UNTRUSTED_ID;
      EOL.Curation.update_thumbnail_background(EOL.Curation.UNTRUSTED_ID, id);
    }

    if($('curate_invisible_'+id).checked) {
      EOL.MediaCenter.image_hash[id].visibility_id = EOL.Curation.INVISIBLE_ID;
    } else if($('curate_visible_'+id).checked) {
      EOL.MediaCenter.image_hash[id].visibility_id = EOL.Curation.VISIBLE_ID;
    } else if($('curate_inappropriate_'+id).checked) {
      EOL.MediaCenter.image_hash[id].visibility_id = EOL.Curation.INAPPROPRIATE_ID;
    }

    eol_update_credit(EOL.MediaCenter.image_hash[id]);

    EOL.MediaCenter.update_thumbnail_icons($$('div#thumbnails a#thumbnail_'+id+' ul')[0]);
  } else if(type == EOL.Curation.TEXT_ID) {
    $$('div#text_buttons_'+id+' div.trust_button')[0].disappear();
    $$('div#text_buttons_'+id+' div.untrust_button')[0].disappear();
    EOL.Curation.update_text_background(id, vetted_id);
  }
};

EOL.Curation.Behaviors = {
  'div.visibility form div.option input:click, div.vetted form div.option input:click': function(e) {
    this.form.down('div.label img').appear();
    form = this.form
    vetted_id = this.readAttribute('data-vetted_id');
    new Ajax.Request(this.form.action,
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'put',
                       onComplete:function(){EOL.Curation.after_curate(form,vetted_id);}.bind(form,vetted_id),
                       parameters:Form.serialize(this.form)
                     });
    this.form.disable();
  },
  
  'div.trust_button a:click': function(e) {
    EOL.Curation.quick_curate(this,EOL.Curation.TRUSTED_ID);
    e.stop();
  },
  
  'div.untrust_button a:click': function(e) {
    EOL.Curation.quick_curate(this,EOL.Curation.UNTRUSTED_ID);
    e.stop();
  }
};

EOL.Curation.UNKNOWN_ID = 0;
EOL.Curation.UNTRUSTED_ID = 1;
EOL.Curation.TRUSTED_ID = 2;

EOL.Curation.TEXT_ID = 3;
EOL.Curation.IMAGE_ID = 5;

EOL.Curation.INVISIBLE_ID = 0;
EOL.Curation.VISIBLE_ID = 1;
EOL.Curation.INAPPROPRIATE_ID = 3;
