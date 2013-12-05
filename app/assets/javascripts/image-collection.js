if (!EOL) { EOL = {}; }
if (!EOL.replace_dato_id || !EOL.click_selected_image || !EOL.toggle_main_img_icons || !EOL.init_image_collection_behaviors) {
  EOL.replace_dato_id = function(id) {
    $('#right-image-buttons a.popup-link, #rating-'+id+' a, #large-image-attribution-button-popup-link').each(function() {
      new_href = $(this).attr('href').replace(/data_objects\/\d+/, 'data_objects/'+id);
      $(this).attr('href', new_href);
    });
  };

  EOL.click_selected_image = function() {
    // If there is no slected image, just click the first one:
    if(!typeof selected_image_id === "undefined") {
      if(!selected_image_id) {
        $("#thumbnails a:nth-child(1)").click();
      } else {
        $("#thumbnails a#thumb-"+selected_image_id).click();
      }
    }
  };

  EOL.toggle_main_img_icons = function(id) {
    $('#large-image-button-group li.status_icon').hide();
    // This is a little confusing, sorry.  Basically, we look at the thumbnail for the image we're showing.
    // For every icon that is VISIBLE on the thumbnail, we make that same icon visible on the large image.
    $('ul[data-data_object_id='+id+'] li:visible').each(function() {
      var classes = $(this).attr('class').split(' ');
      /// ...we look at the class name(s) of that visible icon...
      for (var i in classes) {
        if (classes[i] == 'status_icon') { continue; } // ...(and skip this class)...
        // ...and finally show the icon under the main image with the same class name (they are created with the same partial):
        // Note: weird, but true--show() doesn't work... it forces a display that breaks the icon down a line.  This works:
        $('#large-image-button-group li.'+classes[i]).css({display:'inline-block'});
      }
    });
  };

  EOL.init_image_collection_behaviors = function() {
    // Image pagination:
    $('.mc-navigation a').on('click', function() {
      $.ajax({
        url: $(this).attr('href'),
        beforeSend: function() {EOL.close_open_overlays(); $('#media-images').fadeTo(300, 0.3);},
        success: function(response) {$('#media-images').html(response);},
        error: function() {$('#media-images').html('<p>Sorry, there was an error.</p>');},
        complete: function() {
          // Removing the filter after fading in; IE7 does not anti-alias fonts that are filtered.
          $('.tooltip').hide(); // hides the 'images in yellow...' tooltip
          $('#media-images').delay(25).fadeTo(100, 1, function() {$('#media-images').css({filter:''});});
          try { EOL.Rating.init_links('#image-ratings'); } catch(e) {} // This isn't availble (or needed) for non-curators
          EOL.init_popup_overlays(); // This *needs* to be available.
          EOL.click_selected_image(); // TODO - is this duplicated?
        }
      });
      return false;
    });
    // Show warnings for unvetted thumbnails:
    $("#image-collection img[title]").tooltip();
    // clicking the large image shows its attribution
    $('img.main-image').on('click', function() {
      $('#large-image-attribution-button-popup-link').click(); // "click" the PopupLink
    });
    // Clicking on a thumbnail does... a lot:
    $("#thumbnails a").on('click', function() {
      EOL.close_open_overlays();
      var id = $(this).attr('href').replace(/^.*\/(\d+)/, '$1');
      $('.overlay').fadeOut(200);
      $("#notes-container div.mc-notes, #large-image .main-image-bg, #image-ratings .image-rating").hide();
      $("#notes-container #mc-notes-"+id+", #large-image #image-"+id+", #image-ratings, #image-ratings #rating-"+id).show();
      $("#large-image-comment-button .comment_button").hide();
      $("#large-image-comment-button #comment_button_id_"+id).show();
	  $("#large-image-comment-button").removeClass("hide");
      EOL.replace_dato_id(id);
      EOL.toggle_main_img_icons(id);
      EOL.init_popup_overlays();
      EOL.toggle_photosynth_icon(id);
      return false;
    });
    EOL.click_selected_image();
  };
  
  EOL.toggle_photosynth_icon = function(id) {
    var source_url = $("#mc-notes-"+id+" a.source_url").attr('href');
    if(source_url == undefined || source_url.search(/photosynth.net/) == -1) { //regular static image    
      $("#photosynth-message").html("");
      $("#photosynth-message").unbind('click');
    } else { //photosynth image
      $("#photosynth-message").html("<img src='http://mslabs-999.vo.llnwd.net/e1/inc/images/master/logo.png' height='27' alt='Photosynth' title='Image is part of a Photosynth'/>");
      $("#photosynth-message").on('click', function() {
        $("#large-image #image-"+id+" td").html("<iframe frameborder='0' src='" + source_url.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe>");
      });
    }
  };
}

$(document).ready(function() {
  EOL.init_image_collection_behaviors();
});

