$(function() {
  $(".overlay_link a[rel]").overlay({
    onBeforeLoad: function() {
      var wrap = this.getOverlay().find(".content-wrap");
      wrap.text('');
      wrap.append('<h2>Loading, please wait...</h2>');
      wrap.load(this.getTrigger().attr("href"));
    }
  });
});

$('ul.small-star li a').click(function() {
  $.post($(this).attr('href'));
  EOL.Rating.update_user_image_rating($(this).attr('data-data_object_id'), $(this).text());
});

$('form.comment').submit(function() {
  form_element = this
  $.post($(this).attr('action'), $(this).serialize(), function() {
    // TODO - move this to rjs... once we can use jQuery.  :\
    $(form_element).children().not(':submit, :hidden').val(''); // reset the form
    $(form_element).after('<p id="remove-me" class="submitted">Submitted.</p>');
    $(form_element).parent().children('#remove-me').fadeOut(5000);
  });
  return false;
});

$('.untrust_reasons input').click(function() {
    alert('start');
  form = $(this).parent().parent().parent();
  $.post(form.attr('action'), form.serialize());
    alert('stop');
});
