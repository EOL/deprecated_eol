$(document).ready(function() {
  // Submit the sort when it's changed:
  $('#sort_by').change(function() {$(this).closest('form').submit();});
  $('input[name=commit_select_all]').click(function() {
    $('.object_list input[name="collection_items[]"]').prop('checked', true); return(false);
  });
  $('input[name=commit_sort]').hide();
});
