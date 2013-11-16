// function undo_move(opts) {
//   opts.node.unbind();
//   var data_object_id = opts.node.parent().parent().attr('id').substring(10);
//   var data = "data_object_id=" + data_object_id
//   $.ajax({type: opts.method, url: '/user_ignored_data_objects/' + opts.action, data: data, success: function(){
//     $('#undo-move-' + data_object_id).addClass('hide');
//     $('#curation-item-' + data_object_id).removeClass('hide');
//     opts.node.click(function() { undo_move(opts)});
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
//     opts.node.click(function() { toggle_ignore(opts)});
//   } });
// }
function change_comment_icon_tooltip(e){var t=e.comments=="1"?". ":"s. ",n=e.current_user_comments=="1"?" is":" are";$("#comment_button_link_"+e.data_object_id).parent().attr("title",e.comments+" comment"+t+e.current_user_comments+n+" yours. Add a comment")}$(function(){$(".overlay_link a[rel]").overlay({onBeforeLoad:function(){var e=this.getOverlay().find(".content-wrap");e.text(""),e.append("<h2>Loading, please wait...</h2>"),e.load(this.getTrigger().attr("href"))}})});