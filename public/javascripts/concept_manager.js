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
    beforeSend: function(xtr) { input.siblings(".entries").html('looking up...'); },
    success: function(response) {
      input.siblings(".entries").html(response);
    },
    error: function(xtr) { input.siblings(".entries").html('lookup failed'); }
  });
}