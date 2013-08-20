$(function() {

  // uncheck search filter All when other options are selected
  $("#main_search_type_filter input[type=checkbox][value!='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value='all']").prop("checked", false);
  });
  // uncheck all other search filter options when All is selected
  $("#main_search_type_filter input[type=checkbox][value='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value!='all']").prop("checked", false);
  });
  // disable the checkboxes for filter categories with no results
  $("#main_search_type_filter li.no_results input[type=checkbox]").attr("disabled", true);

  // Search should not allow you to search without a term:
  $("#simple_search :submit").click(function() {
    var $q = $("#simple_search :submit").closest('form').find('#q');
    if ($q.val() == $(this).attr('data_unchanged')) {
      $q.css('color', '#aa0000').val($(this).attr('data_error')).click(function() { $(this).val('').css('color', 'black').unbind('click'); });
      return(false);
    } else if ($q.val() == $(this).attr('data_error')) {
      var blinkIn = 20;
      var blinkOut = 350;
      $q.css('color', '#aa0000').fadeOut(blinkOut).fadeIn(blinkIn).fadeOut(blinkOut).fadeIn(blinkIn).fadeOut(blinkOut).fadeIn(blinkIn);
      return(false);
    }
  });

});
