if(!EOL) var EOL = {};
if(!EOL.Rating) EOL.Rating = {};

// These do get called from rjs and curation.js, so need to be methods, despite being simple:
EOL.Rating.update_average_rating = function(data_object_id, rating) {
  $('#average-rating-'+data_object_id).css('width', rating * 20+'%');
};
EOL.Rating.update_user_rating = function(data_object_id, rating) {
  $('#user-rating-'+data_object_id).css('width', rating * 20+'%');
};
// Set up the links to be clickable. A 'scope' of an empty string ('') will do everything on the page...
EOL.Rating.init_links = function(scope) {
  if (scope.length > 0) scope = scope + ' '
  $(scope+'ul.small-star li a').click(function(e) {
    EOL.Rating.update_user_rating($(this).attr('data-data_object_id'), $(this).html());
    $.ajax({url: $(this).attr('href'), type: 'PUT'});
    return false;
  });
};

$(document).ready(function() {
  EOL.Rating.init_links('');
});
