
function textCounter(field,cntfield,maxlimit) {
	if (field.val().length > maxlimit) { // if too long...trim it!
		field.val(field.val().substring(0, maxlimit));
  } else { // otherwise, update 'characters left' counter
		cntfield.html(maxlimit - field.val().length + ' remaining');
  }
}

function check_body_remaining () {
  textCounter($('#news_item_body'),$('#body_remaining_length'),1500);  preview_news_item();
}   

function check_title_remaining () {
  textCounter($('#news_item_title'),$('#title_remaining_length'),250);
  preview_news_item();
}

function preview_news_item() {
 $('#previewed_news_item').html('<strong>'+todays_date+'</strong> - ' + $('#news_item_title').val() + ' - ' + $('#news_item_body').val());
} 

$(document).ready(function() {
  if ($('#body_remaining_length').length > 0) {
    check_title_remaining();
    check_body_remaining();
  }
});
