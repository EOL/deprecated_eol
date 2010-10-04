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
});
