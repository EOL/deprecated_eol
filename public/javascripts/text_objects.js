if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {};

EOL.TextObjects.Behaviors = {
  'li.add_text a, div.add_text_button a': function(e) {
    new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});
  },

  '#data_objects_toc_category_toc_id:change': function(e) {
    if(this.value==='new') {
      $('existing_toc').hide();
      $('new_toc').show();
    }
  },

  '#new_toc a:click': function(e) {
    $$('#existing_toc select')[0].selectedIndex = 0;
    $('existing_toc').show();
    $('new_toc').hide();
    return false;
  }
};
