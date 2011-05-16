if (!EOL) { var EOL = {}; }
if (EOL.use_external_link_popups) {
  EOL.use_external_link_popups = function() {
    $('a.external_link').click(function() {
      // TODO - i18n
      var agree = confirm("The link you have clicked will take you to an external website.  Are you sure you wish to proceed?");
      if (agree) {
        $(this).attr('target', '_blank');
        return true;
      } else {
        return false;
      }
    });
  };
}

// Notice that this does NOT interrupt the event.  If you add this to a click(), it should follow the link.
EOL.addReturnTo = function(link) {
  if ($(link).attr('href') == null) { // Not a link, silly!
    return;
  } else if ($(link).attr('href').match(/\?/) == null) { // There are no params in it yet
    $(link).attr('href', $(link).attr('href') + '?');
  } else { // There are already params in this link
    $(link).attr('href', $(link).attr('href') + '&');
  }
  $(link).attr('href', $(link).attr('href') + "return_to=" + location.href.replace(/^http:\/\/[^\/]*/, '')); // Removes protocol + host
};


$(document).ready(function() {
  if (EOL.USE_EXTERNAL_LINK_POPUPS) { EOL.use_external_link_popups(); }
  $('a.return_to').click(function() { EOL.addReturnTo(this); });
});

