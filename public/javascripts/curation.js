if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

EOL.Curation.post_curate_text = function(data_object_id, visibility_id, vetted_id) {
  $('div#text_buttons_'+data_object_id+' div.trust_button').remove();
  $('div#text_buttons_'+data_object_id+' div.untrust_button').remove();
  EOL.Curation.update_text_background(data_object_id, vetted_id);
  EOL.Curation.update_text_icons(data_object_id, visibility_id);
};

EOL.Curation.post_curate_image = function(data_object_id, visibility_id, vetted_id) {
  EOL.MediaCenter.image_hash[data_object_id].vetted_id = vetted_id;
  EOL.MediaCenter.image_hash[data_object_id].visibility_id = visibility_id;
  EOL.MediaCenter.image_hash[data_object_id].curated = true;
  // TODO - this may need some updating of what they changed, now.
  EOL.Curation.update_thumbnail_background(vetted_id, data_object_id);
  EOL.MediaCenter.update_thumbnail_icons($('div#thumbnails a#thumbnail_'+data_object_id+' ul'));
};

EOL.Curation.update_thumbnail_background = function(vetted_id, data_object_id) {
  $('#thumbnail_'+data_object_id).removeClass('trusted-background-image');
  $('#thumbnail_'+data_object_id).removeClass('unknown-background-image');
  $('#thumbnail_'+data_object_id).removeClass('untrusted-background-image');
  if(vetted_id == EOL.Curation.TRUSTED_ID) {
    //no background
  } else if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('#thumbnail_'+data_object_id).addClass('untrusted-background-image');
  } else if (vetted_id == EOL.Curation.UNKNOWN_ID) {
    $('#thumbnail_'+data_object_id).addClass('unknown-background-image');
  }
};

EOL.Curation.update_text_background = function(data_object_id, vetted_id) {
  $('#text_'+data_object_id).removeClass('untrusted-background-image');
  $('#text_'+data_object_id).removeClass('unknown-background-image');
  $('#text_'+data_object_id).removeClass('trusted-background-image');
  if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('#text_'+data_object_id).addClass('untrusted-background-image');
  }
}

EOL.Curation.update_text_icons = function(data_object_id, visibility_id) {
  $('div#text_buttons_'+data_object_id+' ul li.invisible_icon').hide();
  $('div#text_buttons_'+data_object_id+' ul li.inappropriate_icon').hide();

  if(visibility_id == EOL.Curation.INVISIBLE_ID) {
    $('div#text_buttons_'+data_object_id+' ul li.invisible_icon').show();
  } else if(visibility_id == EOL.Curation.INAPPROPRIATE_ID) {
    $('div#text_buttons_'+data_object_id+' ul li.inappropriate_icon').show();
  }
};

$(document).ready(function() {
  $('form.curation input[type="submit"]').click(function() {
    var form = $(this).closest('form');
    form.find('div.processing').show();
    $.ajax({
      url: form.attr('action'),
      type: 'PUT',
      beforeSend: function(xhr) {
        xhr.setRequestHeader("Accept", "text/javascript"); // Sorry, not sure why this xhr wasn't auto-js, but it wasn't.
        form.find(':submit').attr('disabled', 'disabled');
      },
      complete: function() {
        form.find(':submit').attr('disabled', '');
        form.find('div.processing').fadeOut();
      },
      data: $(form).serialize()
    });
    return false;
  });
  // Show untrust reasons when it's ... uhhh.... untrusted. 
  $('div.vetted div.untrusted div input[type="radio"]').click(function() {
    $(this).parent().parent().find('div.reason').slideDown();
  });
  // Hide untrust reasons when it's trusted:
  $('div.vetted div.trusted input[type="radio"]').click(function() {
    $(this).parent().parent().find('div.reason').slideUp();
  });
  // Cancel button just clicks the closest close-link:
  $('form.curation .cancel-button').click(function() {
    $(this).closest('div.overlay, div.text-slidebox-container').find('a.close, a.close-button').click();
  });
  // Text curation isn't an overlay, so we need to manually make the close link work:
  $('div.text_curation_close a.close-button').click(function() {
    $(this).parent().parent().parent().fadeOut();
  });
});
