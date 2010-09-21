$j('ul.small-star li a').click(function() {
  $j.post($j(this).attr('href'));
  EOL.Rating.update_user_image_rating($j(this).attr('data-data_object_id'), $j(this).text());
});

$j('form.comment').submit(function() {
  form_element = this
  $j.post($j(this).attr('action'), $j(this).serialize(), function() {
    // TODO - move this to rjs... once we can use jQuery.  :\
    $j(form_element).children().not(':submit, :hidden').val(''); // reset the form
    $j(form_element).after('<p id="remove-me" class="submitted">Submitted.</p>');
    $j(form_element).parent().children('#remove-me').fadeOut(5000);
  });
  return false;
});

$j('.untrust_reasons input').click(function() {
  $j.post($j(this).attr('action'), $j(this).serialize());
});
