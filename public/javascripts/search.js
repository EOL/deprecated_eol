if(!EOL) var EOL = {}
if(!EOL.Search) EOL.Search = {}

EOL.Search.show_top_spinner = function() {
  Element.show('top_search_spinner');
}

EOL.Search.Behaviors = {
  '#change_content_level': function () {
    $('content_level').value=1;    
    showAjaxIndicator();
    document.forms.search_form.submit();    
  }
}