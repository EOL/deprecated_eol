if(!EOL) { var EOL = {}; }
if (!EOL.CommonNameCuration) { EOL.CommonNameCuration = {}; }

$(document).ready(function() {
  // Just clicking on a preferred name submits the form (and reloads the page):
  $('td.preferred_name_selector input[type="radio"]').click(function() {
    var form = $(this).closest('form');
    form.submit();
  });
  // Checkbox may ask the user to confirm; if they don't, it re-checks the box:
  $('td.preferred_name_selector input[type="checkbox"]').click(function() {
    var form = $(this).closest('form');
    name_id = $(this).val()
    duplicate = !(form.find("#duplicate_" + name_id).val() == 'false'); // Sorry, I am not *positive* what the true val w/b
    agent = form.find("#agent_" + name_id).val();
    is_checked_now = $(this).attr('checked');
    do_submit = true;
    if (!is_checked_now && !duplicate) {
      do_submit = confirm("Are you sure you want to delete this common name added by "+agent+"?");
    }
    if (do_submit) {
      form.find("#trusted_name_clicked_on").val(name_id);
      form.find("#trusted_synonym_clicked_on").val(form.find("#synonym_id_"+name_id).val());
      form.find("#trusted_name_checked").val(is_checked_now);
      form.submit();
    } else {
      $(this).attr('checked', true);
    }
  });
  // Confirm adding a common name:
  $("#add_common_name_button").click(function() {
    var name = $.trim($("#name_name_string").val());
    var language = $("#name_language").val();
    if (name != '') {
      // TODO - i18n
      i_agree = confirm("Create a new common name?\n\nYou can always delete it later");
      if (i_agree) {
        $(this).closest('form').submit();
      }
    } else alert("Add a new common name first");
  });
});
