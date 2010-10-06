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
      EOL.TextObjects.preview_text(this);
      return false;
    });
    // Close the add-text window:
    $('#insert_text_popup a.close-button').click(function() {
      $('#insert_text_popup').slideUp();
      EOL.TextObjects.remove_preview();
    });
    // Cancel adding text:
    $('input#cancel_edit_text').click(function() {
      EOL.TextObjects.cancel_edit($(this).attr('data-data_object_id')); // TODO - why do we need an id?
    });
    // Update the text area when the user changes the TOC Item category:
    $('select#data_objects_toc_category_toc_id').change(function() {
      $.ajax({
        url: $(this).attr('data-change_toc_url'),
        success: function(response) {
          // remove all text objects from page.  It would be better to do this on success, but timing is an issue.
          $('.text_object').slideUp().delay(500).remove();
          // remove warning boxes
          $('div.cpc-content div#unknown-text-warning-box_wrapper').fadeOut().delay(500).remove();
          $('div.cpc-content div#untrusted-text-warning-box_wrapper').fadeOut().delay(500).remove();
          // Put in the new content:
          $('#insert_text_popup').before(response);
        },
        data: EOL.TextObjects.form().serialize()
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

  data_object_id: function() {
    return EOL.TextObjects.form().attr('data-data_object_id');
  },

  submit_text: function() {
    if (EOL.TextObjects.show_missing_text_error_if_empty()) return false;
    var id = EOL.TextObjects.data_object_id();
    if(id) {
      $('#text_wrapper_'+id).fadeOut().delay(500).remove();
    }
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: EOL.TextObjects.form().attr('action'),
      type: 'POST',
      beforeSend: function() { EOL.TextObjects.disable_form(); },
      success: function(response) {
        $('#insert_text_popup').before(response);
        EOL.TextObjects.form().find('*').not(':button, :submit, :reset, :hidden').val('').removeAttr('checked').removeAttr('selected');
      },
      complete: function() { $('#insert_text_popup').slideUp(); }, // TODO - This needs to reset the form and possibly change ids on it.
      error: function() { alert("Sorry, there was an error submitting your text.");},
      data: EOL.TextObjects.form().serialize()
    });
  },

  preview_text: function(button) {
    if (EOL.TextObjects.show_missing_text_error_if_empty()) return false;
    EOL.TextObjects.remove_preview();
    // TODO - the data is hacky ... why isn't it this way in the data-preview_url?
    $.ajax({
      url: $(button).attr('data-preview_url'),
      type: 'POST',
      beforeSend: function() { EOL.TextObjects.disable_form(); },
      success: function(response) {
        $('#insert_text_popup').before(response);
        $('a#edit_text_').remove(); // We don't want them editing the preview text!
        $('#text_wrapper_').slideDown();
      },
      complete: function() { EOL.TextObjects.enable_form(); },
      error: function() { alert("Sorry, there was an error previewing your text.");},
      data: EOL.TextObjects.form().serialize().replace("_method=put&","id="+EOL.TextObjects.data_object_id()+"&")
    });
  },

  remove_preview: function() {
    if($('#text_wrapper_')) {
      $('div#text_wrapper_').slideUp().delay(500).remove();
    };
  },

  cancel_edit: function(data_object_id) {
    data_object_id = EOL.TextObjects.data_object_id();
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

  // This is only called from RJS:
  update_text: function(text, data_object_id, old_data_object_id) {
    $("#text_wrapper_"+old_data_object_id+"_popup").before(text);
    $("text_wrapper_"+data_object_id).fadeIn();
    $("div#text_wrapper_"+old_data_object_id+"_popup").fadeOut(1000, function() {
      $("div#text_wrapper_"+old_data_object_id+"_popup").remove();
    });
    // TODO - reload behaviors... the edit link needs to be activated.
  },

  // This is only called server-side, but in two different places, so I'm keeping it here:
  update_add_links: function(url) {
    $('#new_text_toc_text').attr('href', url);
    $('#new_text_toc_button').attr('href', url);
    $('#new_text_content_button').attr('href', url);
  },

});

$(document).ready(function() {
  EOL.TextObjects.init_new_text_behaviors();
});

