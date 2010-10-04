$(document).ready(function() {
  // Allow the user to show extra attribution information for text
  $('.expand-text-attribution').click(function(e) {
    // TODO - I don't think we need the each() here... I think it will work withgout it, but cannot test now
    $('div.' + $(this).attr('id').substring(4) +' div.credit').each(function(){ $(this).fadeIn(); });
    $(this).fadeOut();
    return false;
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

  // Open the add-text user interface
  // TODO - This should scroll to a useful position after adding the box.
  $('div.edit_text a, li.add_text>a, div.add_text_button a').click(function(e) {
    EOL.TextObjects.toggle_dialog(e,EOL.popup_links['new_text_toc_text'],this);
  });
  // Submit new text:
  $('div#insert_text_popup form, div.insert_text form.edit_data_object').submit(function(e) {
    EOL.TextObjects.submit_text();
    return false;
  });
  // Preview:
  $('input#preview_text').click(function() {
    form = $('div.popup.insert_text');
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: $(this).attr('data-preview_url'),
      type: 'POST',
      data: form.serialize().replace("_method=put&","id="+form.attr('data-data_object_id')+"&") // TODO -this is hacky
    });
    EOL.TextObjects.disable_form();
    return false;
  });
  // Cancel adding text:
  $('input#cancel_edit_text').click(function() {
    EOL.TextObjects.cancel_edit($(this).attr('data-data_object_id')); // TODO - why do we need an id?
  });
  // Update the text area when the user changes the category:
  $('select#data_objects_toc_category_toc_id').change(function() {
    $.ajax({
      url: $(this).attr('data-change_toc_url'),
      type: 'POST', // TODO - why?
      data: $('div.popup.insert_text').serialize() // TODO -wrong
    });
  });
  // Give the user another reference field
  $('div#add_user_text_references input#add_more_user_text_reference').click(function(e) {
    $('#add_user_text_references_input').append('<textarea rows="3" name="references[]" id="references[]" cols="33"/>');
  });
});

if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {

  submit_text: function() {
    form = $('div.popup.insert_text');
    data_object_id = form.attr('data-data_object_id');
    // error handling, just make sure there's a description
    textarea_val = form.find('textarea').val().strip();
    if((data_object_id && textarea_val == '') ||
       (textarea_val.length > 0 && textarea_val == '')) {
      $('#missing_text_error').fadeIn().delay(2000).fadeOut();
      return false;
    }
    if(data_object_id) {
      $('#text_wrapper_'+data_object_id).fadeOut(500, function() {$('#text_wrapper_'+data_object_id).remove();});
    }
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: form.action,
      type: 'POST',
      data: $(form).serialize()
    });
    EOL.TextObjects.disable_form();
    return false;
  },

  disable_form: function() {
    form = $('div.popup.insert_text');
    form.find('input[type=submit], input[type=button]').attr('disabled', 'disabled');
    $('#edit_text_spinner').fadeIn();
  },

  enable_form: function() {
    form = $('div.popup.insert_text');
    form.find('input[type=submit], input[type=button]').attr('disabled', '');
    $('#edit_text_spinner').fadeOut();
  },

  insert_new_text: function(text) {
    EOL.popups["insert_text_popup"].hide();
    Element.insert("insert_text", { after: text });
    EOL.reload_behaviors();
    setTimeout(EOL.popups["insert_text_popup"].destroy(), 1000);
  },

  preview_text: function(text, data_object_id) {
    if(data_object_id == null) {
      // new text object preview

      // insert html
      Element.insert("insert_text", { after: text });

      // enable form
      EOL.TextObjects.enable_form();
    } else {
      // existing text object preview

      // insert html
      Element.insert($('#text_wrapper_'+data_object_id+'_popup').previousSiblings()[0].id, { after: text });

      // remove existing text object, so it won't confuse the user
      jQuery('div#text_wrapper_'+data_object_id).fadeOut(1000, function() {$('#text_wrapper_'+data_object_id).remove();});

      // enable form
      EOL.TextObjects.enable_form();
    }

    Effect.Appear('text_wrapper_');
  },

  remove_preview: function() {
    if($('#text_wrapper_')) {
      jQuery('div#text_wrapper_').fadeOut(1000, function() {$('#text_wrapper_').remove();});
    };
  },

  update_text: function(text, data_object_id, old_data_object_id) {
    Element.insert("text_wrapper_"+old_data_object_id+"_popup", { before: text });
    Effect.Appear("text_wrapper_"+data_object_id);
    jQuery("div#text_wrapper_"+old_data_object_id+"_popup").fadeOut(1000, function() {EOL.popups[this.id].destroy();});
    EOL.reload_behaviors();
               },

  update_add_links: function(url) {
    url = url.unescapeHTML();
    $('#new_text_toc_text').href = url;
    $('#new_text_toc_button').href = url;
    if($('#new_text_content_button')) {
      $('#new_text_content_button').href = url;
    }
  },

  change_toc: function(toc_label, add_new_url, new_text, toc_item_id) {
    // update header
    $('div#center-page-content div.cpc-header h3').html(toc_label);

    // update the links/buttons for adding new text
    EOL.TextObjects.update_add_links(add_new_url);

    // remove all text objects from page
    jQuery('div#center-page-content div.cpc-content div.text_object').each(function(i) {
      jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
    });

    // remove yellow warning box
    jQuery('div#center-page-content div.cpc-content div#unknown-text-warning-box_wrapper').each(function(i) {
      jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
    });

    // remove red warning box
    jQuery('div#center-page-content div.cpc-content div#untrusted-text-warning-box_wrapper').each(function(i) {
      jQuery('#'+this.id).fadeOut("normal", function() {$(this.id).remove();}.bind(this));
    });

    // add text from newly selected toc
    $('div#center-page-content div.cpc-content').append(new_text);

    // update selected TOC
    $A(document.getElementsByClassName('active', $('#toc'))).each(function(e) { e.className = 'toc_item'; });
    $('#current_content').val(toc_item_id);

    Event.addBehavior.reload();

    if($('ul#toc a.toc_item[title='+toc_label+']').length > 0) {
      $('ul#toc a.toc_item[title='+toc_label+']').addClass('active toc_item');
    }
  },

  // OLD: new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});

  toggle_dialog: function(e,popup,el) {
    // hide old warnings
    $('.multi_new_text_error').each(function(el) {el.hide();});

    if($('div.insert_text:visible')) {
      // show warning because add/edit popup is already being displayed
      if(el.id == "new_text_content_button") {
        // button on the top of the content area
        $('div.cpc-header div.multi_new_text_error').show();
        $('div.cpc-header div.multi_new_text_error').pulsate(); // TODO 
      } else if(el.id == "new_text_toc_text" || el.id == "new_text_toc_button") {
        // links in the toc
        $('ul#toc li.multi_new_text_error')[0].show();
        $('ul#toc li.multi_new_text_error')[0].pulsate();
      } else if(el.id.indexOf('edit_text_') == 0) {
        // edit links
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
              EOL.TextObjects.cancel_edit($(this).find('form').attr('data-data_object_id'));
            }
          } else {
            this.show();
          }
        };
        if(popup.href.indexOf('toc_id=none') != -1) {
          // if currently selected toc doesn't allow user submitted text
          new Ajax.Request($('#new_text_toc_text').readAttribute('data-change_toc_url'),
                         {
                           asynchronous:true,
                           evalScripts:true,
                           method:'post'
                         });
        }
        popup.popup.toggle();
      }
    }
    return false;
  },

  cancel_edit: function(data_object_id) {
    // remove preview text
    EOL.TextObjects.remove_preview();
    // if the old text still exists on the page, just remove the edit div
    // TODO - does this work?  Can it be said more elegantly?
    if($('#text_wrapper_'+data_object_id) || $('#original_toc_id').val() != $('#data_objects_toc_category_toc_id')[$('#data_objects_toc_category_toc_id').selectedIndex].val()) {
      $("div#text_wrapper_"+data_object_id+"_popup").fadeOut(1000, function() {EOL.popups[this.id].destroy();});
    } else {
      $.ajax({
        url: $('#edit_data_object_'+data_object_id).attr('action').replace('/data_objects/','/data_objects/get/'),
        type: 'POST',
        data: $(form).serialize()
      });
      EOL.TextObjects.disable_form();
    }
  }

};
