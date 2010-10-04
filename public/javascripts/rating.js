if(!EOL) var EOL = {};
if(!EOL.Rating) EOL.Rating = {};

EOL.Rating.update_average_image_rating = function(data_object_id, rating) {
  var items = $('div.image-rating ul.average-rating li');
  if (items.length > 0)
    items[0].css('width', rating * 20+'%');
};

EOL.Rating.update_average_text_rating = function(data_object_id, rating) {
  $('div#text_buttons_'+data_object_id+' div.text-rating ul.average-rating li')[0].css('width', rating * 20+'%');
};

EOL.Rating.update_user_image_rating = function(data_object_id, rating) {
  var items = $('div.image-rating ul.user-rating li');
  if (items.length > 0)
    items[0].css('width', rating * 20+'%');
  if(EOL.MediaCenter.image_hash[data_object_id])
    EOL.MediaCenter.image_hash[data_object_id].user_rating = rating;
};

EOL.Rating.update_user_text_rating = function(data_object_id, rating) {
  $('div#text_buttons_'+data_object_id+' div.text-rating ul.user-rating li')[0].css('width', rating * 20+'%');
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
