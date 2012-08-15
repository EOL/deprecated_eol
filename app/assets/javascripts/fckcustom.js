// CHANGE FOR APPS HOSTED IN SUBDIRECTORY
FCKRelativePath = '';

// DON'T CHANGE THESE
FCKConfig.LinkBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Connector='+FCKRelativePath+'/fckeditor/command';
FCKConfig.ImageBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Type=Image&Connector='+FCKRelativePath+'/fckeditor/command';
FCKConfig.FlashBrowserURL = FCKConfig.BasePath + 'filemanager/browser/default/browser.html?Type=Flash&Connector='+FCKRelativePath+'/fckeditor/command';

FCKConfig.LinkBrowser = false;
FCKConfig.ImageBrowser = false;
FCKConfig.LinkUploadURL = FCKRelativePath+'/fckeditor/upload';
FCKConfig.ImageUploadURL = FCKRelativePath+'/fckeditor/upload?Type=Image';
FCKConfig.FlashUploadURL = FCKRelativePath+'/fckeditor/upload?Type=Flash';
FCKConfig.SpellerPagesServerScript = FCKRelativePath+'/fckeditor/check_spelling';
FCKConfig.AllowQueryStringDebug = false;
FCKConfig.SpellChecker = 'WSC' ;	// 'WSC' | 'SpellerPages' | 'ieSpell'

//FCKConfig.Plugins.Add( 'easyUpload', 'es' ) ;		// easyUpload translated to spanish
FCKConfig.Plugins.Add( 'easyUpload', 'en' ) ;

FCKConfig.ContextMenu = ['Generic','Anchor','Flash','Select','Textarea','Checkbox','Radio','TextField','HiddenField','ImageButton','Button','BulletedList','NumberedList','Table','Form'] ;

// ONLY CHANGE BELOW HERE
FCKConfig.SkinPath = FCKConfig.BasePath + 'skins/office2003/';

FCKConfig.EditorAreaCSS = '/stylesheets/fckcustom.css' ;

FCKConfig.ToolbarSets["Easy"] = [
        ['Bold','Italic','Underline','StrikeThrough','-'],
        ['OrderedList','UnorderedList','-'],
        ['FontSize'], ['TextColor','BGColor'],
        ['easyImage', 'easyLink', 'Unlink']
] ;

FCKConfig.ToolbarSets["Simple"] = [
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

FCKConfig.ToolbarSets["Article"] = [
       ['Cut','Copy','Paste','PasteWord','-','SpellCheck','-','Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
       ['Bold','Italic','-', 'Link','Unlink','Anchor'], ['Source']
] ;

FCKConfig.ToolbarSets["CMSNavigation"] = [
       ['Cut','Copy','Paste','PasteWord','-','SpellCheck'],
       ['Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
       ['UnorderedList'],
       ['Link','Unlink'],
       ['Source','FitWindow','ShowBlocks','-','About']
] ;

FCKConfig.ToolbarSets["CMSBody"] = [
       ['Cut','Copy','Paste','PasteWord','-','SpellCheck','-','Undo','Redo','-','Find','Replace','-','SelectAll','RemoveFormat'],
       ['Source','FitWindow','ShowBlocks','-','About'],
       '/',
       ['FontFormat','OrderedList','UnorderedList','Blockquote','-','Bold','Italic','-','Subscript','Superscript'],
       ['Link','Unlink','Anchor'],
       ['Image','Table','Rule','SpecialChar']
] ;

FCKConfig.FontFormats = 'p;h2;h3;h4;h5;h6;pre;address' ;
FCKConfig.IgnoreEmptyParagraphValue = true ;
FCKConfig.FillEmptyBlocks = false ;
FCKConfig.StartupShowBlocks = true ;
FCKConfig.LinkDlgHideTarget = true ;
FCKConfig.DefaultLinkTarget = '' ;
FCKConfig.CleanWordKeepsStructure = true ;