if (!EOL) { EOL = {}; }
if (!EOL.replace_dato_id) {
  EOL.replace_dato_id = function(link, id) {
    $(link).each(function() {
      new_href = $(this).attr('href').replace(/\/\d+/, '/'+id); // Leading slash avoids replacing params (like star ratings).
      $(this).attr('href', new_href);
    });
  };
}

if (!EOL.handle_main_img_icon) EOL.handle_main_img_icon = function(id) {
  $('#large-image-button-group li.status_icon').hide();
  // This is a little confusing, sorry.  Basically, we look at the thumbnail.  For every icon that is VISIBLE there...
  $('ul[data-data_object_id='+id+'] li:visible').each(function() {
    var classes = $(this).attr('class').split(' ');
    /// ...we look at the class name(s) of that visible icon...
    for (i in classes) {
      if (classes[i] == 'status_icon') { continue; } // ...(and skip this class)...
      // ...and finally show the icon under the main image with the same class name (they are created with the same partial):
      // Note: weird, but true--show() doesn't work... it forces a display that breaks the icon down a line.  This works:
      $('#large-image-button-group li.'+classes[i]).css({display:'inline-block'});
    }
  });
};

$(document).ready(function() {
  // Image pagination:
  $('.mc-navigation a').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      beforeSend: function() {$('#media-images').fadeTo(300, 0.3);},
      success: function(response) {$('#media-images').html(response);},
      error: function() {$('#media-images').html('<p>Sorry, there was an error.</p>');},
      complete: function() {
        $('#media-images').delay(25).fadeTo(100, 1);
        try { EOL.Rating.init_links('#image-ratings'); } catch(e) {} // This isn't availble (or needed) for non-curators
      }
    });
    return false;
  });
  // Show warnings for unvetted thumbnails:
  $("#image-collection img[title]").tooltip();
  // clicking the large image shows its attribution
  $('img.main-image').click(function() {
    $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
  });
  // Clicking on a thumbnail does... a lot:
  $("#thumbnails a").click(function() {
    EOL.close_open_overlays();
    var id = $(this).attr('href');
    $("#notes-container div.mc-notes").hide();
    $("#notes-container #mc-notes-"+id).show();
    $("#large-image .main-image-bg").hide();
    $("#large-image #image-"+id).show();
    $("#image-ratings").show();
    $("#image-ratings .image-rating").hide();
    $("#image-ratings #rating-"+id).show();
    EOL.replace_dato_id('#large-image-attribution-button-popup-link', id);
    EOL.replace_dato_id('#rating-'+id+' a', id);
    EOL.replace_dato_id('#right-image-buttons a.popup-link', id);
    EOL.handle_main_img_icon(id);
    $('.overlay').fadeOut(200);
    return false;
  });
  // Now that everything is set up, click() the selected image (or just the first) to show all of it's information.
  if(!selected_image_id) {
    $("#thumbnails a:nth-child(1)").click();
  } else {
    $("#thumbnails a[href="+selected_image_id+"]").click();
  }
});
