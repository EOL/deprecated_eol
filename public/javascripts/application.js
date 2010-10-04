// WAIT ).merge(EOL.Tagging.Behaviors).merge(EOL.Search.Behaviors).merge(EOL.Curation.Behaviors).merge(EOL.MediaCenter.Behaviors).merge(EOL.TextObjects.Behaviors).merge(EOL.Rating.Behaviors).merge(EOL.Comments.Behaviors).merge(EOL.Admin.Behaviors).toObject());

// Let's register some Ajax callbacks (for the spinner on the page, but could be extended)
$().ajaxStart( EOL.Ajax.start );
$().ajaxStop( EOL.Ajax.finish );

// Behaviours to attach globally:
$(document).ready(function() {
  // Make our links show up
  $('a.external_link').click(function(e) {
    show_popup = false;
    if (EOL.USE_EXTERNAL_LINK_POPUPS) {
      var agree = confirm("The link you have clicked will take you to an external website.  Are you sure you wish to proceed?");
    } else {
      var agree = true;
    }
    if (agree) {
      window.open('/external_link?url=' + escape(this.href));
    }
    return false ;
  });
  $('a.return_to').click(function() {
    EOL.addReturnTo(this);
  });
});

var RecaptchaOptions = { theme : 'clean'};
