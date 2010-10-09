if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

// Update the image(s) now that it's been curated:
EOL.Curation.post_curate_image = function(dato_id, visibility_id, vetted_id) {
  thumbnail = $('#thumbnails a[href='+dato_id+']')
  image = $('#image-'+dato_id+' table')
  thumbnail.removeClass('trusted unknown untrusted');
  image.removeClass('trusted unknown untrusted');
  if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    thumbnail.addClass('untrusted');
    image.addClass('untrusted');
  } else if (vetted_id == EOL.Curation.UNKNOWN_ID) {
    thumbnail.addClass('unknown');
    image.addClass('unknown');
  } else {
    thumbnail.addClass('trusted');
    image.addClass('trusted');
  }
};
// Update text objects after curation:
EOL.Curation.post_curate_text = function(data_object_id, visibility_id, vetted_id) {
  $('div#text_buttons_'+data_object_id+' div.trust_button').remove();
  $('div#text_buttons_'+data_object_id+' div.untrust_button').remove();
  EOL.Curation.update_text_background(data_object_id, vetted_id);
  EOL.Curation.update_text_icons(data_object_id, visibility_id);
};
// Yellow/Red bg for text objects:
EOL.Curation.update_text_background = function(data_object_id, vetted_id) {
  $('#text_'+data_object_id).removeClass('untrusted unknown trusted');
  if (vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('#text_'+data_object_id).addClass('untrusted');
  }
}
// Invisible icons on text:
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
  $('div.vetted .untrust input[type="radio"]').click(function() {
    $(this).parent().find('div.reason').slideDown();
  });
  // Hide untrust reasons when it's trusted:
  $('div.vetted .trust input[type="radio"]').click(function() {
    $(this).parent().find('div.reason').slideUp();
  });
  // Cancel button just clicks the closest close-link:
  $('form.curation .cancel-button').click(function() {
    $(this).closest('div.overlay, div.text-slidebox-container').find('a.close, a.close-button').click();
  });
  // Text curation isn't an overlay, so we need to manually make the close link work:
  $('div.text_curation_close a.close-button').click(function() {
    $(this).parent().parent().parent().slideUp();
  });
});
