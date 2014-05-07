$(function(){
  var $target_image = $('#permalink img:first');
  var $crop_form = $('#crop_form form');

  $target_image.Jcrop({
    onChange: showPreview,
    onSelect: showPreview,
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
    updatePreviewForm(coords);
  }

  function resetPreview()
  {
    $('#crop_panel .crop_preview img').each(function(){
      $(this).stop();
      $(this).attr('style', '');
      $(this).attr('src', $(this).attr('original_src'));
    });
  }

  function updatePreviewForm(c)
  {
    $crop_form.children('[name="x"]').val(c.x);
    $crop_form.children('[name="y"]').val(c.y);
    $crop_form.children('[name="w"]').val(c.w);
    $crop_form.children('[name="h"]').val(c.h);
  }

  function checkCoords()
  {
    if (parseInt($crop_form.children('[name="w"]').val())>0) return true;
    alert('Please select a crop region in the larger image, then press "crop image".');
    return false;
  }

});

