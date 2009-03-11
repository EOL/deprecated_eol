if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {};

EOL.TextObjects.Behaviors = {
  'li.add_text a, div.add_text_button a': function(e) {
    new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});
  }
};
