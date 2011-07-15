if(!EOL) { var EOL = {}; }

// TODO = Cleanup.  This was hacked together hastily, trying to deal with a task that's already DAYS past when it was
// supposed to be done.  For one, I'm not sure we need more than "html" to be set in the ajaxSetup.  Second, we
// should abstract those two Ajax calls, which are so similar.  ...And likely more.

// TODO - these unbind() calls are not working.  Not sure why.  Invesitgate.  (Clicking on multiple "edit annotation"
// links will submit the request multiple times.)

// TODO - move this somewhere global:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

if (!EOL.init_collection_behaviours) {
  EOL.init_collection_behaviours = function() {
    // Submit the sort when it's changed:
    $('#sort_by').unbind('change');
    $('#sort_by').change(function() {$(this).closest('form').submit();});
    // Select All:
    // TODO: there's something in the application JS file that could handle this. Try it.
    $('input[name=commit_select_all]').unbind('click');
    $('input[name=commit_select_all]').click(function() {
      $('.object_list input[name="collection_items[]"]').prop('checked', true); return(false);
    });
    // Get tiny editable forms when clicking on the edit link:
    $('input[name=commit_sort]').hide();
    $('.editable_link a').click(function() {  // TODO - this isn't working?  Is change the wrong method?
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
    $('input[name=commit_edit_collection]').unbind('click');
    $('input[name=commit_edit_collection]').click(function() {
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
  };
}

$(document).ready(function() {
  EOL.init_collection_behaviours();
});
