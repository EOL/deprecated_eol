/*
 * EOL Javascript : Common functions, Global variables, etc
 *
 * This defines the EOL namespace which can be used for various common functions that get used throughout the application.
 */
if (!EOL) { var EOL = {}; }

// log something to the console (if a console is available, else do nothing)
EOL.log_enabled = true;
EOL.log = function( msg ) {
  if ( EOL.log_enabled ) {
    try {
      console.log(msg);
    } catch (e) {
      EOL.log_enabled = false;
    }
  }
};
// ...Otherwise they stop working!
EOL.close_open_overlays = function() {
  $('.overlay a.close').click();
};
// Ensure that Rails sees JS requests as ... uhhh... js requests:
jQuery.ajaxSetup({
  'beforeSend': function(xhr) { xhr.setRequestHeader("Accept", "text/javascript"); }
});
