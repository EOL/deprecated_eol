/*
 * EOL Javascript : Common functions, Global variables, etc
 *
 * This defines the EOL namespace which can be used for various common functions that get used throughout the application.
 *
 * This allows for better / easier convention following.  For example, instead of using Script.aculo.us effects, directly,
 * you can [define and] use an EOL effects so that every time we want to show or hide something, we use the same effect,
 * with the same options passed, etc.  Making everything nice and conventional  :)
 *
 * Here are some conventions we can use for this:
 *  - Classes and Namespaces should be PascalCase
 *  - Functions and Variables should be camelCase
 *
 * For "classes" and whatnot, we should use Prototype.
 *
 * When a function accepts an 'element' as an argument, assume that it could be the 'id' or an element or an actual DOM element
 *
 */
var EOL = {};

/*
 * Miscellaneous Helper Functions and whatnot
 *
 */

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

// what is this supposed to do?  where is it used?  (i can't find it used anywhere)
EOL.defer_click = function(e) {
  Event.observe(window, 'load', function() {e.onclick();});
  return(false);
};

// get the current app path # there may be a prototype built-in function for easily doing this, i just gsub out everything before the /path
EOL.current_path = function() {
  return window.location.toString().gsub(/https?:\/\//,'').gsub(/^([^/])/,'');
};
