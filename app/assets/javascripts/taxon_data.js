if(!EOL) { var EOL = {}; }

var _TOOLTIP_OPEN = false;

EOL.max_meta_rows = 10;

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
  // EOL.disable_button($('#new_user_added_data').find('input:submit'));
};

EOL.attribute_is_okay = function() {
  $('input#user_added_data_predicate').removeClass('problems');
  $('#new_uri_warning').hide();
  // EOL.enable_button($('#new_user_added_data').find('input:submit'));
};

EOL.add_has_default_behavior = function() {
  $('input.has_default').each(function() {
    if ($(this).val() == '') {
      $(this).val($(this).attr('data-default')).fadeTo(225, 0.6);
    }
    $(this).unbind('focus').unbind('blur');
    $(this).on('focus', function() {
      if ($(this).val() == $(this).attr('data-default')) {
        $(this).val('').fadeTo(150, 1);
      }
    }).on('blur', function() {
      if ($(this).val() == '') {
        $(this).val($(this).attr('data-default')).fadeTo(225, 0.6);
      }
    });
  });
};

EOL.hide_data_tables = function(tables) {
  tables.hide();
  tables.prev('div.header_underlined').hide();
};

EOL.show_data_tables = function(tables) {
  tables.show();
  tables.prev('div.header_underlined').show();
  tables.find('tr.data').show();
  tables.find('tr.actions').hide();
};


function update_input_id_and_name(form, new_id) {
  form.find('input').each(function() {
    $(this).attr('id', $(this).attr('id').replace(/\d+/, new_id));
    $(this).attr('name', $(this).attr('name').replace(/\d+/, new_id));
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
      EOL.add_has_default_behavior();
      return(false);
    });
  });

  $('input#user_added_data_predicate').keyup(function() {
    var $field = $(this)
    if($field.val() != '') {
      $('div#suggestions').hide();
    }
    if ($field.val().match(/^ht/i)) {
      EOL.attribute_is_okay();
      $field.attr('data-autocomplete', $field.attr('data-http'));
    } else {
      $field.attr('data-autocomplete', $field.attr('data-orig'));
      EOL.attribute_is_not_okay();
      if($field.val() == '') {
        EOL.attribute_is_okay();
      } else {
        $('ul.ui-autocomplete').find('li').each(function(i, el) {
          if($(el).text() == $field.val()) {
            EOL.attribute_is_okay();
          }
        });
      }
    }
  }).focus(function() {
    $('div#suggestions').appendTo($(this).parent());
    if ($(this).val() == '') {
      $('div#suggestions').show();
    }
    $(this).parent().hover(function() {
      if (!$('ul.ui-autocomplete').is(':visible') && $(this).val() == '') {
        $('div#suggestions').show();
      }
    }, function () {
      $('div#suggestions').hide();
    });
  });

  $('table.data .fold a').on('click', function() { $(this).closest('tr').click(); return(false); }); // These links just click the row, with JS.

  $('table.data tr.actions').hide().prev().find('.fold img').attr('src', "/assets/arrow_fold_right.png").closest('tr').on('click',
    function(e) {
    if ($(e.target).closest('a').length) return; // It's a link, don't handle the row...
    var $folder = $(this).find('.fold img');
    var $next_row = $(this).next();
    var $this_data = $(this).children('td');
    var $next_row_data = $next_row.children('td');
    var $table = $(this).find('table');
    if ($next_row.is(":visible")) {
      $folder.attr('src', "/assets/arrow_fold_right.png");
      $next_row.hide();
      $table.hide();
      $(this).removeClass('open');
    } else {
      var data_point_id = $(this).attr('id');
      // the metadata table hasn't been loaded yet, so load it dynamically
      if ($table.length == 0) {
        $.ajax({
          url: '/data_point_uris/' + data_point_id.replace('data_point_', '') + '/show_metadata',
          dataType: 'html',
          success: function(response) { $this_data.append(response); },
          error: function(xhr, stat, err) { $next_row.html('<p>Sorry, there was an error: '+stat+'</p>'); },
          complete: function() {
            $folder.attr('src', "/assets/arrow_fold_down.png");
            $next_row.show();
            $table.show();
            $(this).addClass('open');
          }
        });
      } else
      {
        $folder.attr('src', "/assets/arrow_fold_down.png");
        $next_row.show();
        $table.show();
        $(this).addClass('open');
      }
    }
  }).find('table').hide();

  $('#recently_used_category a').on('click', function() {
    $('#suggestions').find('.child').hide();
    var $next = $(this).parent().next();
    while($next.hasClass('child')) {
      $next.show();
      $next = $next.next();
    }
    return(false);
  });

  $('li.attribute').on('click', function() {
    $('#user_added_data_predicate').val($(this).find('.name').text());
    EOL.attribute_is_okay();
    $('div#suggestions').hide();
  });

  $('#tabs_sidebar.data ul.subtabs a').on('click', function() {
    $('p.about').hide();
    if($(this).parent().hasClass('about')) {
      EOL.hide_data_tables($('table.data'));
      $('#taxon_data .empty').hide();
      $('p.about').show()
    } else if($(this).hasClass('all')) { // Acts as a reset button/link
      $('#taxon_data .empty').show();
      EOL.show_data_tables($('table.data'));
    } else {
      EOL.hide_data_tables($('table.data'));
      EOL.show_data_tables($('table.data[data-toc_id="' + $(this).attr('data-toc-id') + '"]'));
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

  EOL.add_has_default_behavior();

  if(location.hash != "") {
    var name  = location.hash.replace(/\?.*$/, '');
    var $row = $(name);
    $row.click();
    var new_top = $row.offset().top - 200;
    $("html, body").animate({ scrollTop: new_top });
  }

  // Move additional command buttons back onto the form proceeding them (saves a lot of ugliness in views):
  $('.additional_commands').each(function() { $(this).appendTo($(this).prev().find(":last-child")) });

  // Remove links on the overview should be hidden until you hover:
  $('#data_summary table').hover(function() {
    $('span.remove').show();
  }, function () {
    $('span.remove').hide();
  }).find('span.remove').hide();

  $('a.button.hidden').hide();

  $('#sortable').sortable({
    placeholder: "placeholder", items: "tr:not(.headers)", helper: 'clone', tolerance: 'pointer',
    update: function() {
      $.post("/known_uris/sort", { known_uris: $("#sortable").sortable('toArray') })
    }
  }).disableSelection();

  /* - TODO - remove this. This is the old version of using ToolTips to handle the definition of URIs.

  // Definitions of attributes:
  $('div.info').each(function() {
    $(this).show();
    // We replace the raw definition (for non-JS users) with a link we'll use as a clickable tooltip:
    $(this).before('<a class="definition hidden" title="'+$(this).html().addClass('icon').replace('"', '&quot;')+'"></a>').html('<a href="#"><img src="/assets/v2/icon_info_tabs.png" height=14 width=14 style="padding-top:3px"/></a>');
  }).find('a').on('click', function() { // Here's where we transform the tooltip to be opened on click instead of hover:
    $('a.definition.hidden').tooltip('close');
    var tip = $(this).parent().prev();
    var nearest = tip.closest('tr').attr('id'); // We need to remember which one is open; click again and it closes.
    if (_TOOLTIP_OPEN == nearest) {
      _TOOLTIP_OPEN = false;
    } else {
      _TOOLTIP_OPEN = nearest;
      tip.tooltip('open');
    }
    return(false);
  });

  // We need to use the content function here to enable HTML:
  $('a.definition.hidden').tooltip({
    items: 'a.definition.hidden',
    show: { effect: 'slideDown', duration: 200 },
    hide: { effect: 'fade', duration: 100 },
    position: { my: "left top", at: "left-170 bottom-5", collision: "flipfit" },
    content: function() { return $(this).attr('title'); }
  });

  */

  // Definitions of Attributes are dialogs if JS is enabled:
  $('tr.first_of_type div.info').each(function() {
    var nearest = $(this).closest('tr').attr('id'); // We need to remember which one is open; click again and it closes.
    var name = $(this).next().html();
    $(this)
      .attr('id', "info_"+nearest)
      .before('<a class="info_icon" data-info="'+nearest+'">&nbsp;</a>')
      .addClass('tip')
      .prepend('<h3>'+name+'</h3>')
      .prepend('<a href="#" class="close">&nbsp;</a>');
    $(this).appendTo(document.body);
  });
 $('a.info_icon') 
    .on('click', function() {
      $('.site_column').unbind('click');
      var $link = $(this);
      var $info = $('#info_'+$(this).attr('data-info'));
      if ($info.is(':visible')) {
        $info.hide('fast');
      } else {
        var pos = $(this).offset();
        $info.css({ top: pos.top + $(this).height() + 26, left: pos.left + $(this).width() });
        $info.show('fast',
          function() {
            $('.site_column').click(function() { $('div.info').hide('fast'); $('.site_column').unbind('click'); });
          }
        ).find('a.close').on('click', function() { $('div.info').hide('fast'); return(false) } );
      }
    });

});
