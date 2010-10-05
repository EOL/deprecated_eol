// Note that this relies on EOL.TextObjects already existing for a reason; many methods this needs are there.
$.extend(EOL.TextObjects, {

  init_new_text_behaviors: function() {
    // Submit new text:
    EOL.TextObjects.form().submit(function(e) {
      EOL.TextObjects.submit_text();
      return false;
    });
    // Preview:
    $('input#preview_text').click(function() {
      EOL.TextObjects.preview_text(this)
      return false;
    });
    // Close the add-text window:
    $('#insert_text_popup a.close-button').click(function() {
      $('#insert_text_popup').slideUp();
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
  },

  show_missing_text_error_if_empty: function() {
    // error handling, just make sure there's a description
    textarea_val = $.trim($('textarea#data_object_description').val());
    if(textarea_val == '') {
      $('#missing_text_error').fadeIn().delay(2000).fadeOut();
      return true;
    } else {
      return false;
    }
  },

  submit_text: function() {
    if (EOL.TextObjects.show_missing_text_error_if_empty()) return false;
    // TODO - this is only set for editing text objects: data_object_id = EOL.TextObjects.form().attr('data-data_object_id');
    if(data_object_id) {
      // TODO - this is for editing text object.  Make sure it does what it means to (which I don't know yet):
      $('#text_wrapper_'+data_object_id).fadeOut(500).delay(600).remove();
    }
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: EOL.TextObjects.form().action,
      type: 'POST',
      beforeSend: function() { EOL.TextObjects.disable_form(); },
      data: EOL.TextObjects.form().serialize()
    });
  },

  preview_text: function(link) {
    if (EOL.TextObjects.show_missing_text_error_if_empty()) return false;
    EOL.TextObjects.remove_preview();
    // TODO - the data is hacky ... why isn't it this way in the data-preview_url?
    $.ajax({
      url: $(link).attr('data-preview_url'),
      type: 'POST',
      beforeSend: function() { EOL.TextObjects.disable_form(); },
      data: EOL.TextObjects.form().serialize().replace("_method=put&","id="+EOL.TextObjects.form().attr('data-data_object_id')+"&")
    });
    // TODO - if(data_object_id == null)
    if(false) {
      $("#insert_text").append(text);
      EOL.TextObjects.enable_form();
    } else {
      $('#text_wrapper_'+data_object_id+'_popup').before(text);
      // remove existing text object, so it won't confuse the user
      $('div#text_wrapper_'+data_object_id).fadeOut(1000, function() {$('#text_wrapper_'+data_object_id).remove();});
      EOL.TextObjects.enable_form();
    }
    $('#text_wrapper_').fadeIn();
  },

  remove_preview: function() {
    if($('#text_wrapper_')) {
      $('div#text_wrapper_').fadeOut(1000, function() {$('#text_wrapper_').remove();});
    };
  },

  cancel_edit: function(data_object_id) {
    EOL.TextObjects.remove_preview();
    // if the old text still exists on the page, just remove the edit div
    // TODO - does this work?  Can it be said more elegantly?
    if($('#text_wrapper_'+data_object_id).length > 0 || $('#original_toc_id').val() != $('#data_objects_toc_category_toc_id').val()) {
      $('#insert_text_popup').slideUp();
      $("div#text_wrapper_"+data_object_id+"_popup").fadeOut(1000).delay(1100).destroy();
    } else {
      $.ajax({
        url: $('#edit_data_object_'+data_object_id).attr('action').replace('/data_objects/','/data_objects/get/'),
        type: 'POST',
        data: EOL.TextObjects.form.serialize()
      });
      EOL.TextObjects.disable_form();
    }
  },

  disable_form: function() {
    EOL.TextObjects.form().find('input[type=submit], input[type=button]').attr('disabled', 'disabled');
    $('#edit_text_spinner').fadeIn();
  },

  enable_form: function() {
    EOL.TextObjects.form().find('input[type=submit], input[type=button]').attr('disabled', '');
    $('#edit_text_spinner').fadeOut();
  },

  insert_new_text: function(text) {
    $("#insert_text_popup").slideUp().remove();
    $(".cpc-content").append(text);
    EOL.reload_behaviors(); // TODO
  },

  update_text: function(text, data_object_id, old_data_object_id) {
    $("#text_wrapper_"+old_data_object_id+"_popup").before(text);
    $("text_wrapper_"+data_object_id).fadeIn();
    $("div#text_wrapper_"+old_data_object_id+"_popup").fadeOut(1000, function() {
      $("div#text_wrapper_"+old_data_object_id+"_popup").remove();
    });
    // TODO - reload behaviors?
  },

  update_add_links: function(url) {
    url = url.unescapeHTML(); // TODO - works?
    $('#new_text_toc_text').attr('href', url);
    $('#new_text_toc_button').attr('href', url);
    $('#new_text_content_button').attr('href', url);
  },

  change_toc: function(toc_label, add_new_url, new_text, toc_item_id) {
    // update header
    $('div#center-page-content div.cpc-header h3').html(toc_label);
    // update the links/buttons for adding new text
    EOL.TextObjects.update_add_links(add_new_url);
    // remove all text objects from page
    $('div#center-page-content div.cpc-content div.text_object').fadeOut('slow', function() {$(this).remove();});
    // remove yellow warning box
    $('div#center-page-content div.cpc-content div#unknown-text-warning-box_wrapper').fadeOut('slow', function() {
      $(this).remove();
    });
    // remove red warning box
    $('div#center-page-content div.cpc-content div#untrusted-text-warning-box_wrapper').fadeOut('slow', function() {
      $(this).remove();
    });
    // add text from newly selected toc
    $('div#center-page-content div.cpc-content').append(new_text);
    // TODO - This seems like it would be a handy function to have available (if it's not already):
    // update selected TOC
    $('#toc.active').removeClass('active');
    $('#current_content').val(toc_item_id);
    $('ul#toc a.toc_item[title='+toc_label+']').addClass('active');
    // TODO - reload behaviors?
  }

});

$(document).ready(function() {
  EOL.TextObjects.init_new_text_behaviors();
});

