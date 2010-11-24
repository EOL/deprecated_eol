if (!EOL) { EOL = {}; }
if (!EOL.Communities) { EOL.Communities = {}; }

if (!EOL.show_message) {
  EOL.show_message = function(ele) {
    $(ele).slideDown().delay(6000).slideUp();
  };
}

if (!EOL.Communities.members_allowed) {
  EOL.Communities.members_allowed = function(are_they) {
    var members_are = 'allowed';
    var non_members_are = 'not_allowed';
    if (!are_they) {
      members_are = 'not_allowed';
      non_members_are = 'allowed';
    }
    $('.member').removeClass(non_members_are);
    $('.member').addClass(members_are);
    $('.non_member').addClass(non_members_are);
    $('.non_member').removeClass(members_are);
  }
}

if (!EOL.Communities.init_community_behaviors) {
  EOL.Communities.init_community_behaviors = function() {
    $('#leave_community a').unbind('click');
    $('#leave_community a').click(function() {
      var link = $(this);
      var spinner = link.parent().find('img.spinner');
      $.ajax({
        url: link.attr('href'),
        beforeSend: function() { spinner.fadeIn(); },
        success: function() { EOL.show_message('#left_message'); EOL.Communities.members_allowed(false); },
        error: function() { EOL.show_message('#community_problem'); },
        complete: function() { spinner.hide(); }
      });
      return false;
    });
    $('#join_community a').unbind('click');
    $('#join_community a').click(function() {
      var link = $(this);
      var spinner = link.parent().find('img.spinner');
      $.ajax({
        url: link.attr('href'),
        beforeSend: function() { spinner.fadeIn(); },
        success: function() { EOL.show_message('#joined_message'); EOL.Communities.members_allowed(true); },
        error: function() { EOL.show_message('#community_problem'); },
        complete: function() { spinner.hide(); }
      });
      return false;
    });
  }; 
}

$(document).ready(function() {
  EOL.Communities.init_community_behaviors();
});
