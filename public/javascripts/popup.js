/*
 * EOL Popup : A Popup class to encapsulate the typical behavior of Popups on the site, to conventionalize them
 *
 * Usage:
 *   var popup = new Popup('/url', $('id of element to insert the popup after'));
 *   popup.show();
 *
 * Right now, we only support inserting the popup *after* another element.
 *
 * Popups are *hidden* be default, so you need to show() or toggle() them.
 *
 * The element you pass *must* have an id!  We use that (*for now*) to create the popup's ID.
 *
 * Given an option of is_static: true, it will assume there exists a div with the same ID as the button, but with _popup_content
 * appended, and show those contents.  For example, <a id="foo"> would use the contents of <div id="foo_popup_content">; no Ajax
 * will be called. The div shown will be surrounded with the usual background/border/close button.
 *
 */

// hash of initialized popups, keyed on the popup.id.  useful for things like ... closing all other popups, when one is opened
EOL.popups = {};

EOL.Popup = Class.create({
  initialize: function(href, element_to_insert_after, scroll_to){
    default_options = {is_static: false, additional_classes: ''};
    options = Object.extend(default_options, arguments[2]);
    this.is_static = options.is_static || false;
    this.scroll_to = scroll_to;
    this.classes = options.additional_classes ? 'popup ' + options.additional_classes : 'popup';
    this.href = href;
    if(options.insert_after != null) {
      this.element_before = $(options.insert_after);
    } else {
      this.element_before = element_to_insert_after;
    }
    if (this.element_before.id == '') {
      throw( "Element (" + this.element_before + ") passed to new Popup doesn't have an ID!" );
    }
    this.id = this.element_before.id + "_popup";
    this.content_id = this.id + "_content";
    this.create_popup_element();
    this.element_before.insert({ after: this.element });
    EOL.popups[ this.id ] = this;
  },
  create_popup_element: function() {
    // div.popup #name
    this.element = new Element('div', { 'class': this.classes, 'id': this.id });
    this.element.hide();
    
    this.element.insert(new Element('div',{'class': 'popup-min-width'}));
    
    //   a.close-button
    this.close_button = new Element('a', { 'class': 'close-button' });
    Event.observe(this.close_button, 'click', function(e){ console.log(this);this.toggle(); }.bind(this));
    this.element.insert(this.close_button);
    //   div #name_content.popup-content
    if(this.is_static) {
      this.content_element = $(this.content_id);
      this.content_element.style.display = 'block';
    } else {
      this.content_element = new Element('div', { 'id': this.content_id, 'class': 'popup-content' });
      //     img (spinner)
      this.content_element.insert(new Element('img', { 'src': '/images/indicator_arrows_black.gif' }), {position: 'bottom'});
      //     'loading'
      this.content_element.update("<img src='/images/indicator_arrows_black.gif'> Please wait... ");
    }
    this.element.insert(this.content_element);
  },
  toggle: function() {
    if (this.element.visible()) {
      this.hide();
    } else {
      this.show();
    }
  },
  show: function() {
    this.hide_other_popups();
    this.element.appear();
    argh = EOL.popups[this.id];
    if (! this.loaded ) {
      this.load();
    }
  },
  hide: function() {
    this.element.disappear();
  },
  hide_other_popups: function() {
    for(var i in EOL.popups) {
      if(EOL.popups[i].id != this.id)
        EOL.popups[i].hide();
    }
  },
  reload: function() {
    if(!this.is_static) {
      scroll_to = this.scroll_to
      new Ajax.Updater(
        this.content_id,
        this.href,
        {
          asynchronous: true,
          method: 'get',
          onComplete: function() {EOL.PopupHelpers.after_load(scroll_to)}.bind(scroll_to)
        }
      );
    }
  },
  load: function() {
    if (! this.loaded) {
      this.loaded = true;
      this.reload();
    }
  },
  destroy: function() {
    delete EOL.popups[this.id];
    this.element.remove();
    this.element = null;
  }
});
var Popup = EOL.Popup; // alias

function showPopupAjaxIndicator() {
	Element.show('ajax-indicator-popup');
}

function hidePopupAjaxIndicator() {
	Element.hide('ajax-indicator-popup');
}

/*
 * EOL PopupLink : when you have a link and you want to say "when this link gets clicked, don't actually go there,
 *                                                           make a popup from that link, instead"
 *
 * Usage:
 *   new PopupLink( the_link_ID_or_element );
 *   new PopupLink( $$('div#foo a')[0] );
 *
 * Note: if the href of the link is changed, we automatically update
 *       the Popup, when the link is clicked.
 *
 */

// hash of initialized popup links, keyed on the element.id.  useful for getting a reference to these objects.
// a good way to see them all is to: $H(EOL.popup_links).keys()
EOL.popup_links = {};

EOL.PopupLink = Class.create({
  initialize: function(element){
    this.link = $(element);
    this.href = this.link.href;
    this.options = arguments[1];
    Event.observe(this.link, 'click', this.click.bind(this));
    EOL.popup_links[ element.id ] = this;
  },
  click: function(e) {
    if (e) e.stop();
    this.href = this.link.href; // reset, just incase the href has been changed
    if (this.popup == null || this.popup.element == null) {
      this.popup = new Popup(this.href, this.link, this.scroll_to, this.options);
    } else if (this.href != this.popup.href) {
      this.popup.href = this.href;
      this.popup.reload();
    }
    this.popup.toggle();
  }
});
var PopupLink = EOL.PopupLink; // alias

EOL.PopupHelpers = {}
EOL.PopupHelpers.after_load = function(scroll_to) {
  EOL.reload_behaviors();
  jQuery('#large-image-comment-button-popup-link_popup').scrollTo(jQuery('#'+scroll_to), 1000)
}
