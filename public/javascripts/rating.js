if(!EOL) var EOL = {};
if(!EOL.Rating) EOL.Rating = {};

EOL.Rating.update_average_image_rating = function(data_object_id, rating) {
  $('#average-rating-'+data_object_id).css('width', rating * 20+'%');
};

EOL.Rating.update_average_text_rating = function(data_object_id, rating) {
  $('#average-rating-'+data_object_id).css('width', rating * 20+'%');
};

EOL.Rating.update_user_image_rating = function(data_object_id, rating) {
  $('#user-rating-'+data_object_id).css('width', rating * 20+'%');
};

EOL.Rating.update_user_text_rating = function(data_object_id, rating) {
  $('#user-rating-'+data_object_id).css('width', rating * 20+'%');
};

$(document).ready(function() {
  $('ul.small-star li a').click(function(e) {
    if($(this).attr('data-data_type') == 'image') {
      EOL.Rating.update_user_image_rating($(this).attr('data-data_object_id'), $(this).text);
    } else {
      EOL.Rating.update_user_text_rating($(this).attr('data-data_object_id'), $(this).text);
    }
    $.ajax({
      url: $(this).attr('href'),
      type: 'PUT'
    });
    return false;
  });
});
