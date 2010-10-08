if (!EOL) var EOL = {};
if (!EOL.CommonNameCuration) EOL.CommonNameCuration = {};

Event.addBehavior({
  'td.preferred_name_selector input[type="radio"]:click': function(e) {
    var form = e.element().form;
    form.submit();
  }
});

Event.addBehavior({
  'td.preferred_name_selector input[type="checkbox"]:click': function(e) {
    var form = e.element().form;
    name_id = e.element().value
    duplicate = form.elements["duplicate_" + name_id].value;
    agent = form.elements["agent_" + name_id].value;
    is_checked_now = e.element().checked;
    do_submit = true;
    if(is_checked_now == false && !duplicate)
    {
      do_submit = confirm("Are you sure you want to delete this common name added by "+agent+"?");
    }
    if(do_submit)
    {
      form.elements["trusted_name_clicked_on"].value = name_id;
      form.elements["trusted_synonym_clicked_on"].value = form.elements["synonym_id_" + name_id].value;
      form.elements["trusted_name_checked"].value = e.element().checked;
      form.submit();
    }else
    {
      e.element().checked = true
    }
  }
});

if ($("add_common_name_button")) $("add_common_name_button").observe('click', confirmAddCommonName);

function confirmAddCommonName(e) {
  var name = $("name_name_string").value.strip();
  var language = $("name_language").value;
  if (name != '') {
    i_agree = confirm("Create a new common name?\n\nYou can always delete it later");
    if (i_agree) {
      var form = e.element().form;
      form.submit();
    }
  } else alert("Add a new common name first");
}
