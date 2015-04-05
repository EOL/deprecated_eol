$(function(){
  var $target_image = $('#permalink img:first');
  var $crop_form = $('#crop_form form');

  $target_image.Jcrop({
    onChange: showPreview,
    onSelect: updatePreviewForm,
    onRelease: resetPreview,
    minSize: [ 50, 50 ],
    addClass: 'auto_margin',
    aspectRatio: 1
  });

  $target_image.closest('a').on('click', function(e) {
      e.preventDefault();
  });

  $crop_form.submit(function() {
    return checkCoords();
  });

  function showPreview(coords)
  {
    if (parseInt(coords.w) > 0)
    {
      $('#crop_panel .crop_preview img').each(function(){
        var rx = $(this).parent().width() / coords.w;
        var ry = $(this).parent().width() / coords.h;
        $(this).attr('src', $target_image.attr('src'));
        $(this).css({
          width: Math.round(rx * $target_image.width()) + 'px',
          height: Math.round(ry * $target_image.height()) + 'px',
          marginLeft: '-' + Math.round(rx * coords.x) + 'px',
          marginTop: '-' + Math.round(ry * coords.y) + 'px',
          visibility: 'visible'
        }).show();
        
      });
    }
  }

  function resetPreview()
  {
    $('#crop_panel .crop_preview img').each(function(){
      $(this).stop();
      $(this).attr('style', '');
      $(this).attr('src', $(this).attr('original_src'));
    });
  }

  function updatePreviewForm(coords)
  {
    var w = $target_image[0].naturalWidth;
    var h = $target_image[0].naturalHeight;
    if (typeof w == "undefined") {
      // IE 6/7/8 doesn't define naturalWidth etc, so load up a hidden copy to get the orig widths
	  var newImg = new Image();
	  newImg.onload = function() {fillForm(this.width, this.height, coords);};
	  newImg.src = $target_image[0].src;
    } else {
      fillForm(w, h, coords);
    }
  }
  
  function fillForm(w,h,c)
  {
    //EoL specific: export the crop as percentages, since large images may be shrunk
    // Offsets are from the 580 x 360 image. However, if they are wider than 
    // 540px, the EoL CSS scales the image proportionally to fit into a max width of 540.
    // The offsets and width need to be scaled to match the image dimensions
    var scale_factor = 1;
    if((w / h) < ( 540 / 360 ))
    {
      //smaller width, so scaling only happens if height exceeds max
      if(h > 360) scale_factor = h / 360;
    } else  {
      //smaller height, so scaling only happens if width exceeds max
      if(w > 540) scale_factor = w / 540;
    }
    $crop_form.children('[name="x"]').val(100.0 * c.x * scale_factor/w);
    $crop_form.children('[name="y"]').val(100.0 * c.y * scale_factor/h);
    $crop_form.children('[name="w"]').val(100.0 * c.w * scale_factor/w);
    //$crop_form.children('[name="h"]').val(100.0 * c.h * scale_factor/h); //only needed for non-square crops
  }
  
  function checkCoords()
  {
    if (parseInt($crop_form.children('[name="w"]').val())>0) return true;
    alert('Please select a crop region in the larger image, then press "crop image".');
    return false;
  }

});
