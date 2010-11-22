function lookup_concept(input_id) {
  lookup_id(input_id, '/concept_manager/lookup_concept/');
}
function lookup_entry(input_id) {
  lookup_id(input_id, '/concept_manager/lookup_entry/');
}

function lookup_id(input_id, url_prefix) {
  var input = $(input_id);
  $.ajax({
    url: url_prefix + input.val(),
    beforeSend: function(xtr) { input.siblings(".entries").html('<p style="text-align: center;"><img src="/images/green_loader.gif"/></p>'); },
    success: function(response) {
      input.siblings(".entries").html(response);
      input.siblings(".entries").attr('taxon_concept_id', $(this).attr('id'));
    },
    error: function(xtr) { input.siblings(".entries").html('lookup failed'); }
  });
}


$(document).ready(function() {
});