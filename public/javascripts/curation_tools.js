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

$('form.comment').submit(function() {
  form_element = this;
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


$('.is_ignored_false').find('.action-value').find('a').click(function() {
  
  var parent_div = $('.is_ignored_false');
  var link = $(this);
  var div_id = link.parent().attr('id');
  var data_object_id = div_id.substring(7);
  var data = "div_id=" + div_id + "&data_object_id=" + data_object_id
  $.ajax({type: "POST", url: '/user_ignored_data_objects/create', data: data, success: function(){
     parent_div.removeClass('is_ignored_false');
     parent_div.addClass('is_ignored_true');
     link.text("Move to active");
     link.parent().find('.info_msg').text(' (will be hidden on reload)');
     link.parent().parent().find('.credit-caption').text('Ignored');
  } });
});

$('.is_ignored_true').find('.action-value').find('a').click(function() {
  
  var parent_div = $('.is_ignored_true');
  var link = $(this);
  var div_id = link.parent().attr('id');
  var data_object_id = div_id.substring(7);
  var data = "data_object_id=" + data_object_id
  $.ajax({type: "DELETE", url: '/user_ignored_data_objects/destroy', data: data, success: function(){
     parent_div.removeClass('is_ignored_true');
     parent_div.addClass('is_ignored_false');
     link.text("Move to ignored list");
     link.parent().find('.info_msg').text(' (will be hidden on reload)');
     link.parent().parent().find('.credit-caption').text('Active');
  } });
});

