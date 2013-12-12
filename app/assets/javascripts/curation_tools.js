// function undo_move(opts) {
//   opts.node.unbind();
//   var data_object_id = opts.node.parent().parent().attr('id').substring(10);
//   var data = "data_object_id=" + data_object_id
//   $.ajax({type: opts.method, url: '/user_ignored_data_objects/' + opts.action, data: data, success: function(){
//     $('#undo-move-' + data_object_id).addClass('hide');
//     $('#curation-item-' + data_object_id).removeClass('hide');
//     opts.node.on('click', function() { undo_move(opts)});
//   } });
// }
// 
// function toggle_ignore(opts) {
//   opts.node.unbind();
//   var data_object_id = opts.node.parent().attr('id').substring(7);
//   var data = "data_object_id=" + data_object_id
//   $.ajax({type: opts.method, url: '/user_ignored_data_objects/' + opts.action, data: data, success: function(){
//     $('#undo-move-' + data_object_id).removeClass('hide');
//     $('#curation-item-' + data_object_id).addClass('hide');
//     opts.node.on('click', function() { toggle_ignore(opts)});
//   } });
// }

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

// $('a.undo-restore-image').on('click', function() { undo_move({ node: $(this), method: "POST", action: "create" })});
// 
// $('a.undo-ignore-image').on('click', function() { undo_move({ node: $(this), method: "DELETE", action: "destroy" })});
// 
// $('.is_ignored_false').find('.action-value').find('a').on('click', function() { toggle_ignore({ node: $(this), method: 'POST', action: 'create' })});
// 
// $('.is_ignored_true').find('.action-value').find('a').on('click', function() { toggle_ignore({ node: $(this), method: 'DELETE', action: 'destroy' })});
