// Links with a rel attribute and a popup-link class will load content via Ajax.
// Note that this is HIGHLY dependent on the popup CSS associated with it:
if (!EOL) { EOL = {}; }
if (!EOL.init_popup_overlays) { 
  EOL.init_popup_overlays = function() {
    // To avoid people clicking on these links before the Ajax is ready, we start with them hidden.  We can show them now:
    $('a.popup-link').show();
    $('a[rel].popup-link').each(function() {
      $(this).overlay({
        fixed: false,
        // Sorry this is hack-ish. The top of an overlay is ALWAYS (argh) relative to the *current* position of the window.  We
        // don't want that, but we can't get rid of it (easily).
        onBeforeLoad: function() {
          var overlay = this.getOverlay();
          $('body').append(overlay);
          var wrapper = overlay.find(".contentWrap");
          var trigger = this.getTrigger();
          var x = trigger.offset()['left'] + trigger.width();
          if(x > 800) { x = 800; }
          var y = trigger.offset()['top'] + trigger.height();
          // This doesn't work.  Why not? TODO - overlay.offset({top:y, left:x});
          overlay.animate({
            top: y,
            left: x
          }, 1); // The '1' here means "super-fast", essentially.  I'm only doing this because offset() isn't working!
          wrapper.load(this.getTrigger().attr('href'));
        }
      });
    });
  };
}

$(document).ready(function() { EOL.init_popup_overlays(); });
