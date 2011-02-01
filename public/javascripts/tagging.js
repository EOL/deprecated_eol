/*
 * Any javascript stuff related to tagging
 *
 * Perhaps shouldn't be in its own file, but I prefer it this way, since there's a lot going on here and I don't want to
 * clutter it with other functions (or vice-versa).
 *
 */
EOL.Tagging = {

  // the id of the DataObject that we're currently tagging
  data_object_id: function() {
    return $('div#public_and_private_data_object_tags input[name=tagging_data_object]').val();
  },

  // the currently selected category (key)
  selected_category: function() {
    var category = $('#tag_key').val();
    if (category == '') { category = 'none'; }
    return category;
  },

  // returns whether or not a valid category (key) is currently selected
  category_selected: function() {
    var cat = EOL.Tagging.selected_category();
    if (cat.length != 1) {
      return true;
    } else {
      return false;
    }
  },

  // The div that the tagging UI on the current page is wrapped in (depending on whether it's in a popup)
  wrapper_div: function() {
    return $('#public_and_private_data_object_tags').parent();
  },

  // reload the tagging UI - pass in the ID of a new DataObject (defaults to the ID of the DataObject we're currently tagging)
  reload: function( data_object_id ) {
    if (data_object_id == null) {
      data_object_id = EOL.Tagging.data_object_id();
    }
    var path = '/data_objects/' + data_object_id + '/tags';
    EOL.Tagging.reload_url(path);
    $('#ajax-indicator-popup').fadeOut();
  },

  // reloaded the tagging UI given a specific URL
  reload_url: function( url, tag_type ) {
    $.ajax({
      url: url,
      beforeSend: function() {$('#ajax-indicator-popup').fadeIn();},
      success: function(response) {$(EOL.Tagging.wrapper_div()).html(response);},
      complete: function() {EOL.Tagging.reload_tagging();}
    });
  },
  
  reload_tagging: function (tag_type) {
    // Create Tag
    $('div#add_data_object_tags_fields>form').unbind('submit');
    $('div#add_data_object_tags_fields>form').submit(function(e) {
      if(!$("#tag_value").val()) {
        $("#tag_error").show();
        return false;
      }
      if($("#tag_error").is(":visible")) $("#tag_error").hide();
      $('#ajax-indicator-popup').fadeIn();
      var key   = EOL.Tagging.selected_category();
      var value = $('#private_data_object_tags input[name="tag[value]"]').val();
      var post_url = $(this).attr('action');
      $.post( post_url, { 'tag[key]': key, 'tag[value]': value }, function(){ EOL.Tagging.reload() } );
      return false;
    });

    // Delete Tag
    $('#private_data_object_tags span.data_object_tag_key_value>form').unbind('submit');
    $('#private_data_object_tags span.data_object_tag_key_value>form').submit(function(e) {
      $('#ajax-indicator-popup').fadeIn();
      var post_url = $(this).attr('action');
      $.post( post_url, { '_method': 'delete' }, function() { EOL.Tagging.reload(); } );
      return false;
    });

    $('#add_data_object_tags_fields input[autocomplete_url]').each(function() {
      var url = $(this).attr('autocomplete_url');
      // tagging auto-complete field
      //
      // options:
      //   matchContains:1,      //also match inside of strings when caching
      //   selectFirst:1,        //select the first item on tab/enter
      //   removeInitialValue:0  //when first applying $.autocomplete
      //
      //  note: we've customized jquery.autocomplete specifically for this form!
      $(this).autocomplete({
        url: url,
        matchContains: 1,
        selectFirst: 1,
        removeInitialValue: 0
      });
    });

    // Ajaxify switching between Public / Private Tags
    $('#public_and_private_data_object_tags div.headers h3 a').unbind('click');
    $('#public_and_private_data_object_tags div.headers h3 a').click(function(e) {
      EOL.Tagging.reload_url(this.href, e.element().id);
      return false;
    });

    // Ajaxifies switching from Public -> Private Tags, given a specific link
    $('#public_and_private_data_object_tags #public_data_object_tags a.tagging-link').unbind('click');
    $('#public_and_private_data_object_tags #public_data_object_tags a.tagging-link').click(function(e) {
      EOL.Tagging.reload_url(this.href);
      return false;
    });

    $('#ajax-indicator-popup').fadeOut();
  }

};

$(document).ready(function() {
  EOL.Tagging.reload_tagging();
});
