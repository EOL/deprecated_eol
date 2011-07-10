$(document).ready(function() {
  // Submit the sort when it's changed:
  $('#sort_by').change(function() {$(this).closest('form').submit();});
  $('input[name=commit_sort]').hide();
});
