// ajax call to determine if username is unique
function check_username() {
	new Ajax.Request('/account/check_username/', {
	 		parameters: { username: $('user_username').value }, 		
			asynchronous:true,
			evalScripts:true});		
}

// ajax call to determine if email is unique
function check_email() {
	new Ajax.Request('/account/check_email/', {
	 		parameters: { email: $('user_email').value }, 		
			asynchronous:true,
			evalScripts:true});		
}

// instant feedback to user about password matching
function check_passwords() {
	if ($('user_entered_password').value != $('user_entered_password_confirmation').value)
	{
		$('password_warn').innerHTML='Passwords must match';
	}
	else
	{
		$('password_warn').innerHTML='';
	}
}

function reset_curator_panel() {
	EOL.Effect.appear("curator_request_options");
}