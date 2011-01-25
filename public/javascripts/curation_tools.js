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

function change_comment_icon_tooltip(data) {
  var pluralize_comments = data.comments == "1" ? '. ' : 's. ';
  var pluralize_current_user_comments = data.current_user_comments == "1" ? ' is' : ' are';
  $('#comment_button_link_' + data.data_object_id).parent().attr('title', data.comments + ' comment' + pluralize_comments + data.current_user_comments + pluralize_current_user_comments + ' yours. Add a comment');
};

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
  $.post($(this).attr('action'), $(this).serialize(), function(data) {
    // TODO - move this to rjs... once we can use jQuery.  :\
    data = jQuery.parseJSON(data);
    $(form_element).children().not(':submit, :hidden').val(''); // reset the form
    $(form_element).after('<p id="remove-me" class="submitted">You added new comment:<br/>' + data.last_comment + '</p>');
    $(form_element).parent().children('#remove-me').fadeOut(15000);
    change_comment_icon_tooltip(data);
    $('#comment_button_link_' + data.data_object_id + ' .span_block').html(data.comments);
  },'JSON');
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

$(document).ready(function() {
  $('.curator_worklist_curation input').click(function() {
    if ($(this).attr('data_href')) {
      var selected = $(this);
      var curation_comment = "";
      if (selected.parent().children('.curation-comment-box').is(":visible")) { 
        curation_comment = selected.parent().children('.curation-comment-box').val();
      }
      var untrust_reason_ids = selected.parent().children('.option').children(':checked').map(function(){return this.value}).get();
      var untrust_reasons_comment = "";
      var untrust_data = "";
      if (untrust_reason_ids != "") {
        untrust_reasons_comment = "Reasons to Untrust:\n\n" + selected.parent().children('.option').children(':checked').siblings().map(function(){return this.innerHTML}).get().join(",\n");
      }
      if(untrust_reason_ids || curation_comment) {
        untrust_data = "untrust_reasons_comment=" + encodeURI(untrust_reasons_comment) + "&untrust_reason_ids=" + untrust_reason_ids + "&comment=" + encodeURI(curation_comment);
      }
      
      $.ajax({
        url: $(this).attr('data_href'),
        beforeSend: function(xhr) {
          if(selected.parent().attr('class')==("reason")){
            if((selected.parent().children(".curation-comment-box").val() == "") && (untrust_reason_ids == "")) {
              selected.parent().find('b').show().css("color","red");
              return false;
            } else {
              selected.parent().find('b').show().css("color","black");
              selected.parent().children('.curation-comment-box').val("");
              return true;
            }
          } else {
            selected.parent().siblings().find('b').show().css("color","black");
            return true;
          }
        },
        data: untrust_data, 
      });
    }
  });
});
