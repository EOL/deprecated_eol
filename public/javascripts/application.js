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

if (!EOL) var EOL = {};
// Notice that this does NOT interrupt the event.  If you add this to a click(), it should follow the link.
EOL.addReturnTo = function(link) {
  if ($(link).attr('href') == null) { // Not a link, silly!
    return;
  } else if ($(link).attr('href').match(/\?/) == null) { // There are no params in it yet
    $(link).attr('href', $(link).attr('href') + '?');
  } else { // There are already params in this link
    $(link).attr('href', $(link).attr('href') + '&');
  }
  $(link).attr('href', $(link).attr('href') + "return_to=" + $(link).attr('href').replace(/^http:\/\/[^\/]*/, '')); // Removes protocol + host
}

