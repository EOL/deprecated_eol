/* This handles all of the functionality of the mini-clade browser, which is used in several places.
 *
 */
// Set up some stupid defaults, just in case.  (All of these should be supplied before now, though.)
if (!EOL) EOL = {};
if (!EOL.clade_selector_input_name) EOL.clade_selector_input_name = 'selected-clade-id';
if (!EOL.clade_selector_id) EOL.clade_selector_id = 'selected-clade-id';
if (!EOL.clade_selector_id) EOL.clade_selector_id = '<img src="/images/indicator_arrows_black.gif"/>';
if (!EOL.expand_clade_behavior) EOL.expand_clade_behavior = function() {
  $('a.expand-clade').click(function() {
    $('value_' + $(this).attr('clade_id')).html(EOL.indicator_arrows_html);
    // TODO - This is EXTREMELY inefficient in that it re-loads the current page with a given node expanded and then grabs
    // the entire tree from the resulting HTML and puts in place of the existing one.  This is really ugly.  Needs to be
    // fixed ASAP. Note that this special functionality of load() is ONLY available with load() (not with, say, $.ajax()).
    var tree_path = '#'+EOL.clade_selector_id+'-inner ul.tree'
    $(tree_path).load($(this).attr('href') + ' ' + tree_path, // special syntax to grab *part* of a response.
      '', // data.  We don't want to send any.  Careful not to use an object {} here, the request w/ become a POST.
      function() { EOL.expand_clade_behavior(); } // this is called when the response is complete.
    );
    return false;
  });
}

// Alias to display a node when it's not for a selection:
function displayNode(id) {
  displayNode(id, false);
}

// call remote function to show the selected node in the text-based navigational tree view
function displayNode(id, for_selection) {
  url = '/navigation/show_tree_view'
  if(for_selection) {
    url = '/navigation/show_tree_view_for_selection'
  }
  $.ajax({
    url: url,
    type: 'POST',
    success: function(response){$('#browser-text').html(response);},
    error: function(){ $('#browser-text').html("<p>Sorry, there was an error.</p>"); },
    data: {id: id}
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser(hierarchy_entry_id, expand) {
  $.ajax({
    url: '/navigation/browse',
    complete: function(){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    error: function(){ $('#browser-text').html("<p>Sorry, there was an error.</p>"); },
    data: {id: hierarchy_entry_id, expand: expand }
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser_stats(hierarchy_entry_id, expand) {
  $.ajax({
    url: '/navigation/browse_stats',
    complete: function(request){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    error: function(){ $('#browser-text').html("<p>Sorry, there was an error.</p>"); },
    data: {id: hierarchy_entry_id, expand: expand }
  });
}

$(document).ready(function() {
  $('#browser_hide a').click(function() {
    $($(this).attr('href')).slideUp();
    $('#browser_show').show();
    $('#browser_hide').hide();
    return false;
  });
  $('#browser_show a').click(function() {
    $($(this).attr('href')).slideDown();
    $('#browser_show').hide();
    $('#browser_hide').show();
    return false;
  });
  $('#browser_clear a').click(function() {
    clear_clade_of_clade_selector();
    return false;
  });
  // Show the clade browser if the checkbox is checked:
  if($('input#curator_request').attr('checked')) {
    $("#curator_request_options").slideDown();
  } else {
    $("#curator_request_options").slideUp();
  }
  // Click to show/hide the clade browser:
  $('input#curator_request').click(function() {
    if($(this).attr('checked')) {
      $("#curator_request_options").slideDown();
    } else {
      $("#curator_request_options").slideUp();
    }
  });
  EOL.expand_clade_behavior();
});

function select_clade_of_clade_selector( clade_id ) {
  $(EOL.clade_selector_input_name).val(clade_id);
  unselect_all_clades_of_clade_selector();
  $('li.value_' + clade_id).addClass('selected');
}

function clear_clade_of_clade_selector() {
  $(EOL.clade_selector_input_name).val('');
  unselect_all_clades_of_clade_selector();
}

function unselect_all_clades_of_clade_selector() {
  $('div#'+EOL.clade_selector_id+' ul.tree li.selected').removeClass('selected');
}
