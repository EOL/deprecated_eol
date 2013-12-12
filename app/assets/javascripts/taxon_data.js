if (!EOL) { var EOL = {}; }

var _TOOLTIP_OPEN = false;

EOL.max_meta_rows = 10;

EOL.create_info_dialog = function(match) {
  var $has_id = $(match).closest('[id]');
  var nearest = $has_id.attr('id'); // We need to remember which one is open; click again and it closes.
  $(match)
    .attr('id', "info_"+nearest)
    .before('<a id="tip_'+nearest+'" class="info_icon" data-info="'+nearest+'">&emsp;&emsp;&emsp;&emsp;</a>') // Spaces 'cause width doesn't work. :\
    .addClass('tip')
    .prepend('<a href="#" class="close">&nbsp;</a>');
  EOL.enable_info_dialogs($('#tip_'+nearest));
  $(match).appendTo(document.body);
};

EOL.enable_info_dialogs = function(tip) {
  tip.unbind('click')
    .on('click', function() {
      $('.site_column').unbind('click');
      var $link = $(this);
      var $info = $('#info_'+$(this).attr('data-info'));
      if ($info.is(':visible')) {
        $info.hide('fast');
      } else {
        $('.info.tip').hide('fast');
        var pos = $(this).offset();
        $info.css({ top: pos.top + $(this).height() + 26, left: pos.left + $(this).width() });
        $info.show('fast',
          function() {
            $('.site_column').on('click', function() { $('.info').hide('fast'); $('.site_column').unbind('click'); });
          }
        ).find('a.close').on('click', function() { $('.info').hide('fast'); return(false) } );
      }
    });
  // making sure the info icons show when anywhere on the row is moused over
  $('table.data tr.data, table.meta tr').hover(
    function() {
      $(this).find('.info_icon').addClass('active');
    },
    function() {
      $(this).find('.info_icon').removeClass('active');
    }
  );
};

EOL.enable_button = function($button) {
  if ($button.is(':disabled')) {
    $button.removeAttr('disabled').fadeTo(225, 1);
  }
};

EOL.disable_button = function($button) {
  if (!$button.is(':disabled')) {
    $button.attr("disabled", true).fadeTo(225, 0.3);
  }
};

EOL.attribute_is_not_okay = function() {
  $('input#user_added_data_predicate').addClass('problems');
  $('#new_uri_warning').show();
  EOL.disable_measurement_input();
};

EOL.attribute_is_okay = function() {
  $('input#user_added_data_predicate').removeClass('problems');
  $('#new_uri_warning').hide();
  if ($('#predicate_uri_type').val() == 'measurement' && $('#user_added_data_predicate').val() != '') {
    $('fieldset.unit_of_measure').fadeIn(100);
  } else {
    EOL.disable_measurement_input();
  }
};

EOL.disable_measurement_input = function() {
  $('fieldset.unit_of_measure').fadeOut(100);
  $('fieldset.unit_of_measure input').val('');
}

EOL.hide_data_tables = function(tables) {
  tables.hide();
  tables.prev('div.header_underlined').hide();
};

EOL.show_data_tables = function(tables) {
  tables.show();
  tables.prev('div.header_underlined').show();
  tables.find('tr.data').show();
  tables.find('tr.actions').hide();
  $('.help_text').show();
};

EOL.toggle_actions_row = function(data_row) {
  var $folder = data_row.find('.fold img');
  var $next_row = data_row.next();
  var $next_row_data = $next_row.children('td');
  var $table = data_row.next().find('table.meta');
  if ($next_row.is(":visible")) {
    $folder.attr('src', "/assets/arrow_fold_right.png");
    $next_row.hide();
    $table.hide();
  } else {
    var data_point_id = data_row.attr('id');
    // the metadata table hasn't been loaded yet, so load it dynamically
    if (data_row.data('loading') != true && data_row.data('loaded') != true) {
      $folder.attr('src', '/assets/indicator_arrows_black.gif');
      data_row.data('loading', true);
      $.ajax({
        url: '/data_point_uris/' + data_point_id.replace('data_point_', '') + '/show_metadata',
        dataType: 'html',
        success: function(response) {
          var $pasted = $next_row_data.prepend(response);
          $pasted.find('.info').each(function() {
            var html = $(this).find('ul.glossary > li').html();
            var uri = $(this).find('.uri').text();
            EOL.create_info_dialog(this);
            // only add the term if it is not already in the glossary
            $('.glossary_subtab ul.glossary:not(:contains("' + uri + '"))').append('<li>'+html+'</li>');
          });
          // sort the glossary now that new items have been added to the end
          $(".glossary_subtab ul.glossary > li").sort(EOL.sort_glossary).appendTo('.glossary_subtab ul.glossary');
          EOL.enable_hover_list_items();
        },
        error: function(xhr, stat, err) { $next_row.html('<p>Sorry, there was an error: '+stat+'</p>'); },
        complete: function() {
          $folder.attr('src', "/assets/arrow_fold_down.png");
          $next_row.show();
          EOL.yank_glossary_terms($next_row);
          $table.show();
          data_row.data('loading', false);
          data_row.data('loaded', true);
          $folder.attr('src', "/assets/arrow_fold_down.png");
        }
      });
    } else if(data_row.data('loading') != true)
    {
      $folder.attr('src', "/assets/arrow_fold_down.png");
      $next_row.show();
      $table.show();
    }
  }
}

EOL.sort_glossary = function(a, b) {
  return ($(b).find('dt').text()) < ($(a).find('dt').text()) ? 1 : -1;
}

EOL.enable_suggestions_hover = function() {
  $('input#user_added_data_predicate').parent().hover(function() {
    if (!$('ul.ui-autocomplete').is(':visible') && $('input#user_added_data_predicate').val() == '') {
      $('div#suggestions').show();
    } else $('div#suggestions').hide();
  }, function () {
    $('div#suggestions').hide();
  });
}

EOL.disable_suggestions_hover = function() {
  $('input#user_added_data_predicate').parent().unbind('hover');
}

function update_input_id_and_name(form, new_id) {
  form.find('input').each(function() {
    $(this).attr('id', $(this).attr('id').replace(/\d+/, new_id));
    $(this).attr('name', $(this).attr('name').replace(/\d+/, new_id));
    // these 3 fields are used in autocompleting of metadata
    if ($(this).attr('data-id-element')) {
      $(this).attr('data-id-element', $(this).attr('data-id-element').replace(/\d+/, new_id));
    }
    if ($(this).attr('data-include-predicate_known_uri_id')) {
      $(this).attr('data-include-predicate_known_uri_id', $(this).attr('data-include-predicate_known_uri_id').replace(/\d+/, new_id));
    }
    if ($(this).attr('data-update-elements')) {
      $(this).attr('data-update-elements', $(this).attr('data-update-elements').replace(/\d+/, new_id));
    }
  });
}

EOL.limit_data_rows = function() {
  $('table.data tr.more').remove();
  $('table.data tr.data.first_of_type:visible').each(function() {
    var type = $(this).attr('data-type');
    var $nested_set = $(this).closest('table').find('tr[data-type="' + type + '"]:visible');
    if ($nested_set.length > EOL.max_meta_rows) {
      var $index = 1;
      $nested_set.each(function() { if ($index > EOL.max_meta_rows) $(this).hide(); $index++; });
      $nested_set.filter(':last').after(
        '<tr data-type="' + type + '" class="data nested more"><th></th><td><a href="#" class="more">' +
        $('table.data').attr('data-more').replace('NNN', ($nested_set.length-EOL.max_meta_rows)) +
        '</a></td></tr>');
      $('tr.more a.more').unbind('click').on('click', function() {
        var $parent_row = $(this).closest('tr');
        $('tr.data[data-type="' + $parent_row.attr('data-type') +'"]').show();
        $parent_row.remove();
        return(false);
      });
    }
  });
};

EOL.yank_glossary_terms = function($row) {
};

EOL.enable_hover_list_items = function() {
  $('ul.glossary li').hover(
    function() {
      $(this).find('li.hover').show();
    }, function() {
      $(this).find('li.hover').hide();
    }
  );
}

$(function() {

  $('.has_many').each(function() {
    var $subform = $(this).clone();
    $subform.find('.once').remove();
    var last_input = $(this).closest('form').find('input[id^=user_added_data_user_added_data_metadata_attributes]').filter(':last');
    var highest_field_id = parseInt(last_input.attr('id').match(/(\d+)/)[1]);
    update_input_id_and_name($subform, highest_field_id += 1);
    $subform.appendTo($(this)).addClass('subform').hide();
    $(this).append('<span class="add"><a href="#">'+$(this).attr('data-another')+'</a></span>');
    $(this).find('.add a').on('click', function() {
      $subform.clone().insertBefore($(this).parent()).show();
      update_input_id_and_name($subform, highest_field_id += 1);
      var form_h = $('.has_many_expandable').height();
      $('.has_many_expandable').height(form_h + $subform.height());
      return(false);
    });
  });

  $('div#suggestions').appendTo($('input#user_added_data_predicate').parent());

  $('input#user_added_data_predicate').keyup(function(e) {
    var key = e.keyCode || e.which;
    // it was the return key that was pressed, likely the user
    // choosing an autocomplete value from the list, so do nothing
    if (key === 13) return;
    var $field = $(this)
    if ($field.val() != '') {
      $('div#suggestions').hide();
    }
    if ($('#user_added_data_predicate_known_uri_id').val() != '') {
      $('#user_added_data_predicate_known_uri_id').val('');
      EOL.attribute_is_not_okay();
    }
    if ($field.val() == '' || $('#user_added_data_predicate_known_uri_id').val() != '') {
      EOL.attribute_is_okay();
    } else EOL.attribute_is_not_okay();
  }).focus(function() {
    if ($(this).val() == '') {
      $('div#suggestions').show();
    }
  });

  EOL.enable_suggestions_hover();

  $('fieldset.unit_of_measure').hide();

  $('table.data .fold a').on('click', function() { $(this).closest('tr').click(); return(false); }); // These links just click the row, with JS.

  $('table.data tr.actions').hide().prev().find('.fold img').attr('src', "/assets/arrow_fold_right.png");

  $('table.data tr.data').on('click',
    function(e) {
      if ($(e.target).closest('a').length) return; // It's a link, don't handle the row...
      EOL.toggle_actions_row($(this));
    });

  $('table.data tr.actions td .metadata').live('click',
    function(e) {
      if ($(e.target).closest('a').length) return; // It's a link, don't handle the row...
      EOL.toggle_actions_row($(this).closest('tr').prev());
    });

  $('#recently_used_category a').on('click', function() {
    $('#suggestions').find('.child').hide();
    var $next = $(this).parent().next();
    while($next.hasClass('child')) {
      $next.show();
      $next = $next.next();
    }
    return(false);
  });

  $('li.attribute').live('click', function() {
    var span = $(this).find('.name');
    $('#user_added_data_predicate').val(span.text());
    $('#user_added_data_predicate_known_uri_id').val(span.data('id'));
    $('#predicate_uri_type').val(span.data('uri_type'));
    $('#user_added_data_has_values').val(span.data('has_values'));
    EOL.attribute_is_okay();
    $('div#suggestions').hide();
  });

  // any chosen autocomplete value is legitimate
  $('#user_added_data_predicate').bind('railsAutocomplete.select', function(event, data){
    EOL.attribute_is_okay();
  });

  $('input[data-autocomplete]').live('focus', function() {
    // if the field is a value autocomplete, check the hidden *_has_values
    // field to see if we should disable autocomplete or not
    if ($(this).data('autocomplete').match(/known_uri_values/)) {
      var value_toggle = $(this).closest('div').find('input[id*="has_values"]:first');
      if (value_toggle.length > 0) {
        if (value_toggle.val() == '1') $(this).autocomplete('enable');
        else $(this).autocomplete('disable');
      }
    }

    // for the primary measurement, always autocomplete with the value in the text input. The other
    // autocomplete fields will search on ' ' to show always show the pick-list on focus. The primary
    // measurment field will show the custom selector when the field is empty
    if ($(this).attr('id') == 'user_added_data_predicate') {
      $(this).autocomplete("search", $(this).val());
    } else $(this).autocomplete("search", ' ');
  });

  // this helps show default pick-lists when the fields are empty
  $('input[data-autocomplete]').keyup(function(e) {
    var key = e.keyCode || e.which;
    // do nothing if it the key pressed was an arrow key, that would interfere with autocomplete selection
    if (key === 37 || key === 38 || key === 39 || key === 40) return;
    if ($(this).val() == '') {
      if ($(this).attr('id') == 'user_added_data_predicate') {
        $('div#suggestions').show();
      } else $(this).autocomplete("search", ' ');
    }
  });

  $('#tabs_sidebar.data ul.subtabs a').on('click', function() {
    $('.about_subtab').hide();
    $('.glossary_subtab').hide();
    if ($(this).parent().hasClass('about')) {
      EOL.hide_data_tables($('table.data'));
      $('#taxon_data .empty').hide();
      $('.glossary_subtab').hide();
      $('.help_text').hide();
      $('.about_subtab').show()
    } else if ($(this).parent().hasClass('glossary')) {
      EOL.hide_data_tables($('table.data'));
      $('#taxon_data .empty').hide();
      $('.about_subtab').hide();
      $('.help_text').hide();
      $('.glossary_subtab').show()
    } else if ($(this).hasClass('all')) { // Acts as a reset button/link
      $('#taxon_data .empty').show();
      EOL.show_data_tables($('table.data'));
    } else {
      EOL.hide_data_tables($('table.data'));
      EOL.show_data_tables($('table.data[data-toc-id="' + $(this).attr('data-toc-id') + '"]'));
    }
    $(this).parent().parent().find('li').removeClass('active');
    $(this).parent().addClass('active');
    // Reset other aspects of the table:
    $('table.data tr.open').removeClass('open');
    $('table.data .fold img').attr('src', "/assets/arrow_fold_right.png");
    $('table.meta').hide();
    EOL.limit_data_rows();
    return(false);
  });

  EOL.limit_data_rows();

  if (location.hash != "") {
    var name  = location.hash.replace(/\?.*$/, '');
    var $row = $(name);
    $row.click();
    if ($row.offset() !== undefined) {
      var new_top = $row.offset().top - 200;
      $("html, body").animate({ scrollTop: new_top });
    }
  }

  // Remove links on the overview should be hidden until you hover:
  $('#data_summary table').hover(function() {
    $('span.remove').show();
  }, function () {
    $('span.remove').hide();
  }).find('span.remove').hide();

  $('a.button.hidden').hide();

  $('#sortable').sortable({
    placeholder: "placeholder", items: "tr:not(.headers)", helper: 'clone', tolerance: 'pointer',
    update: function(e, ui) {
      $.post("/known_uris/sort", { known_uris: $("#sortable").sortable('toArray'), moved_id: ui.item.attr('id') })
    }
  }).disableSelection();

  $('#sortable a.to_top').on('click', function() {
    $.post("/known_uris/sort", { to: 'top', moved_id: $(this).closest('tr').attr('id') })
    return(false);
  });

  $('#sortable a.to_bottom').on('click', function() {
    $.post("/known_uris/sort", { to: 'bottom', moved_id: $(this).closest('tr').attr('id') })
    return(false);
  });

  // Definitions of Attributes are dialogs if JS is enabled:
  $('table.data tr .info, table.data.search tr .info').each(function() {
    EOL.create_info_dialog(this);
  });

  $('.add_content .article').hide();
  $('.add_content .add_data a').on('click', function() {
    var $article = $('.add_content .article')
    if ($article.is(':visible')) {
      $(this).removeClass('open');
      $('.add_content .article').hide();
    } else {
      $(this).addClass('open');
      $('.add_content .article').show();
    }
    return(false);
  });

  EOL.enable_hover_list_items();

  $('.page_actions .data_download a').on('click', function() {
    window.alert($(this).parent().attr('data-alert').replace(/<\/?[^>]+>/g, ''));
  });

});
