/*
Copyright (c) 2003-2011, CKSource - Frederico Knabben. All rights reserved.
For licensing, see LICENSE.html or http://ckeditor.com/license
*/

CKEDITOR.editorConfig = function( config )
{
  // Define changes to default configuration here. For example:
  // config.language = 'fr';
  // config.uiColor = '#AADC6E';

  // The location of a script that handles file uploads in the Image dialog.
  config.filebrowserImageUploadUrl = "/wysiwyg/upload_image";

  config.format_tags = 'p;h2;h3;h4;h5;h6;pre;address';
  config.ignoreEmptyParagraph = true;
  config.fillEmptyBlocks = false;
  config.startupOutlineBlocks = false;
  config.pasteFromWordNumberedHeadingToList = true;

  /* Extra plugins */
  // works only with en, ru, uk locales
  config.extraPlugins = "embed,attachment";

  /* Toolbars */
  config.toolbar = 'Easy';

  config.toolbar_Easy =
    [
      [ 'Bold' ,'Italic' ,'Underline' ,'Strike' ,'-' ],
      [ 'NumberedList' ,'BulletedList' ,'-' ],
      [ 'FontSize' ], [ 'TextColor' ,'BGColor' ],
      [ 'ImageButton', 'Link', 'Unlink' ],
      [ 'Source' ,'-' ,'ShowBlocks' ,'-' ,'Preview' ]
    ] ;

  config.toolbar_Article =
    [
        [ 'Cut' ,'Copy' ,'Paste' ,'PasteFromWord' ,'-' ,'SpellChecker' ,'-' ,'Undo' ,'Redo' ,'-' ,'Find' ,'Replace' ,'-' ,'SelectAll' ,'RemoveFormat' ],
        [ 'Bold' ,'Italic' ,'-', 'Link' ,'Unlink' ,'Anchor' ], [ 'Source' ,'-' ,'ShowBlocks' ,'-' ,'Preview' ]
    ] ;

  config.toolbar_CMSNavigation =
    [
        [ 'Cut' ,'Copy' ,'Paste' ,'PasteFromWord' ,'-' ,'SpellChecker' ],
        [ 'Undo' ,'Redo' ,'-' ,'Find' ,'Replace' ,'-' ,'SelectAll' ,'RemoveFormat' ],
        [ 'BulletedList' ],
        [ 'Link' ,'Unlink' ],
        [ 'Source' ,'-' ,'ShowBlocks' ,'-' ,'Preview' ]
    ] ;

  config.toolbar_CMSBody =
    [
        [ 'Cut' ,'Copy' ,'Paste' ,'PasteFromWord' ,'-' ,'SpellChecker' ,'-' ,'Undo' ,'Redo' ,'-' ,'Find' ,'Replace' ,'-' ,'SelectAll' ,'RemoveFormat' ],
        [ 'Source' ,'-' ,'ShowBlocks' ,'-' ,'Preview' ],
        '/',
        [ 'Format' ,'NumberedList' ,'BulletedList' ,'Blockquote' ,'-' ,'Bold' ,'Italic' ,'-' ,'Subscript' ,'Superscript' ],
        [ 'Link' ,'Unlink' ,'Anchor' ],
        [ 'Image' ,'Table' ,'HorizontalRule' ,'SpecialChar' ]
    ];
    
  CKEDITOR.on( 'instanceReady', function( ev )
  {
    var editor = ev.editor,
      dataProcessor = editor.dataProcessor,
      htmlFilter = dataProcessor && dataProcessor.htmlFilter;

      dataProcessor.writer.setRules( 'p',
      {
        indent : false,
        breakBeforeOpen : true,
        breakAfterOpen : false,
        breakBeforeClose : false,
        breakAfterClose : true
      });
  });

  // Rails CSRF token
  config.filebrowserParams = function(){
    var csrf_token, csrf_param, meta,
        metas = document.getElementsByTagName('meta'),
        params = new Object();

    for ( var i = 0 ; i < metas.length ; i++ ){
      meta = metas[i];

      switch(meta.name) {
        case "csrf-token":
          csrf_token = meta.content;
          break;
        case "csrf-param":
          csrf_param = meta.content;
          break;
        default:
          continue;
      }
    }

    if (csrf_param !== undefined && csrf_token !== undefined) {
      params[csrf_param] = csrf_token;
    }

    return params;
  };

  config.addQueryString = function( url, params ){
    var queryString = [];

    if ( !params ) {
      return url;
    } else {
      for ( var i in params )
        queryString.push( i + "=" + encodeURIComponent( params[ i ] ) );
    }

    return url + ( ( url.indexOf( "?" ) != -1 ) ? "&" : "?" ) + queryString.join( "&" );
  };

  // Integrate Rails CSRF token into file upload dialogs (link, image, attachment and flash)
  CKEDITOR.on( 'dialogDefinition', function( ev ){
    // Take the dialog name and its definition from the event data.
    var dialogName = ev.data.name;
    var dialogDefinition = ev.data.definition;
    var content, upload;

    if (CKEDITOR.tools.indexOf(['link', 'image', 'attachment', 'flash'], dialogName) > -1) {
      content = (dialogDefinition.getContents('Upload') || dialogDefinition.getContents('upload'));
      upload = (content == null ? null : content.get('upload'));

      if (upload && upload.filebrowser['params'] == null) {
        upload.filebrowser['params'] = config.filebrowserParams();
        upload.action = config.addQueryString(upload.action, upload.filebrowser['params']);
      }
    }
  });
};


