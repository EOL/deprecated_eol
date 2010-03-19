if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {};

EOL.TextObjects.Behaviors = {
  'li.add_text>a': function(e) {
    new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});
    Event.stopObserving(this,'click');
  },
  
  'li.add_text>a:click, div.add_text_button a:click': function(e) {
    EOL.TextObjects.toggle_dialog(e,EOL.popup_links['new_text_toc_text'],this);
  },

  'div.edit_text a': function(e) {
    new EOL.PopupLink(this,{insert_after:this.up(2).id, additional_classes:'insert_text'});
    Event.stopObserving(this,'click');
  },

  'div.edit_text a:click': function(e) {
    //scroll browser down to the bottom of the text, near where the popup will appear
    //Effect.ScrollTo(this.up(2).nextSiblings()[1].id);
    EOL.TextObjects.toggle_dialog(e,EOL.popup_links[this.id],this);
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

  'input#cancel_edit_text:click': function(e) {
    EOL.TextObjects.cancel_edit(this.readAttribute('data-data_object_id'));
  },

  'select#data_objects_toc_category_toc_id:change': function(e) {
    new Ajax.Request(this.readAttribute('data-change_toc_url'),
                       {
                         asynchronous:true,
                         evalScripts:true,
                         method:'post',
                         parameters:Form.serialize(this.form)
                       });
  },

  'div#add_user_text_references input#add_more_user_text_reference:click': function(e) {
    $('add_user_text_references_input').insert({bottom: '<textarea rows="3" name="references[]" id="references[]" cols="33"/>'})
  }
};

EOL.TextObjects.submit_text = function(form, event) {
  data_object_id = form.readAttribute('data-data_object_id');
  //error handling, just make sure there a description
  if((data_object_id && $$('form#edit_data_object_'+data_object_id+' textarea')[0].value.strip() == '') || ($$('form#new_data_object textarea').length > 0 && $$('form#new_data_object textarea')[0].value.strip() == '')) {
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
  
  // //in case we want to reload the TOC Category after submission, but it caused other javascript errors
  var selected_index = $('data_objects_toc_category_toc_id').selectedIndex;
  var toc_id = $('data_objects_toc_category_toc_id')[selected_index].value;
  var taxon_concept_id = $j("input[name=taxon_concept_id]").val();
  // window.location.href = '/pages/'+taxon_concept_id+'?category_id='+toc_id;
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
  $('new_text_toc_text').href = url;
  $('new_text_toc_button').href = url;
  if($('new_text_content_button')) {
    $('new_text_content_button').href = url;
  }
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

  if($$('ul#toc a.toc_item[title='+toc_label+']').length > 0) {
    $$('ul#toc a.toc_item[title='+toc_label+']')[0].className = 'active toc_item';
  }
};

EOL.TextObjects.toggle_dialog = function(e,popup,el) {
  if(e) {
    e.stop();
  }

  //hide old warnings
  $$('.multi_new_text_error').each(function(el) {el.hide();});

  if($$('div.insert_text')[0] && $$('div.insert_text')[0].style.display == '') {
    //show warning because add/edit popup is already being displayed
    if(el.id == "new_text_content_button") {
      //button on the top of the content area
      $$('div.cpc-header div.multi_new_text_error')[0].show();
      $$('div.cpc-header div.multi_new_text_error')[0].pulsate();
    } else if(el.id == "new_text_toc_text" || el.id == "new_text_toc_button") {
      //links in the toc
      $$('ul#toc li.multi_new_text_error')[0].show();
      $$('ul#toc li.multi_new_text_error')[0].pulsate();
    } else if(el.id.indexOf('edit_text_') == 0) {
      //edit links
      el.up(2).down('div.multi_new_text_error').show();
      el.up(2).down('div.multi_new_text_error').pulsate();
    }
  } else {
    popup.href = popup.link.href; // reset, just incase the href has been changed
    if (popup.popup == null || popup.popup.element == null) {
      popup.popup = new Popup(popup.href, popup.link, popup.options);
      popup.popup.toggle = function() {
        if (this.element.visible()) {
          if(this.id == 'insert_text_popup') {
            EOL.TextObjects.remove_preview();
            jQuery('#'+this.id).fadeOut("normal", function() {this.destroy();}.bind(this));
          } else {
            EOL.TextObjects.cancel_edit(this.element.down('form').readAttribute('data-data_object_id'));
          }
        } else {
          this.show();
        }
      };
      if(popup.href.indexOf('toc_id=none') != -1) {
        //if currently selected toc doesn't allow user submitted text
        new Ajax.Request($('new_text_toc_text').readAttribute('data-change_toc_url'),
                       {
                         asynchronous:true,
                         evalScripts:true,
                         method:'post'
                       });
      }
      popup.popup.toggle();
    }
  }
};

EOL.TextObjects.cancel_edit = function(data_object_id) {
  //remove preview text
  EOL.TextObjects.remove_preview();

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
};