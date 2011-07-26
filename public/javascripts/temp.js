/*
 *   This is intended to be merged back into the "application" JS, once that has settled from HR.
 */

if(!EOL) { var EOL = {}; }

// TODO - not all of these are required, if we know we won't use them:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

// TODO - I gave up on this and put the form right on the page.  This is less than ideal, but I18n made this a bad
// option for now. I'm keeping the code here for help later, though.
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

// trying to generalize Ajax calls for EOL:
// Arguments:
//   el: The element firing the event.  It helps us find stuff, please pass it.
//   update: where you want the (html) response to go.  Defaults to the closest .editable item.
//   url: where you want the form to subit to.  Defaults to the data_url of the el you pass in, then to the nearest
//        form's action.
//   data: The data to send.  Defaults to the nearest form, serialized.
//   complete: Function to call when complete.  Optional.
EOL.ajax_submit = function(el, args) {
  var form = el.closest('form');
  var cell = '';
  if(typeof(args.update) != 'undefined') {
    cell = args.update;
  } else {
    cell = el.closest('.editable');
  }
  var url  = '';
  if(typeof(args.url) != 'undefined') {
    url = args.url;
  } else if(typeof(el.attr('data_url')) != 'undefined') {
    url = el.attr('data_url');
  } else {
    url = form.attr('action');
  }
  var data = '';
  if(typeof(args.data) != 'undefined') {
    data = args.data;
  } else {
    data = form.serialize();
  }
  complete = '';
  if(typeof(args.complete) != 'undefined') {
    complete = args.complete;
  }
  $.ajax({
    url: url,
    data: data,
    type: 'POST',
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      if(complete != '') {
        complete();
      }
    }
  });
  return(false); // stop event... there's a better way to do this?
};

// Add to collection buttons should be Ajaxy:
$(function() {
  $('form#new_collection_item').find('input.button').click(function() {
    var $f = $(this).closest('form');
    EOL.ajax_submit($(this), {update: $f})
    return(false);
  });
});

$(function() {
  $('#sort_by').change(function() {
    $(this).closest('form').find('input[type="submit"]').click();
  });
  $('input[type="submit"]').hide();
});
