if(!EOL) var EOL = {};
if(!EOL.TextObjects) EOL.TextObjects = {};

EOL.TextObjects.Behaviors = {
  'li.add_text a, div.add_text_button a': function(e) {
    new EOL.PopupLink(this,{insert_after:'insert_text', additional_classes:'insert_text'});
  },

  'div#insert_text_popup form:submit': function(e) {
    EOL.TextObjects.remove_preview();
    if($$('form#new_data_object textarea')[0].value.strip() == '') {
      $('missing_text_error').show();
      Effect.Pulsate('missing_text_error');
      return false;
    }

    new Ajax.Request(this.action,
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'post',
                       parameters:Form.serialize(this)
                     });
                     
    return false;
  },

  'input#preview_text:click': function(e) {
    EOL.TextObjects.remove_preview();
    form = $('new_data_object')
    new Ajax.Request(form.action+'/preview',
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'post',
                       parameters:Form.serialize(form)
                     });

    return false;
  }
};

EOL.TextObjects.insert_new_text = function(text) {
  EOL.popups["insert_text_popup"].hide();
  Element.insert("insert_text", { after: text });
  EOL.reload_behaviors();
  setTimeout(EOL.popups["insert_text_popup"].destroy(), 1000);
}

EOL.TextObjects.preview_text = function(text) {
  Element.insert("insert_text", { after: text });
}

EOL.TextObjects.remove_preview = function() {
  if($('text_')) {
    $('text_').up().remove();
  }
}
