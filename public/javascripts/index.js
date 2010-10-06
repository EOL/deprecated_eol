var updating = true;
var taxa_number_to_replace = 1;
var interval_between_loads = 10000;

function explore_more_taxa() {
  if (updating) {
    updating = false;
  }
  $.ajax({
    url: '/content/explore_taxa',
    beforeSend: function() {$('#photos_area').fadeTo(200, 0.03);},
    success: function(response){$('#photos_area').html(response);},
    complete: function(){
        taxa_number_to_replace = 1;
        setTimeout("start_explore_updates()",interval_between_loads);
        $('#photos_area').delay(300).fadeTo(750, 1);
    }
  });
}

function fade_out_taxa(num) {
  $('#top_image_tag_'+num).fadeOut(600);
  $('#top_name_'+num).fadeOut(600);
}

function fade_in_taxa(num) {
  $('#top_image_tag_'+num).delay(250).fadeIn(600);
  $('#top_name_'+num).fadeIn(600);
}

function replace_single_taxa(taxa_number) {
  if(updating) {
    r = new RegExp("[0-9]+$");
    var current_taxa = [];
    $('td.name a').each(function() {
      current_taxa.push($(this).attr('href'));
    });
    $.ajax({
      url: '/content/replace_single_explore_taxa',
      data: {taxa_number: taxa_number, current_taxa: current_taxa.join(',')},
      failure: function(request){fade_in_taxa(taxa_number);},
      success: function(request){fade_in_taxa(taxa_number);},
      beforeSend: function(request){fade_out_taxa(taxa_number);}
    });
    taxa_number_to_replace += 1;
  }
}

function get_new_explore_taxa() {
  if (taxa_number_to_replace > 6) {taxa_number_to_replace = 1;}
  replace_single_taxa(taxa_number_to_replace);
}

function pause_explore_updates() {
  updating = false;
  $('#play-button').attr('src', png_host + '/images/homepage/play.gif');
  $('#play-button').attr('alt', 'play');
}

function start_explore_updates() {
  updating = true;
  $('#play-button').attr('src', png_host + '/images/homepage/pause.gif');
  $('#play-button').attr('alt', 'pause');
}

function toggle_explore_updates() {
  if (updating) {
    pause_explore_updates();
  }
  else
  {
    start_explore_updates();
  }
}

$(document).ready(function() {
  window.setInterval(get_new_explore_taxa, interval_between_loads);
});
