function undo_move(opts) {
  opts.node.unbind();
  var data_object_id = opts.node.parent().parent().attr('id').substring(10);
  var data = "data_object_id=" + data_object_id
  $.ajax({type: opts.method, url: '/user_ignored_data_objects/' + opts.action, data: data, success: function(){
    $('#undo-move-' + data_object_id).addClass('hide');
    $('#curation-item-' + data_object_id).removeClass('hide');
    opts.node.click(function() { undo_move(opts)});
  } });
}

function toggle_ignore(opts) {
  opts.node.unbind();
  var data_object_id = opts.node.parent().attr('id').substring(7);
  var data = "data_object_id=" + data_object_id
  $.ajax({type: opts.method, url: '/user_ignored_data_objects/' + opts.action, data: data, success: function(){
    $('#undo-move-' + data_object_id).removeClass('hide');
    $('#curation-item-' + data_object_id).addClass('hide');
    opts.node.click(function() { toggle_ignore(opts)});
  } });
}

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

$('a.undo-restore-image').click(function() { undo_move({ node: $(this), method: "POST", action: "create" })});

$('a.undo-ignore-image').click(function() { undo_move({ node: $(this), method: "DELETE", action: "destroy" })});

$('.is_ignored_false').find('.action-value').find('a').click(function() { toggle_ignore({ node: $(this), method: 'POST', action: 'create' })});

$('.is_ignored_true').find('.action-value').find('a').click(function() { toggle_ignore({ node: $(this), method: 'DELETE', action: 'destroy' })});

