// TODO - these methods (all of them) could use error functions.
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
    success: function(response){$('#browser-text').html(response);},
    data: {id: id}
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser(hierarchy_entry_id, expand) {
  url = '/navigation/browse'
  $.ajax({
    url: url,
    complete: function(){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    data: {id: hierarchy_entry_id, expand: expand }
  });
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser_stats(hierarchy_entry_id, expand) {
  url = '/navigation/browse_stats'
  $.ajax({
    url: url,
    complete: function(request){scroll(0,100);},
    success: function(response){$('#hierarchy_browser').html(response);},
    parameters: {id: hierarchy_entry_id, expand: expand }
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
});

function expand_clade_of_clade_selector( clade_id ) {
  $('value_' + clade_id).html(indicator_arrows_html);
  // TODO: i'll fix this shortly ... for right now, this just needs to work so i hit the page you're on with a new
  // querystring - extremely inefficient - will be fixed ASAP  (JRice: I don't know who said that--not I--but clearly
  // it wasn't fixed.)  :)
  $('#'+some_id+'-inner ul.tree').load(request_path+'?clade_to_expand='+clade_id+' #'+some_id+'-inner ul.tree');
}

function select_clade_of_clade_selector( clade_id ) {
  $(some_name).value = clade_id;
  unselect_all_clades_of_clade_selector();
  $('a.value_' + clade_id).addClass('selected');
}

function clear_clade_of_clade_selector() {
  $(some_name).value = '';
  unselect_all_clades_of_clade_selector();
}

function unselect_all_clades_of_clade_selector() {
  $('div#'+some_id+' ul.tree li.selected').removeClass('selected');
}
