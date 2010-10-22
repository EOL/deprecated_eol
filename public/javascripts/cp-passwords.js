  // ajax call to determine if username is unique
  function check_username() {
    $.ajax({ url:'/content_partner/check_username/', data: { username: $('#agent_username').val() } });
  }
  // instant feedback to user about password matching
  function check_passwords() {
    if ($('#agent_password').val() != $('#agent_password_confirmation').val()) {
      $('#password_match').fadeIn();
    } else {
      $('#password_match').fadeOut();
    }
  }
