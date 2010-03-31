//I use jquery according to our new policy to use it for every new js
$j(function() {
  $j("#user_entered_password").attr("value","");
  $j("#user_entered_password_confirmation").attr("value","");
});

// ajax call to determine if username is unique
function check_username() {
	new Ajax.Request('/account/check_username/', {
	 		parameters: { username: $('user_username').value }, 		
			asynchronous:true,
			evalscripts:true});		
}

// ajax call to determine if email is unique
function check_email() {
	new Ajax.Request('/account/check_email/', {
	 		parameters: { email: $('user_email').value }, 		
			asynchronous:true,
			evalscripts:true});		
}

// instant feedback to user about password matching
function check_passwords() {
	if ($('user_entered_password').value != $('user_entered_password_confirmation').value)
	{
		$('password_warn').innerhtml='passwords must match';
	}
	else
	{
		$('password_warn').innerhtml='';
	}
}

function reset_curator_panel() {
	eol.effect.appear("curator_request_options");
}
