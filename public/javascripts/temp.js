/*
 *   This is intended to be merged back into the "application" JS, once that has settled from HR.
 */

// TODO - not all of these are required, if we know we won't use them:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

$('.editable_link a').click(function() {
  var url = $(this).attr('href');
  var cell = $(this).closest('.editable');
  $.ajax({
    url: url,
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      $('.editable_link a').unbind('click'); // TODO - needed?
      EOL.init_collection_behaviours();
    }
  });
  return(false); // stop event... there's a better way to do this?
});
// Submit tiny editable forms and return the tiny html response:
$('input.edited_field').unbind('click');
$('input.edited_field').click(function() {
  var form = $(this).closest('form');
  var cell = $(this).closest('.editable');
  var url  = form.attr('action');
  if($(this).attr('data_url') != undefined) {
    url = $(this).attr('data_url');
  }
  $.ajax({
    url: url,
    data: form.serialize(),
    type: 'POST',
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      EOL.init_collection_behaviours();
    }
  });
  return(false); // stop event... there's a better way to do this?
});
