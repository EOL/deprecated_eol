CKEDITOR.editorConfig = function( config ) {

  config.ToolbarSets["Easy"] = [
          ['Bold','Italic','Underline','StrikeThrough','-'],
          ['OrderedList','UnorderedList','-'],
          ['FontSize'], ['TextColor','BGColor'],
          ['easyImage', 'easyLink', 'Unlink']
  ] ;

  config.ToolbarSets["Simple"] = [
          ['Source','-','-','Templates'],
          ['Cut','Copy','Paste','PasteWord','-','Print','SpellCheck'],
          ['Undo','Redo','-','Find','Replace','-','SelectAll'],
          '/',
          ['Bold','Italic','Underline','StrikeThrough','-','Subscript','Superscript'],
          ['OrderedList','UnorderedList','-','Outdent','Indent'],
          ['JustifyLeft','JustifyCenter','JustifyRight','JustifyFull'],
          ['Link','Unlink'],
          '/',
          ['Image','Table','Rule'],
          ['FontName','FontSize','Style'],
          ['TextColor','BGColor']
  ] ;

  config.ToolbarSets["Article"] = [
         ['Cut','Copy','Paste','PasteWord','-','SpellCheck','-','Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
         ['Bold','Italic','-', 'Link','Unlink','Anchor'], ['Source']
  ] ;

  config.ToolbarSets["CMSNavigation"] = [
         ['Cut','Copy','Paste','PasteWord','-','SpellCheck'],
         ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
         ['UnorderedList'],
         ['Link','Unlink'],
         ['Source','FitWindow','ShowBlocks','-','About']
  ] ;

  config.ToolbarSets["CMSBody"] = [
         ['Cut','Copy','Paste','PasteWord','-','SpellCheck','-','Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
         ['Source','FitWindow','ShowBlocks','-','About'],
         '/',
         ['FontFormat','OrderedList','UnorderedList','Blockquote','-','Bold','Italic','-','Subscript','Superscript'],
         ['Link','Unlink','Anchor'],
         ['Image','Table','Rule','SpecialChar']
  ] ;

  config.FontFormats = 'p;h2;h3;h4;h5;h6;pre;address' ;
  config.IgnoreEmptyParagraphValue = true ;
  config.FillEmptyBlocks = false ;
  config.StartupShowBlocks = true ;
  config.LinkDlgHideTarget = true ;
  config.DefaultLinkTarget = '' ;
  config.CleanWordKeepsStructure = true ;
}
