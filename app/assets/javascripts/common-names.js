if(!EOL) { var EOL = {}; }

if (!EOL.init_common_name_behaviors) {
  EOL.init_common_name_behaviors = function() {
    // Just clicking on a preferred name submits the form (and reloads the page):
    $('td.preferred_name_selector input[type="radio"]').unbind('click');
    $('td.preferred_name_selector input[type="radio"]').on('click', function() {
      var form = $(this).closest('form');
      form.submit();
    });
    // Checkbox may ask the user to confirm; if they don't, it re-checks the box:
    $('td.vet_common_name select').unbind('change').change(function() {
      var $update = $(this).closest('tr');
      var url = $(this).attr('data_url');
      url = url.replace(/REPLACE_ME/, $(this).val());
      EOL.ajax_submit($(this), {url: url, update: $update, data: {}, type: 'GET',
        complete: function(response) {
          EOL.init_common_name_behaviors();
        }}); // data is in the url.
    });
    // Confirm adding a common name:
    $("#add_common_name_button").unbind('click');
    $("#add_common_name_button").on('click', function() {
      var name = $.trim($("#name_name_string").val());
      var language = $("#name_language").val();
      if (name !== '') {
        // TODO - i18n (put this in the view and show/hide it, duh)
        i_agree = confirm("Create a new common name?\n\nYou can always delete it later");
        if (i_agree) {
          $(this).closest('form').submit();
        }
      } else alert("Add a new common name first");
    });
  };
}

$(document).ready(function() {
  EOL.init_common_name_behaviors();
});

function vet_common_name(tc_id, lang_id, name_id, select_tag_id, he_id)
{
  var x = document.getElementById(select_tag_id).selectedIndex;
  var y = document.getElementById(select_tag_id).options;
  //alert("Index: " + y[x].index + " is " + y[x].text + " value: " + y[x].value);
  document.getElementById('form_taxon_concept_id').value = tc_id;
  document.getElementById('form_language_id').value = lang_id;
  document.getElementById('form_name_id').value = name_id;
  document.getElementById('form_vetted_id').value = y[x].value;
  document.getElementById('form_hierarchy_entry_id').value = he_id;
  document.forms.vet_common_name_form.submit();
}
