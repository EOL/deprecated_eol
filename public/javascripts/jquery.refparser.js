(function($){

  $.fn.refParser = function(options) {

    var defaults = {
      //CrossRef API username:password key (use an account that CANNOT be used to assign DOIs)
      // Get an account here: http://www.crossref.org/requestaccount/
      pid      : 'pleary@mbl.edu',
      
      //URL path to the icons directory & icons themselves
      iconPath : '/images/refparser/',
      icons : {
        search  : 'magnifier.png',
        loader  : 'ajax-loader.gif',
        error   : 'error.png',
        timeout : 'clock_red.png',
        pdf     : 'page_white_acrobat.png',
        html    : 'world_go.png',
        doi     : 'world_go.png',
        hdl     : 'world_go.png',
        scholar : 'g_scholar.png'

      },
      
      //web service parser thatcould be a remote or IP-based fully qualified URL (jQuery's jsonp is used)
      parserUrl : 'http://refparser.shorthouse.net/cgi-bin/refparser',
      callback  : 'myCallback',
      
      //set the target for the final click event
      target    : '_blank',
      
      //cause all references to be checked on page load
      preload   : false
    };

    var extended_options = $.extend({}, defaults, options);

    return this.each(function() {
      
      var $this = $(this);
      
      var target = (extended_options.target) ? " target = \"" + extended_options.target + "\" " : "";
      
      $this.append('<img src="' + extended_options.iconPath + extended_options.icons.search + '" alt="Search!" title="Search!" class="refparser-icon" />');

      $this.find('.refparser-icon').css({'cursor':'pointer','border':'0px','height':'16px','width':'16px','vertical-align':'center'}).each(function() {
        if(extended_options.preload) {
          $.fn.refParser.execute($(this), extended_options, target);
        }
        else {
          $(this).click(function() {
            $.fn.refParser.execute($(this), extended_options, target);
          });
        }
      });
    });
    
  };
  
  $.fn.refParser.execute = function(obj, options, target) {
    
    var ref = obj.parent().text();
    
    obj.attr({src : options.iconPath + options.icons.loader, alt : 'Looking for reference...', title : 'Looking for reference...'}).css({'cursor':'auto'}).unbind('click');
    $.ajax({
      url: options.parserUrl + '?pid=' + options.pid + '&output=json&q=' + escape(ref) + '&callback=?',
      dataType: 'json',
      global: false,
      error: function(xhr, textStatus, thrownError) {
        obj.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'})
          .css({'cursor':'auto'})
          .unbind('click');
      },
      success: function(data) {
        switch(data.status) {
          case 'ok':
            var doi = data.record.doi;
            var hdl = data.record.hdl;
            var url2 = data.record.url;
            var atitle = data.record.atitle;
            var glink = "http://scholar.google.com/scholar?q="+escape(atitle)+"&as_subj=bio";
            
            if ((doi == null || doi == '') && (hdl == null || hdl == '') && (url2 == null || url2 == '') && atitle != null && atitle != '') {
              obj.attr({src : options.iconPath + options.icons.scholar, alt : 'Search Google Scholar', title : 'Search Google Scholar'})
                .css({'cursor':'pointer'})
                .unbind('click')
                .wrap("<a href=\"" + glink + "\"" + target + " />");
            }
            else {
              var link = null;
              if (doi != null && doi != '') {
                link = "http://dx.doi.org/"+doi;
                obj.attr({src : options.iconPath + options.icons.doi, alt : 'To publisher...', title : 'To publisher...'})
                  .css({'cursor':'pointer'})
                  .unbind('click')
                  .wrap("<a href=\"" + link + "\"" + target + " />");
              }
              else if (hdl != null && hdl != '') {
                link = "http://hdl.handle.net/"+hdl;
                obj.attr({src : options.iconPath + options.icons.hdl, alt : 'To publisher...', title : 'To publisher...'})
                  .css({'cursor':'pointer'})
                  .unbind('click')
                  .wrap("<a href=\"" + link + "\"" + target + " />");
              }
              else if (url2 != null && url2 != '') {
                var ext = Right(url2,4);
                var img = options.iconPath + options.icons.html;
                var alt = "HTML";
                
                if (ext == ".pdf") {
                  img = options.iconPath + options.icons.pdf;
                  alt = "PDF";
                }            
                obj.attr({src : img, alt : alt, title : alt})
                  .css({'cursor':'pointer'})
                  .unbind('click')
                  .wrap("<a href=\"" + url2 + "\"" + target + " />");
              }
              else
              {
                obj.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'})
                  .css({'cursor':'auto'})
                  .unbind('click');
              }
            }
          break;
          
          case 'failed':
            switch(data.message) {
              case 'Could not parse':
                obj.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'}).css('cursor','auto').unbind('click');
              break;
              
              case 'CrossRef is down':
                obj.attr({src : options.iconPath + options.icons.timeout, alt : 'Service is temporarily down. Please try later.', title : 'Service is temporarily down. Please try later.'}).css('cursor','auto').unbind('click');
              break;
              
              default:
                obj.attr({src : options.iconPath + options.icons.error, alt : 'Unable to parse reference', title : 'Unable to parse reference'}).css('cursor','auto').unbind('click');
            }
          
          break;
        }
      }
    });
  };
})(jQuery);