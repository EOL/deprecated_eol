if(!EOL) { var EOL = {}; }
// Third party scripts for social plugins
EOL.loadTwitter = function() {
  if($(".twitter-share-button").length > 0){
    if (typeof (twttr) !== 'undefined') {
      twttr.widgets.load();
      EOL.initTwitter();
    } else {
      $.getScript("http://platform.twitter.com/widgets.js", function() { EOL.initTwitter(); });
    }
  }
};
EOL.initTwitter = function() {
  if (typeof(_ga) !== 'undefined') {
    _ga.trackTwitter();
  }
};
EOL.loadFacebook = function(app_id, channel_url) {
  if ($("#fb-root").length > 0) {
    if (typeof (FB) !== 'undefined') {
      EOL.initFacebook();
    } else {
      $.getScript("http://connect.facebook.net/en_US/all.js", function() { EOL.initFacebook(app_id, channel_url); });
    }
  }
};
EOL.initFacebook = function(app_id, channel_url) {
  FB.init({
    appId      : app_id,
    channelUrl : channel_url,
    logging    : true,
    status     : true,
    cookie     : true,
    xfbml      : true
  });
  if (typeof(_ga) !== 'undefined') {
    _ga.trackFacebook();
  }
};

