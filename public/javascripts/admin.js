if(!EOL) var EOL = {};
if(!EOL.Admin) EOL.Admin = {};

EOL.Admin.Behaviors = {
  'select#content_pages_id:change': function(e) {
    page_id=this.options[this.selectedIndex].value;
    new Ajax.Request('/administrator/content_page/get_page_content/'+ page_id,
    {asynchronous:true,
      evalScripts:true,
      onComplete:function(request){hideAjaxIndicator();},
      onLoading:function(request){showAjaxIndicator();}
      });
    return false;
  },

  'form#page_form input#preview:click': function(e) {
		$('page_form').target="_blank";
		$('page_form').action='/administrator/content_page/preview/'+this.form.readAttribute('data-page_id');
		$('page_form').submit();
  },

  'form#page_form input#publish:click': function(e) {
		$('page_form').target="_self";
		$('page_form').action='/administrator/content_page/update/'+this.form.readAttribute('data-page_id');
		$('page_form').submit();
  },

  'select#content_page_archive_id:change': function(e) {
		content_page_archive_id=this.options[this.selectedIndex].value;
		if (content_page_archive_id != '') {
			new Ajax.Request('/administrator/content_page/get_archived_page', {
				asynchronous: true,
				evalScripts: true,
				method: 'post',
				onComplete: function(request){
					hideAjaxIndicator();
          EOL.reload_behaviors();
				},
				onLoading: function(request){
					showAjaxIndicator();
				},
				parameters: 'content_page_archive_id=' + content_page_archive_id + '&content_page_id=' + this.form.readAttribute('data-page_id')
			});
		}
  },

  'form#content_section_select select#content_section_id:change': function(e) {
    content_section_id=this.options[this.selectedIndex].value;
    new Ajax.Request('/administrator/content_page/get_content_pages',{
      asynchronous:true,
      evalScripts:true,
      method:'post',
      onComplete:function(request){hideAjaxIndicator();},
      onLoading:function(request){showAjaxIndicator();},
      parameters:'id='+content_section_id
    });
  },

  'input#agent_password:blur, input#agent_password_confirmation:blur': function(e) {
    if ($('agent_password').value != $('agent_password_confirmation').value) {
      $('password_warn').show();
    }
    else {
      $('password_warn').hide();
    }
  },

  'div#users a.remove_link:click': function(e) {
    var notes = prompt ("Are you sure you want to remove this user from the curator list?  If so, enter a reason below.  They will be removed immediately, their clade, credentials and scope will be cleared immediately, and they will not be notified.","")
    if (notes != null) {
      new Ajax.Request(this.href, {
        asynchronous:true,
        evalScripts:true,
        parameters:'notes='+escape(notes)
      });
    }
    return false;
  }
};