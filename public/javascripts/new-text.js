$(document).ready(function() {
  // Submit new text:
  EOL.TextObjects.form.submit(function(e) {
    EOL.TextObjects.submit_text();
    return false;
  });
  // Preview:
  $('input#preview_text').click(function() {
    EOL.TextObjects.preview_text()
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
    // TODO - this is only set for editing text objects: data_object_id = EOL.TextObjects.form.attr('data-data_object_id');
    // error handling, just make sure there's a description
    textarea_val = $.trim($('textarea#data_object_description').val());
    if(textarea_val == '') {
      $('#missing_text_error').fadeIn().delay(2000).fadeOut();
      return false;
    }
    // TODO - this is for editing text object.  Make sure it does what it means to (which I don't know yet):
    if(data_object_id) {
      $('#text_wrapper_'+data_object_id).fadeOut(500, function() {$('#text_wrapper_'+data_object_id).remove();});
    }
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: EOL.TextObjects.form.action,
      type: 'POST',
      beforeSend: function() { },
      data: EOL.TextObjects.form.serialize()
    });
    EOL.TextObjects.disable_form();
  },

  preview_text: function() {
    EOL.TextObjects.remove_preview();
    $.ajax({
      url: $(this).attr('data-preview_url'),
      type: 'POST',
      data: EOL.TextObjects.form.serialize().replace("_method=put&","id="+EOL.TextObjects.form.attr('data-data_object_id')+"&") // TODO -this is hacky
    });
    EOL.TextObjects.disable_form();
    if(data_object_id == null) {
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
  }

};
