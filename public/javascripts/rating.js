if(!EOL) var EOL = {};
if(!EOL.Rating) EOL.Rating = {};

EOL.Rating.update_average_image_rating = function(data_object_id, rating) {
  var items = $$('div.image-rating ul.average-rating li');
  if (items.length > 0)
    items[0].setStyle('width: ' + rating * 20 + '%');
  EOL.MediaCenter.image_hash[data_object_id].average_rating = rating;
};

EOL.Rating.update_average_text_rating = function(data_object_id, rating) {
  $$('div#text_buttons_'+data_object_id+' div.text-rating ul.average-rating li')[0].setStyle('width: '+rating * 20+'%');
};

EOL.Rating.update_user_image_rating = function(data_object_id, rating) {
  var items = $$('div.image-rating ul.user-rating li');
  if (items.length > 0)
    items[0].setStyle('width: ' + rating * 20 + '%');
  EOL.MediaCenter.image_hash[data_object_id].user_rating = rating;
};

EOL.Rating.update_user_text_rating = function(data_object_id, rating) {
  $$('div#text_buttons_'+data_object_id+' div.text-rating ul.user-rating li')[0].setStyle('width: '+rating * 20+'%');
};

EOL.Rating.Behaviors = {
  'ul.small-star li a:click': function(e) {

    if(this.readAttribute('data-data_type') == 'image') {
      EOL.Rating.update_user_image_rating(this.readAttribute('data-data_object_id'), this.text)
    } else {
      EOL.Rating.update_user_text_rating(this.readAttribute('data-data_object_id'), this.text)
    }

    new Ajax.Request(this.href,
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'put'
                     });

    return false;
  }
};
