alert('we have been loaded.');
if(!EOL) var EOL = {};
if(!EOL.CommonNameCuration) EOL.CommonNameCuration = {};

EOL.Curation.CommonNameBehaviors = {
  'form#set_preferred_name input[type="radio"]:click': function(e) {
    var form = $(this.form);
    $('div#common_names_spinner img').appear();
    $('div#common_names_error').disappear();
    new Ajax.Request(form.action,
                     { asynchronous:true,
                       evalScripts:true,
                       method:'put',
                       onError:function(){
                         $('div#common_names_error').appear();
                         $('div#common_names_spinner img').disappear();
                       }.bind(element),
                       onComplete:function() {
                         $('div#common_names_spinner img').disappear();
                       }.bind(form),
                       parameters:Form.serialize(form)
                     });
  }
};
