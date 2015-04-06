$(function(){
  var $targetImage = $('#permalink img:first');
  var $cropForm = $('#crop_form form');

  $targetImage.Jcrop({
    onChange: showPreview,
    onSelect: updatePreviewForm,
    onRelease: resetPreview,
    minSize: [ 50, 50 ],
    addClass: 'auto_margin',
    aspectRatio: 1
  });

  $targetImage.closest('a').on('click', function(e) {
      e.preventDefault();
  });

  $cropForm.submit(function() {
    return checkCoords();
  });

  function showPreview(coords)
  {
    if (parseInt(coords.w) > 0)
    {
      $('#crop_panel .crop_preview img').each(function(){
        var rx = $(this).parent().width() / coords.w;
        var ry = $(this).parent().width() / coords.h;
        $(this).attr('src', $targetImage.attr('src'));
        $(this).css({
          width: Math.round(rx * $targetImage.width()) + 'px',
          height: Math.round(ry * $targetImage.height()) + 'px',
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
    var w = $targetImage[0].naturalWidth;
    var h = $targetImage[0].naturalHeight;
    if (typeof w == 'undefined') {
      // IE 6/7/8 doesn't define naturalWidth etc, 
      // so load up a hidden copy to get the original widths
	  var newImg = new Image();
	  newImg.onload = function() {fillForm(this.width, this.height, coords);};
	  newImg.src = $targetImage[0].src;
    } else {
      fillForm(w, h, coords);
    }
  }
  
  function fillForm(w,h,c)
  {
    //EoL specific: express crop as % not px, as large images may be shrunk
    // Offsets are from the 580 x 360 image. However, if they are wider than 
    // 540px, the EoL CSS scales the image proportionally to fit into a max 
    // width of 540. %ages thus need scaling to match the image dimensions
    var scaleFactor = 1;
    if((w / h) < ( 540 / 360 ))
    {
      //smaller width, so scaling only happens if height exceeds max
      if(h > 360) scale_factor = h / 360;
    } else  {
      //smaller height, so scaling only happens if width exceeds max
      if(w > 540) scale_factor = w / 540;
    }
    $cropForm.children('[name="x"]').val(100.0 * c.x * scaleFactor/w);
    $cropForm.children('[name="y"]').val(100.0 * c.y * scaleFactor/h);
    $cropForm.children('[name="w"]').val(100.0 * c.w * scaleFactor/w);
    //$cropForm.children('[name="h"]').val(100.0 * c.h * scaleFactor/h); //only needed for non-square crops
  }
  
  function checkCoords()
  {
    if (parseInt($cropForm.children('[name="w"]').val())>0) return true;
    alert('Please select a crop region in the larger image, then press "crop image".');
    return false;
  }

});
