function pulsate_error(el) {
  $(el).fadeIn('fast').fadeOut('fast').fadeIn('fast').fadeOut('fast').fadeIn('fast').delay(4000).fadeOut(2000);
}

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
  $('div.edit_text a, li.add_text>a, div.add_text_button a').click(function() {
    EOL.TextObjects.open_new_text_dialog();
    return false;
  });
});

if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {

  open_new_text_dialog: function(popup_id) {
    if($('#insert_text_popup:visible').length > 0) {
      // show warning because add/edit popup is already being displayed
      pulsate_error($('.multi_new_text_error'));
    } else {
      $.ajax({
        url: $('#new_text_toc_text').attr('href'),
        success: function(response) {$('#insert_text_popup .popup-content').html(response);},
        error: function() {$('#insert_text_popup .popup-content').html("<p>Sorry, there was an error.</p>");},
        complete: function() { $('#insert_text_popup').slideDown(); }
      });
      if($('#new_text_toc_text').attr('href').indexOf('toc_id=none') != -1) {
        // if currently selected toc doesn't allow user submitted text
        $.ajax({url:$('#new_text_toc_text').attr('data-change_toc_url'), type:'post'});
      }
    }
  },

  disable_form: function() {
    form = $('div.popup.insert_text'); // TODO -wrong
    form.find('input[type=submit], input[type=button]').attr('disabled', 'disabled');
    $('#edit_text_spinner').fadeIn();
  },

  enable_form: function() {
    form = $('div.popup.insert_text'); // TODO -wrong
    form.find('input[type=submit], input[type=button]').attr('disabled', '');
    $('#edit_text_spinner').fadeOut();
  },

  insert_new_text: function(text) {
    $("#insert_text_popup").slideUp().remove();
    $(".cpc-content").append(text);
    EOL.reload_behaviors(); // TODO
  },

  preview_text: function(text, data_object_id) {
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
        data: $(form).serialize()
      });
      EOL.TextObjects.disable_form();
    }
  }

};
