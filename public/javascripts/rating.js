if(!EOL) var EOL = {};
if(!EOL.Rating) EOL.Rating = {};

EOL.Rating.update_image_rating = function(rating) {
  $$('div.image-rating ul.average-rating li')[0].setStyle('width: '+rating * 20+'%')
};

EOL.Rating.update_text_rating = function(id, rating) {
  $$('div#text_buttons_'+id+' div.text-rating ul.average-rating li')[0].setStyle('width: '+rating * 20+'%')
};

EOL.Rating.Behaviors = {
  'ul.small-star li a:click': function(e) {

    this.up().up().down('li').setStyle('width: '+(this.text * 20)+'%');

    new Ajax.Request(this.href,
                     {
                       asynchronous:true,
                       evalScripts:true,
                       method:'put'
                     });

    return false;
  }
};