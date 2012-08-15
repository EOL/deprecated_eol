// OBSOLETE - NOT USED IN V2?

if (!EOL) { EOL = {}; }
// TODO - move this to eol.js and possibly use it elsewhere (user.js, for example).
EOL.pulsate_error = function(el) {
  $(el).fadeIn('fast').fadeOut('fast').fadeIn('fast').fadeOut('fast').fadeIn('fast').delay(4000).fadeOut(2000);
};

if (!EOL) EOL = {};
if (!EOL.Text) EOL.Text = {};
$.extend(EOL.Text, {

  form: function() {
    return $('form#new_data_object, form.edit_data_object');
  },

  // This will either show an existing dialog, create a new one, or show an error if it's already open:
  open_new_text_dialog: function(link_href) {
    if($('#insert_text_popup:visible').length > 0) {
      // show warning because add/edit popup is already being displayed
      EOL.pulsate_error($('.multi_new_text_error'));
    } else {
      // If we already have a form and this is NOT an edit:
      if (EOL.Text.form().length > 0 && link_href.indexOf('edit') == -1) {
        EOL.Text.show_new_text_dialog();
      // Otherwise, we need to (re-)create the form:
      } else {
        EOL.Text.create_new_text_dialog(link_href);
      }
    }
  },

  // Allow users to edit their own text.  This needs to be init'd several times, so it's extracted to a method.
  init_edit_links: function() {
    $('div.edit_text a').unbind('click');
    $('div.edit_text a').click(function() {
      EOL.Text.open_new_text_dialog($(this).attr('href'));
      return false;
    });
  },

  // When you have a populated new-text dialog, show it and make it work:
  show_new_text_dialog: function() {
    $('#insert_text_popup').slideDown(400, function() {
      $(window).scrollTop($('#insert_text_popup').offset().top - 40);
    });
    try { EOL.Text.enable_form(); } catch(e) { } // This isn't always loaded at this point (and runs elsewhere when it isn't)...
  },

  // Loads the new text dialog via ajax, cleans up content if needed (for example, if on "Common Names")
  create_new_text_dialog: function(link_href) {
    $.ajax({
      url: link_href,
      success: function(response) {
        // If this is not a toc item we're allowed to add text to, we need to do some cleanup:
        if($('#new_text_toc_text').attr('href').indexOf('toc_id=none') != -1) {
          $('.cpc-content').children().not('#insert_text_popup').slideUp(400).delay(100).remove();
          $.ajax({url:$('#new_text_toc_text').attr('data-change_toc_url'), type:'post'});
        }
        $('#insert_text_popup .popup-content').html(response);
      },
      error: function() {$('#insert_text_popup .popup-content').html("<p>Sorry, there was an error.</p>");},
      complete: function() { EOL.Text.show_new_text_dialog(); }
    });
  },

  // This is only called server-side, but in two different places, so I'm keeping it here:
  update_add_links: function(url) {
    $('li.add_text>a, div.add_text_button a').attr('href', url);
  },

  init_text_content_behaviors: function() {
    // NOTE - These get reloaded often, so I am unbinding them before re-binding them. (Otherwise they fire twice.)
    $('a.gloss-tooltip').tooltip();
    // Allow the user to show extra attribution information for text
    $('.expand-text-attribution').unbind('click');
    $('.expand-text-attribution').click(function(e) {
      // TODO - I don't think we need the each() here... I think it will work withgout it, but cannot test now
      $('div.' + $(this).attr('id').substring(4) +' div.credit').each(function(){ $(this).fadeIn(); });
      $(this).fadeOut();
      return false;
    });
    // slide in text comments
    $('div.text_buttons div.comment_button a').unbind('click');
    $('div.text_buttons div.comment_button a').click(function(e) {
      data_object_id = $(this).attr('data-data_object_id');
      textCommentsDiv = "text-comments-wrapper-" + data_object_id;
      textCommentsWrapper = "#" + textCommentsDiv;
      $.ajax({
        url: $(this).attr('href'),
        data: { body_div_name: textCommentsDiv },
        success: function(result) { $(textCommentsWrapper).html(result); },
        error: function() {$(textCommentsWrapper).html("<p>Sorry, there was an error.</p>");},
        complete: function() { $(textCommentsWrapper).slideDown(); }
      });
      return false;
    });
    // Curate text:
    $('div.text_buttons div.curate_button a').unbind('click');
    $('div.text_buttons div.curate_button a').click(function(e) {
      data_object_id = $(this).attr('data-data_object_id');
      textCuration = "text-curation-" + data_object_id;
      textCurationWrapper = "#text-curation-wrapper-" + data_object_id;
      $.ajax({
        url: $(this).attr('href'),
        data: { body_div_name: textCuration },
        success: function(result) { $('#'+textCuration).html(result); },
        error: function() {$(textCurationWrapper).html("<p>Sorry, there was an error.</p>");},
        complete: function() { $(textCurationWrapper).slideDown(); }
      });
      return false;
    });
    // Open the add-text user interface
    $('li.add_text>a, div.add_text_button a').unbind('click');
    $('li.add_text>a, div.add_text_button a').click(function() {
      EOL.Text.open_new_text_dialog($(this).attr('href'));
      return false;
    });
    // Open edit-text user interface:
    EOL.Text.init_edit_links();
  }

});

$(document).ready(function() {
  EOL.Text.init_text_content_behaviors();
});

