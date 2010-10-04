function textCounter(field,cntfield,maxlimit) {
	if (field.value.length > maxlimit) // if too long...trim it!
		field.value = field.value.substring(0, maxlimit);
	else // otherwise, update 'characters left' counter
		cntfield.html(maxlimit - field.value.length + ' remaining');
}

function check_body_remaining () {
  textCounter($('#news_item_body'),$('#body_remaining_length'),1500);  preview_news_item();
}   

function check_title_remaining () {
  textCounter($('#news_item_title'),$('#title_remaining_length'),250);
  preview_news_item();
}

function preview_news_item() {
 $('#previewed_news_item').html('<strong>'+todays_date+'</strong> - ' + $('#news_item_title').value + ' - ' + $('#news_item_body').value);
} 

$(document).ready(function() {
  check_title_remaining();
  check_body_remaining();
});
