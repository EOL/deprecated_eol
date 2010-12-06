/**
 * jQuery Reference Parser
 *
 * jQuery Reference Parser is a jQuery, javascript front-end to a Perl-based bibliographic citation parser. 
 * 
 * Version 1.0
 * November 14, 2010
 *
 * Copyright (c) 2010 David P. Shorthouse
 * Licensed under the MIT license.
 * http://creativecommons.org/licenses/MIT/
 **/

(function($){

  $.fn.refParser = function(custom_options) {

    var base = this;

    var defaults = {
      
      // URL path to the icons directory & icons themselves
      iconPath  : '/images/refparser/',
      icons    : {
        search  : 'magnifier.png',
        loader  : 'ajax-loader.gif',
        error  : 'error.png',
        timeout  : 'clock_red.png',
        pdf    : 'page_white_acrobat.png',
        html  : 'world_go.png',
        doi    : 'world_go.png',
        hdl    : 'world_go.png',
        scholar  : 'g_scholar.png'

      },
      
      // web service parser
      parserUrl  : '/taxa/lookup_reference/',
      callback  : 'myCallback',
      
      // set the target for the final click event (if there is one)
      target    : '_blank',
      
      // set a timeout in milliseconds (should be at least 4000)
      // 20 seconds
      timeout     : 20000
    };
    
    var options = $.extend({}, defaults, custom_options);
    var target = (options.target) ? " target=\""+options.target+"\" " : "";
    
    base.execute = function(obj) {

      var icon = obj.find('.refparser-icon');
      icon.attr({src : options.iconPath + options.icons.loader, alt : 'Looking for reference...', title : 'Looking for reference...'}).css({'cursor':'auto'}).unbind('click');
      $.ajax({
        type : 'GET',
        dataType : 'jsonp',
        url : options.parserUrl + '?ref_id=' + obj.attr('ref_id') + '&callback=?',
        timeout : (options.timeout) ? options.timeout : 5000,
        success : function(data) {
          switch(data.status) {
            case 'ok':
              var doi = (data.record.doi) ? data.record.doi : "";
              var hdl = (data.record.hdl) ? data.record.hdl : "";
              var url2 = (data.record.url) ? data.record.url : "";
              var atitle = (data.record.atitle) ? data.record.atitle : "";
              var glink = "http://scholar.google.com/scholar?q="+escape(atitle);

              if (doi == "" && hdl == "" && url2 == "" && atitle != "") {
                icon.attr({src : options.iconPath + options.icons.scholar, alt : 'Search Google Scholar', title : 'Search Google Scholar'})
                  .css({'cursor':'pointer'})
                  .unbind('click')
                  .wrap("<a href=\"" + glink + "\"" + target + " />");
              }
              else {
                var link = null;
                if (doi != "") {
                  link = "http://dx.doi.org/"+doi;
                  icon.attr({src : options.iconPath + options.icons.doi, alt : 'To publisher...', title : 'To publisher...'})
                    .css({'cursor':'pointer'})
                    .unbind('click')
                    .wrap("<a href=\"" + link + "\"" + target + " />");
                }
                else if (hdl != "") {
                  link = "http://hdl.handle.net/"+hdl;
                  icon.attr({src : options.iconPath + options.icons.hdl, alt : 'To publisher...', title : 'To publisher...'})
                    .css({'cursor':'pointer'})
                    .unbind('click')
                    .wrap("<a href=\"" + link + "\"" + target + " />");
                }
                else if (url2 != "") {
                  var ext = Right(url2,4);
                  var img = options.iconPath + options.icons.html;
                  var alt = "HTML";

                  if (ext == ".pdf") {
                    img = options.iconPath + options.icons.pdf;
                    alt = "PDF";
                  }            
                  icon.attr({src : img, alt : alt, title : alt})
                    .css({'cursor':'pointer'})
                    .unbind('click')
                    .wrap("<a href=\"" + url2 + "\"" + target + " />");
                }
              }
            break;

            case 'failed':
              switch(data.message) {
                case 'Could not parse':
                  icon.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'}).css('cursor','auto').unbind('click');
                break;

                case 'CrossRef is down':
                  icon.attr({src : options.iconPath + options.icons.timeout, alt : 'Service is temporarily down. Please try later.', title : 'Service is temporarily down. Please try later.'}).css('cursor','auto').unbind('click');
                break;

                default:
                  icon.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'}).css('cursor','auto').unbind('click');
              }

            break;  
          }
        },
        error : function() {
          icon.attr({src : options.iconPath + options.icons.timeout, alt : 'Service is temporarily down. Please try later', title : 'Service is temporarily down. Please try later'}).css('cursor', 'auto').unbind('click');
        }
      });
    };

    return this.each(function() {
      
      var $this = $(this);
      
      var target = (options.target) ? " target = \"" + options.target + "\" " : "";
      
      $this.append('<img src="' + options.iconPath + options.icons.search + '" alt="Search!" title="Search!" class="refparser-icon" />');

      $this.find('.refparser-icon').css({'cursor':'pointer','border':'0px'}).click(function() {
        base.execute($this);
      });

    });

  };

})(jQuery);
