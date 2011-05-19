$(document).ready(function() {
  $("#user_entered_password").attr("value", "");
  $("#user_entered_password_confirmation").attr("value", "");
  
  // Show the clade browser if the checkbox is checked:
  var curator_request = $('input#curator_request');
  if (curator_request.length > 0) {
    if($('input#curator_request').attr('checked')) {
      $("#curator_request_options").slideDown();
    } else {
      $("#curator_request_options").slideUp();
    }
  }
  // Click to show/hide the clade browser:
  $('input#curator_request').click(function() {
    if($(this).attr('checked')) {
      $("#curator_request_options").slideDown();
    } else {
      $("#curator_request_options").slideUp();
    }
  });
});
// ajax call to determine if username is unique
function check_username() {
  name = $('#user_username').val();
  if (name.length > 0) {
    $.ajax({
      url: '/account/check_username/',
      data: { username: $('#user_username').val() }
    });
  }
}
// ajax call to determine if email is unique
function check_email() {
	$.ajax({ url: '/account/check_email/', data: { email: $('#user_email').val() } });		
}
// instant feedback to user about password matching
function check_passwords() {
  $('#password_warn').html('');
  if ($('#user_entered_password').val() != $('#user_entered_password_confirmation').val()) {
    $('#password_warn').html('passwords must match');
  }
}
