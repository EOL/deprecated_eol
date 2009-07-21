if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

EOL.Curation.post_curate_text = function(data_object_id, visibility_id, vetted_id) {
  try {
    $$('div#text_buttons_'+data_object_id+' div.trust_button')[0].disappear();
    $$('div#text_buttons_'+data_object_id+' div.untrust_button')[0].disappear();
  } catch(err) {
    //no quick curate buttons
  }
  EOL.Curation.update_text_background(data_object_id, vetted_id);
  EOL.Curation.update_text_icons(data_object_id, visibility_id);
};

EOL.Curation.post_curate_image = function(data_object_id, visibility_id, vetted_id) {
  try {
    $('large-image-trust-button').disappear();
    $('large-image-untrust-button').disappear();
  } catch (err) {
    //no quick curate buttons
  }

  EOL.MediaCenter.image_hash[data_object_id].vetted_id = vetted_id;
  EOL.MediaCenter.image_hash[data_object_id].visibility_id = visibility_id;
  EOL.MediaCenter.image_hash[data_object_id].curated = true;
  
  eol_update_credit(EOL.MediaCenter.image_hash[data_object_id]);
  EOL.Curation.update_thumbnail_background(vetted_id, data_object_id);
  EOL.MediaCenter.update_thumbnail_icons($$('div#thumbnails a#thumbnail_'+data_object_id+' ul')[0]);
};

EOL.Curation.quick_curate = function(element) {
  element.ancestors()[1].down('div.spinner img').appear();
  new Ajax.Request(element.href,
                    {
                      asynchronous:true,
                      evalScripts:true,
                      onComplete:function(){
                        element.ancestors()[1].down('div.spinner img').disappear();
                      }.bind(element)
                    }
                  );
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

EOL.Curation.update_text_icons = function(data_object_id, visibility_id) {
  $$('div#text_buttons_'+data_object_id+' ul li.invisible_icon')[0].hide();
  $$('div#text_buttons_'+data_object_id+' ul li.inappropriate_icon')[0].hide();

  if(visibility_id == EOL.Curation.INVISIBLE_ID) {
    $$('div#text_buttons_'+data_object_id+' ul li.invisible_icon')[0].show();
  } else if(visibility_id == EOL.Curation.INAPPROPRIATE_ID) {
    $$('div#text_buttons_'+data_object_id+' ul li.inappropriate_icon')[0].show();
  }
};

EOL.Curation.Behaviors = {
  'form.curation input[type="submit"]:click': function(e) {
    e.stop();
    var form = $(this.form);
    form.down('div.processing').appear();
    new Ajax.Request(form.action,
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'put',
                       onComplete:function() {
                         form.enable();
                         form.down('div.processing').fade();
                       }.bind(form),
                       parameters:Form.serialize(form)
                     });
    form.disable();
  },
  
  'div.trust_button a:click, div.untrust_button a:click': function(e) {
    EOL.Curation.quick_curate(this);
    e.stop();
  },
  
  'input#curator_request': function(e) {
    $(this).observe("click", function() {
      EOL.Effect.toggle_with_effect("curator_request_options");  
    });
  },

  'div.vetted div.untrusted div input[type="radio"]:click': function(e) {
    this.up(2).down('div.reason').appear();
  },

  'div.vetted div.trusted input[type="radio"]:click': function(e) {
    this.up(2).down('div.reason').fade();
  },

  'div#large-image-curator-button-popup-link_popup_content input.cancel-button:click': function(e) {
    $('large-image-curator-button-popup-link_popup').disappear();
  },

  'div.text_curation_close a.close-button:click': function(e) {
    this.up(2).fade();
  },

  'div.text-slidebox-container form.curation input.cancel-button:click':function(e) {
    this.up(4).fade();
  }
};