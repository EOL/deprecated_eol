/*
 *   This is intended to be merged back into the "application" JS, once that has settled from HR.
 */

if(!EOL) { var EOL = {}; }

// TODO - not all of these are required, if we know we won't use them:
$.ajaxSetup({accepts: {
  '*': "text/javascript, */*",
  html: "text/javascript",
  json: "application/json, text/javascript",
  script: "text/javascript",
  text: "text/plain",
  xml: "application/xml, text/xml"
}});

// TODO - I gave up on this and put the form right on the page.  This is less than ideal, but I18n made this a bad
// option for now. I'm keeping the code here for help later, though.
$('.editable_link a').click(function() {
  var url = $(this).attr('href');
  var cell = $(this).closest('.editable');
  $.ajax({
    url: url,
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      $('.editable_link a').unbind('click'); // TODO - needed?
      EOL.init_collection_behaviours();
    }
  });
  return(false); // stop event... there's a better way to do this?
});

// trying to generalize Ajax calls for EOL:
// Arguments:
//   el: The element firing the event.  It helps us find stuff, please pass it.
//   update: where you want the (html) response to go.  Defaults to the closest .editable item.
//   url: where you want the form to subit to.  Defaults to the data_url of the el you pass in, then to the nearest
//        form's action.
//   data: The data to send.  Defaults to the nearest form, serialized.
//   complete: Function to call when complete.  Optional.
EOL.ajax_submit = function(el, args) {
  var form = el.closest('form');
  var cell = '';
  if(typeof(args.update) != 'undefined') {
    cell = args.update;
  } else {
    cell = el.closest('.editable');
  }
  var url  = '';
  if(typeof(args.url) != 'undefined') {
    url = args.url;
  } else if(typeof(el.attr('data_url')) != 'undefined') {
    url = el.attr('data_url');
  } else {
    url = form.attr('action');
  }
  var data = '';
  if(typeof(args.data) != 'undefined') {
    data = args.data;
  } else {
    data = form.serialize();
  }
  complete = '';
  if(typeof(args.complete) != 'undefined') {
    complete = args.complete;
  }
  $.ajax({
    url: url,
    data: data,
    type: 'POST',
    dataType: 'html',
    beforeSend: function(xhr) { cell.fadeTo(300, 0.3); },
    success: function(response) { cell.html(response); },
    error: function(xhr, stat, err) { cell.html('<p>Sorry, there was an error: '+stat+'</p>'); },
    complete: function() {
      cell.delay(25).fadeTo(100, 1, function() {cell.css({filter:''});});
      if(complete != '') {
        complete();
      }
    }
  });
  return(false); // stop event... there's a better way to do this?
};

// Add to collection buttons should be Ajaxy:
$(function() {
  $('form#new_collection_item').find('input.button').click(function() {
    var $f = $(this).closest('form');
    EOL.ajax_submit($(this), {update: $f})
    return(false);
  });
});

$(document).ready(function() {
  // initiates march of life on homepage
  $('.thumbnails ul li').each(function() {
    var number_of_slides = $('.thumbnails ul li').length;
    var index = $(this).index();
    var random = new Array(-3, 1, 0, -2, -4, -1);
    var display_time = 5000;
    var transition_time = 1800;
    $(this).cycle({
      fx: 'fade',
      timeout: number_of_slides * display_time,
      delay: random[index] * display_time,
      speed: transition_time
    });
  });
  
  // properly shows the march of life name on mouseover
  $(".thumbnails li img").unbind().mouseover(function() {
    var $e = $(this).parent().parent(),
        $thumbs = $e.closest(".thumbnails"),
        margin = $thumbs.find("li").eq(0).outerWidth(true) - $e.outerWidth();
        direction = ($e.index() > $thumbs.find("li").length / 2 - 1) ? "right" : "left";
        pos = $e.position();
    pos.right = $thumbs.find("ul").width() - $e.outerWidth() - pos.left + margin;
    $thumbs.find(".term p").css({
      margin: 0,
      textAlign: direction
    }).css("margin-" + direction, pos[direction]).text($(this).attr("alt"));
  }).eq(0).mouseover();

  // removes the homepage march of life name on mouseout
  $(".thumbnails li").mouseout(function() {
    $(".thumbnails .term p").html("&nbsp;");
  });
  
  
  // uncheck search filter All when other options are selected
  $("#main_search_type_filter input[type=checkbox][value!='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value='all']").removeAttr("checked");
  });
  // uncheck all other search filter options when All is selected
  $("#main_search_type_filter input[type=checkbox][value='all']").click(function() {
    $("#main_search_type_filter input[type=checkbox][value!='all']").removeAttr("checked");
  });
  // disable the checkboxes for filter categories with no results
  $("#main_search_type_filter li.no_results input[type=checkbox]").attr("disabled", true);
  
  
  // uncheck media list filter All when other options are selected
  $("#media_list #sidebar input[type=checkbox][value!='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  // uncheck all other media list filter options when All is selected
  $("#media_list #sidebar input[type=checkbox][value='all']").click(function() {
    $("#media_list #sidebar input[type=checkbox][value!='all'][name='"+ $(this).attr('name') +"']").removeAttr("checked");
  });
  
  // re-writing a block from application.js which was missing an end() and thus was broken
  $(".heading form.filter, form.select_submit").find(".actions").hide().find(":submit").end().end().find("select")
    .change(function() {
      $(this).closest("form").submit();
    });
});


