if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {};

EOL.TextObjects.Behaviors = {
  'li.add_text>a': function(e) {
    new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});
  },

  'div.add_text_button a:click': function(e) {
    EOL.popup_links['new_text_toc_text'].click(e);
  },

  'div.insert_text form.edit_data_object:submit': function(e) {
    EOL.TextObjects.submit_text(this,e);
    return false;
  },

  'div#insert_text_popup form:submit': function(e) {
    EOL.TextObjects.submit_text(this,e);
    return false;
  },

  'input#preview_text:click': function(e) {
    form = this.form;
    EOL.TextObjects.remove_preview();
    new Ajax.Request(this.readAttribute('data-preview_url'),
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'post',
                       parameters:Form.serialize(form).gsub("_method=put&","id="+form.readAttribute('data-data_object_id')+"&") //this is hacky
                     });
    EOL.TextObjects.disable_form(form);
    return false;
  },

  'div.edit_text a': function(e) {
    new EOL.PopupLink(this,{insert_after:this.up(2).id, additional_classes:'insert_text'});
  },

  'div.edit_text a:click':function(e) {
    //scroll browser down to the bottom of the text, near where the popup will appear
    Effect.ScrollTo(this.up(2).nextSiblings()[1].id);
  },

  'input#cancel_edit_text:click': function(e) {
    data_object_id = this.readAttribute('data-data_object_id');

    //remove preview text
    jQuery('div#text_wrapper_').fadeOut(1000, function() {this.remove();});

    //if the old text still exists on the page, just remove the edit div
    if($('text_wrapper_'+data_object_id) || $('original_toc_id').value != $('data_objects_toc_category_toc_id')[$('data_objects_toc_category_toc_id').selectedIndex].value) {
      jQuery("div#text_wrapper_"+data_object_id+"_popup").fadeOut(1000, function() {EOL.popups[this.id].destroy();});
    } else {
      form = $('edit_data_object_'+data_object_id);

      new Ajax.Request(form.action.gsub('/data_objects/','/data_objects/get/'),
                       {
                         asynchronous:true,
                         evalScripts:true,
                         method:'post',
                         parameters:Form.serialize(form)
                       });

      EOL.TextObjects.disable_form(form);
    }
  },

  'select#data_objects_toc_category_toc_id:change': function(e) {
    new Ajax.Request(this.readAttribute('data-change_toc_url'),
                       {
                         asynchronous:true,
                         evalScripts:true,
                         method:'post',
                         parameters:Form.serialize(this.form)
                       });
  }
};

EOL.TextObjects.submit_text = function(form, event) {
  data_object_id = form.readAttribute('data-data_object_id');
  //error handling, just make sure there a description
  if((data_object_id && $$('form#edit_data_object_'+data_object_id+' textarea')[0].value.strip() == '') || ($('form#new_data_object textarea') && $$('form#new_data_object textarea')[0].value.strip() == '')) {
    $('missing_text_error').show();
    Effect.Pulsate('missing_text_error');
    return false;
  }

  if(data_object_id) {
    jQuery('div#text_wrapper_'+data_object_id).fadeOut(1000, function() {$('text_wrapper_'+data_object_id).remove();});
  }

  EOL.TextObjects.remove_preview();

  new Ajax.Request(form.action,
                   {
                     asynchronous:true,
                     evalScripts:true,
                     method:'post',
                     parameters:Form.serialize(form)
                   });

  EOL.TextObjects.disable_form(form);

  return false;
};

EOL.TextObjects.disable_form = function(form) {
  form.disable();
  Effect.Appear('edit_text_spinner');
};

EOL.TextObjects.enable_form = function(form) {
  form.enable();
  Effect.Fade('edit_text_spinner');
};

EOL.TextObjects.insert_new_text = function(text) {
  EOL.popups["insert_text_popup"].hide();
  Element.insert("insert_text", { after: text });
  EOL.reload_behaviors();
  setTimeout(EOL.popups["insert_text_popup"].destroy(), 1000);
};

EOL.TextObjects.preview_text = function(text, data_object_id) {
  if(data_object_id == null) {
    //new text object preview

    //insert html
    Element.insert("insert_text", { after: text });

    //enable form
    EOL.TextObjects.enable_form($$('div#insert_text_popup form')[0]);
  } else {
    //existing text object preview

    //insert html
    Element.insert($('text_wrapper_'+data_object_id+'_popup').previousSiblings()[0].id, { after: text });

    //remove existing text object, so it won't confuse the user
    jQuery('div#text_wrapper_'+data_object_id).fadeOut(1000, function() {$('text_wrapper_'+data_object_id).remove();});

    //enable form
    EOL.TextObjects.enable_form($$('div#text_wrapper_'+data_object_id+'_popup form')[0]);
  }

  Effect.Appear('text_wrapper_');
};

EOL.TextObjects.remove_preview = function() {
  if($('text_wrapper_')) {
    jQuery('div#text_wrapper_').fadeOut(1000, function() {$('text_wrapper_').remove();});
  };
};

EOL.TextObjects.update_text = function(text, data_object_id, old_data_object_id) {
  Element.insert("text_wrapper_"+old_data_object_id+"_popup", { before: text });
  Effect.Appear("text_wrapper_"+data_object_id);
  jQuery("div#text_wrapper_"+old_data_object_id+"_popup").fadeOut(1000, function() {EOL.popups[this.id].destroy();});
  EOL.reload_behaviors();
};

EOL.TextObjects.update_add_links = function(url) {
  url = url.unescapeHTML();
  $$('a#new_text_toc_text')[0].href = url;
  $$('a#new_text_toc_button')[0].href = url;
  $$('a#new_text_content_button')[0].href = url;
};

EOL.TextObjects.change_toc = function(toc_label, add_new_url, new_text, toc_item_id) {
  //update header
  $$('div#center-page-content div.cpc-header h3')[0].update(toc_label);

  //update the links/buttons for adding new text
  EOL.TextObjects.update_add_links(add_new_url);

  //remove all text objects from page
  jQuery('div#center-page-content div.cpc-content div.text_object').each(function(i) {
    jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
  });

  //remove yellow warning box
  jQuery('div#center-page-content div.cpc-content div#unknown-text-warning-box_wrapper').each(function(i) {
    jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
  });

  //remove red warning box
  jQuery('div#center-page-content div.cpc-content div#untrusted-text-warning-box_wrapper').each(function(i) {
    jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
  });

  //add text from newly selected toc
  $$('div#center-page-content div.cpc-content')[0].insert(new_text);

  //update selected TOC
  $A(document.getElementsByClassName('active', $('toc'))).each(function(e) { e.className = 'toc_item'; });
  $('current_content').value = toc_item_id;

  Event.addBehavior.reload();

  $$('ul#toc a.toc_item[title='+toc_label+']')[0].className = 'active toc_item';
}

EOL.TextObjects.dialog_shown = false;