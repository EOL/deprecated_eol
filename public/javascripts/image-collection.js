
$(document).ready(function() {
  $('.mc-navigation a').click(function() {
    $.ajax({
      url: $(this).attr('href'),
      beforeSend: function() {$('#media-images').fadeTo(300, 0.3);},
      success: function(response) {$('#media-images').html(response);},
      error: function() {$('#media-images').html('<p>Sorry, there was an error.</p>');},
      complete: function() {$('#media-images').delay(100).fadeTo(100, 1);}
    });
    return false;
  });
  $("#image-collection img[title]").tooltip();
  $("#thumbnails").tabs("#notes-container > div.mc-notes");
  $("#thumbnails a").click(function() {
    var id = $(this).attr('href');
    $("#large-image .main-image-bg").hide();
    $("#large-image #image-"+id).show();
    $("#image-ratings .image-rating").hide();
    $("#image-ratings #rating-"+id).show();
    // Change the HREFs of all the image's links, IF they have an href to replace it in.  :)
    $('#large-image-buttons a').each(function() {
      if(!$(this).attr('href') == undefined) {
        new_href = $(this).attr('href').replace(/\/\d+/, '/'+id);
        $(this).attr('href', new_href);
      }
    });
    $('.overlay').fadeOut(200);
  });
  // click() the selected image, or just the first.
  if(!selected_image_id) {
    $("#thumbnails a:nth-child(1)").click();
  } else {
    $("#thumbnails a[href="+selected_image_id+"]").click();
  }
  $("#image-ratings").show(); // Now that we've only got one showing, we can unhide the ratings (without this, it's ugly).
  // clicking the large image shows its attribution
  $('img.main-image').click(function() {
    $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
  });
});
