$(document).ready(function() {
  // Submit new text:
  $('form#insert_new_text, form.edit_data_object').submit(function(e) {
    EOL.TextObjects.submit_text();
    return false;
  });
  // Preview:
  $('input#preview_text').click(function() {
    form = $('div.popup.insert_text');  // TODO - wrong selector.
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
    form = $('form#insert_new_text');
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
  }

};
