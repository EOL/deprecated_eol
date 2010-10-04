// Links with a rel attribute and a popup-link class will load content via Ajax.
// Note that this is HIGHLY dependent on the popup CSS associated with it:
$(document).ready(function() {
  // To avoid people clicking on these links before the Ajax is ready, we start with them hidden.  We can show them now:
  $('a.popup-link, a.slide-in-link').each(function() { $(this).show(); });
  $('a.static-popup-link'); // TODO ... what do we do differently with static popups?
  $('a[rel].popup-link').each(function() {
    var x = $(this).offset()['left'] + $(this).width();
    var y = $(this).offset()['top'] + $(this).height();
    // Sorry this is hack-ish. The top of an overlay is ALWAYS (argh) relative to the *current* position of the window.  We
    // don't want that, but we can't get rid of it (easily).  I'm doing the best I can, here, by setting it to where the
    // scroll was when the page was loaded... but, of course, that's not always useful. If we get desperate, I can reset this
    // value (expensively) every time the user scrolls.  For now, I don't think it's worth it.
    $(this).overlay({
      fixed: false,
      top: y - $(document).scrollTop(),
      left: x,
      onBeforeLoad: function() {
        var overlay = this.getOverlay();
        $('body').append(overlay);
        var wrapper = overlay.find(".contentWrap");
        wrapper.load(this.getTrigger().attr('href'));
      },
      onLoad: function() {
        var overlay = this.getOverlay();
        overlay.animate({
          top: y,
          left: x
        }, 325);
      }
    });
  });
});
