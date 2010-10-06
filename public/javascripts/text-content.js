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
  $('li.add_text>a, div.add_text_button a').click(function() {
    EOL.TextObjects.open_new_text_dialog($(this).attr('href'));
    return false;
  });

  // Open edit-text user interface:
  EOL.TextObjects.init_edit_links();
});

if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {

  form: function() {
    return $('form#new_data_object, form.edit_data_object');
  },

  // This will either show an existing dialog, create a new one, or show an error if it's already open:
  open_new_text_dialog: function(link_href) {
    if($('#insert_text_popup:visible').length > 0) {
      // show warning because add/edit popup is already being displayed
      pulsate_error($('.multi_new_text_error'));
    } else {
      // If we already have a form and this is NOT an edit:
      if (EOL.TextObjects.form().length > 0 && link_href.indexOf('edit') == 0) {
        EOL.TextObjects.show_new_text_dialog();
      // Otherwise, we need to (re-)create the form:
      } else {
        EOL.TextObjects.create_new_text_dialog(link_href);
      }
    }
  },

  init_edit_links: function() {
    $('div.edit_text a').click(function() {
      EOL.TextObjects.open_new_text_dialog($(this).attr('href'));
      return false;
    });
  },

  // When you have a populated new-text dialog, show it and make it work:
  show_new_text_dialog: function() {
    $('#insert_text_popup').slideDown(400, function() {
      $(window).scrollTop($('#insert_text_popup').offset()['top'] - 40);
    });
    EOL.TextObjects.enable_form();
  },

  // Loads the new text dialog via ajax, changes the TOC if needed (for example, if on "Common Names", which doesn't allow
  // text, we want to load an appropriate TOC item).
  create_new_text_dialog: function(link_href) {
    $.ajax({
      url: link_href,
      success: function(response) { $('#insert_text_popup .popup-content').html(response); },
      error: function() {$('#insert_text_popup .popup-content').html("<p>Sorry, there was an error.</p>");},
      complete: function() { EOL.TextObjects.show_new_text_dialog(); }
    });
    if($('#new_text_toc_text').attr('href').indexOf('toc_id=none') != -1) {
      $.ajax({url:$('#new_text_toc_text').attr('data-change_toc_url'), type:'post'});
    }
  }

};
