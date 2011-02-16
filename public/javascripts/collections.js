if (!EOL) { EOL = {}; }
if (!EOL.show_collection_name_field) {
  EOL.show_collection_name_field = function() {
    $('#collection_name_field').slideDown();
  };
}
