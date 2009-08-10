if(!EOL) var EOL = {};
if(!EOL.Comments) EOL.Comments = {};

EOL.Comments.Behaviors = {
  'div#large-image-comment-button-popup-link_popup a.close-button:click': function(e) {
    EOL.popups["large-image-comment-button-popup-link_popup"].toggle();
  }
};