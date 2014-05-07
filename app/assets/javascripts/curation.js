if(!EOL) { EOL = {}; }
if(!EOL.Curation) { EOL.Curation = {}; }

EOL.Curation.form_is_valid = function(form) {
  var untrusted_option_checked  = $('#' + form.data('data-object-id') + '_vetted_id_' + EOL.Curation.UNTRUSTED_ID).is(':checked');   
  var comment_empty             = form.find('.curation-comment-box').val() === "";
  var untrust_reasons_unchecked = form.find('.untrust_reason:checked').siblings().map(function(){return this.innerHTML;}).get() === ''; 
  return untrusted_option_checked ? !(comment_empty && untrust_reasons_unchecked) : true; 
};

// Invisible icons on text:
EOL.Curation.update_icons = function(data_object_id, visibility_id) {
  $('ul[data-data-object-id='+data_object_id+'] li.invisible_icon').hide();
  $('ul[data-data-object-id='+data_object_id+'] li.inappropriate_icon').hide();
  // NOTE: show() doesn't work for image thumbnails, because the diplay ends up with the wrong value.
  if(visibility_id == EOL.Curation.INVISIBLE_ID) {
    $('ul[data-data-object-id='+data_object_id+'] li.invisible_icon').css({display: 'inline-block'});
  } else if(visibility_id == EOL.Curation.INAPPROPRIATE_ID) {
    $('ul[data-data-object-id='+data_object_id+'] li.inappropriate_icon').css({display: 'inline-block'});
  }
};
// Update the image(s) now that it's been curated:
EOL.Curation.post_curate_image = function(args, page_type) {
  var dato_id = args[0]; var visibility_id = args[1];
  var vetted_id = args[2];
  var vetted_label = EOL.Curation.vetted_type[vetted_id];
  if (page_type == 'species_page') {
    EOL.Curation.update_icons(dato_id, visibility_id);
    EOL.toggle_main_img_icons(dato_id);
    thumbnail = $('#thumbnails a#thumb-'+dato_id);
    image_wrap = $('#image-'+dato_id);
    notes = $('#mc-notes-'+dato_id);
    classes = 'trusted unknown untrusted unknown-text untrusted-text trusted-text';
    thumbnail.removeClass(classes).addClass(vetted_label);
    image_wrap.removeClass(classes).addClass(vetted_label);
    notes.removeClass(classes).addClass(vetted_label + '-text');
  } else {
    var div_id = $('#' + dato_id + '_vetted_id_' + vetted_id);
    var undo_move = $('#undo-move-' + dato_id);
    div_id.parents('td').removeClass('unknown untrusted trusted').addClass(vetted_label);
    div_id.parents('td').siblings('td').removeClass('unknown untrusted trusted').addClass(vetted_label);
    undo_move.removeClass('unknown untrusted trusted').addClass(vetted_label);
  }
};
// Update text objects after curation:
EOL.Curation.post_curate_text = function(args, page_type) {
  var data_object_id = args[0]; var visibility_id = args[1];
  var vetted_id = args[2];
  if (page_type == 'species_page') {
    $('div#text_buttons_'+data_object_id+' div.trust_button').remove();
    $('div#text_buttons_'+data_object_id+' div.untrust_button').remove();
    $('#text_'+data_object_id).removeClass('untrusted unknown trusted');
    if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
      $('#text_'+data_object_id).addClass('untrusted');
    } else if (vetted_id == EOL.Curation.UNKNOWN_ID) {
      $('#text_'+data_object_id).addClass('unknown');
    }
    EOL.Curation.update_icons(data_object_id, visibility_id);
  }
};

$(document).ready(function() {
  $('form.curation_form input[type="submit"]').on('click', function() {
    var form = $(this).closest('form');
    var page_type = form.data('page_type');
    form.find('div.processing').show();
    submit = form.find(':submit');
    the_comment = form.find('textarea');
    $.ajax({
      url: form.attr('action'),
      type: 'PUT',
      dataType: 'json',
      beforeSend: function(xhr) {
      if(EOL.Curation.form_is_valid(form)) {
          xhr.setRequestHeader("Accept", "text/javascript"); // Sorry, not sure why this xhr wasn't auto-js, but it wasn't.
          submit.attr('disabled', 'disabled');
          the_comment.attr('disabled', 'disabled');
        } else {
          form.find('.untrust_reason').parent().parent().find('b').show().css("color","red");
          form.find('div.processing').fadeOut();
          return false;
        }
      },
      complete: function() {
        submit.attr('disabled', '');
        the_comment.attr('disabled', '');
        form.find('div.processing').fadeOut();
        form.find('.untrust_reason').parent().parent().find('b').show().css("color","black");
      },
      success: function(response) {
        $('#comment_button_link_' + response.args[0] + ' .span_block').html(response.args[4]);
        // Show the Comments container if comments are submitted or vetted the dato as untrusted
        if (form.find('.reason').siblings("input").attr("checked") || the_comment.val()) {
          $('#comment_button_link_' + response.args[0]).click();
        }
        the_comment.val('');
        if (response.type == "text") {
          EOL.Curation.post_curate_text(response.args, page_type);
        } else {
          EOL.Curation.post_curate_image(response.args, page_type);
        }
      },
      data: $(form).serialize()
    });
    return false;
  });
  // Show untrust reasons when it's ... uhhh.... untrusted. 
  $('div.vetted .untrust input[type="radio"]').on('click', function() {
    $(this).parent().find('.untrust_reason').parent().parent().find('b').show().css("color","black");
    $(this).parent().find('div.reason').slideDown();
  });
  // Hide untrust reasons when it's trusted:
  $('div.vetted .trust input[type="radio"]').on('click', function() {
    $(this).parent().parent().find('div.reason').slideUp();
  });
  // Hide untrust reasons when it's unreviewed:
  $('div.vetted .unreviewed input[type="radio"]').on('click', function() {
    $(this).parent().parent().find('div.reason').slideUp();
  });
  // Cancel button just clicks the closest close-link:
  $('form.curation .cancel-button').on('click', function() {
    $(this).closest('div.overlay, div.text-slidebox-container').find('a.close, a.close-button').click();
  });
  // Text curation isn't an overlay, so we need to manually make the close link work:
  $('div.text_curation_close a.close-button').on('click', function() {
    $(this).parent().parent().parent().slideUp();
  });
  // Curation of classifications: show all classifications if they start splitting / moving:
  $('td.show_all input').on('click', function(e) {
    var $show_all_link = $('#show_other_classifications');
    window.location = $show_all_link.attr('href') + "&split_hierarchy_entry_id[]=" + $(e.target).val();
    $('div.main_container').children().fadeOut(function() {$('#please_wait').fadeIn();});
  });
  // Check all checkboxes when you check the header:
  $('th.check_all:not(:has(input))').append('<input class="check_all_from_header" type="checkbox"/>');
  $('input.check_all_from_header').on('click', function(e) {
    $(e.target).closest('table').find('td input[type=checkbox]').attr('checked', $(e.target).is(':checked'));
  });
});
