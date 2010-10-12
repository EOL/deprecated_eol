$(document).ready(function() {
  $("#user_entered_password").attr("value","");
  $("#user_entered_password_confirmation").attr("value","");
});
// ajax call to determine if username is unique
function check_username() {
	$.ajax({
    url: '/account/check_username/',
    data: { username: $('#user_username').val() }
  });
}
// ajax call to determine if email is unique
function check_email() {
	$.ajax({
    url: '/account/check_email/',
	 	parameters: { email: $('#user_email').val() }, 		
  });		
}
// instant feedback to user about password matching
function check_passwords() {
	if ($('#user_entered_password').val() != $('#user_entered_password_confirmation').val())
	{
		$('#password_warn').html('passwords must match');
	}
	else
	{
		$('#password_warn').html('');
	}
}
