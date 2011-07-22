if(!EOL) { var EOL = {}; }

// TODO = Cleanup.  This was hacked together hastily, trying to deal with a task that's already DAYS past when it was
// supposed to be done.  For one, I'm not sure we need more than "html" to be set in the ajaxSetup.  Second, we
// should abstract those two Ajax calls, which are so similar.  ...And likely more.

// TODO - these unbind() calls are not working.  Not sure why.  Invesitgate.  (Clicking on multiple "edit annotation"
// links will submit the request multiple times.)

if (!EOL.init_collection_behaviours) {
  EOL.init_collection_behaviours = function() {
    // Submit the sort when it's changed:
    $('#sort_by').unbind('change');
    $('#sort_by').change(function() {$(this).closest('form').submit();});
    // Get tiny editable forms when clicking on the edit link:
    $('input[name=commit_sort]').hide();
  };
}

$(document).ready(function() {
  EOL.init_collection_behaviours();
});
