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
  }
};