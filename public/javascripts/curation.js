if(!EOL) var EOL = {};
if(!EOL.Curation) EOL.Curation = {};

EOL.Curation.quick_curate = function(url) {
  $$('#right-image-buttons #spinner img')[0].appear();
  new Ajax.Request(url, {asynchronous:true, evalScripts:true, onComplete:EOL.Curation.after_quick_curate});
};

EOL.Curation.after_quick_curate = function() {
  $$('#right-image-buttons #spinner img')[0].disappear();
  $('large-image-trust-button').disappear();
  $('large-image-untrust-button').disappear();
};

EOL.Curation.Behaviors = {
  '#large-image-curator-button-popup-link_popup_content .visibility input:click': function(e) {
    $$('#large-image-curator-button-popup-link_popup_content .visibility form')[0].onsubmit();
    $$('#large-image-curator-button-popup-link_popup_content .visibility form img')[0].appear();
    $$('#large-image-curator-button-popup-link_popup_content .visibility form')[0].disable();
  },
  
  '#large-image-curator-button-popup-link_popup_content .vetted input:click': function(e) {
    $$('#large-image-curator-button-popup-link_popup_content .vetted form')[0].onsubmit();
    $$('#large-image-curator-button-popup-link_popup_content .vetted form img')[0].appear();
    $$('#large-image-curator-button-popup-link_popup_content .vetted form')[0].disable();
  },
  
  '#large-image-trust-button a:click': function(e) {
    EOL.Curation.quick_curate(this.href);
    e.stop();
  },
  
  '#large-image-untrust-button a:click': function(e) {
    EOL.Curation.quick_curate(this.href);
    e.stop();
  }
};

EOL.Curation.UNKNOWN_ID = 0;
EOL.Curation.UNTRUSTED_ID = 1;
EOL.Curation.TRUSTED_ID = 2;
