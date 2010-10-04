if(!EOL) var EOL = {}
if(!EOL.Search) EOL.Search = {}

EOL.Search.show_top_spinner = function() {
  $('#top_search_spinner').show();
}

EOL.validate_search_parameters = function(form,advanced_search) {
  if ($('#q').attr('value').trim() == "") {
    error_message = 'Please enter a search term!';
    $('#search_message').html(error_message);
    if (advanced_search == true) {
      $('#advanced_search_message').html(error_message);
    }
    $('#q').focus();
    return false;
  } else {
    $('.search_image').hide();
    if (advanced_search == true) {
      $('#advanced_search_message').html('Searching...');
    } else {
      $('#search_message').html('Searching...');
    }
    if(!advanced_search) {
      EOL.Search.show_top_spinner();
    } else {
      $('#ajax-indicator').show();
    }
    return true;
  }
}

