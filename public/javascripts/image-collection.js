if (!EOL) EOL = {};
if (!EOL.replace_dato_id) EOL.replace_dato_id = function(link, id) {
  new_href = $(link).attr('href').replace(/\/\d+/, '/'+id); // Leading slash avoids replacing params (like star ratings).
  $(link).attr('href', new_href);
};

$(document).ready(function() {
  // Image pagination:
  $('.mc-navigation a').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      beforeSend: function() {$('#media-images').fadeTo(300, 0.3);},
      success: function(response) {$('#media-images').html(response);},
      error: function() {$('#media-images').html('<p>Sorry, there was an error.</p>');},
      complete: function() {$('#media-images').delay(25).fadeTo(100, 1);}
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
