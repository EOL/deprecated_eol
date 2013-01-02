$(function() {

  (function($main) {
    $main.find("a.jp-play").each(function() {
      switch($(this).attr('data-mime_type')) {
        case 'audio/mpeg':
          var media = { mp3: $(this).attr('href') };
          var supplied = "mp3";
          break;
        default:
          // Mime type unknown
          var media = {};
      }
      $("#player").jPlayer({
        swfPath: "/assets/jplayer/js",
        supplied: supplied,
        cssSelectorAncestor: "#player_interface",
        ready: function () {
          $(this).jPlayer("setMedia", media);
        }
      });
    });
  })($("#main"));

  EOL.init_curation_behaviours();
});
