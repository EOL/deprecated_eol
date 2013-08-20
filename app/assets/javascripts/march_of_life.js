$(function() {

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
      speed: transition_time,
      before: loadMoreMarchOfLife
    });
    var random_index = Math.floor(Math.random() * 6) + 1;
    initiate_alt_text_for_march_of_life($(".thumbnails li:nth-child(" + random_index + ") img:first"));
  });

  // this method is used to grab more images for the march of life before callback
  function loadMoreMarchOfLife(curr, next, opts) {
    // on the first pass, addSlide is undefined (plugin hasn't yet created the fn); 
    // when we're finshed adding slides we'll null it out again 
    if (!opts.addSlide) return;

    cycle_list_item = $(this).closest('li');
    number_of_images_in_li = cycle_list_item.find('img').size();
    if(number_of_images_in_li < 10) {
      // call to get more images
      $.getJSON('content/random_homepage_images?count=5', function(data) {
        // make sure there were no errors, 
        if(!data['error']) {
          for(i = 0 ; i < data.length ; i++) {
            image_data = data[i];
            // make sure this image isn't already featured on this page
            if($("img[src='" + image_data['image_url'] + "']").size() == 0) {
              // add the HTML for the new image
              scientific_name = image_data['taxon_scientific_name'];
              common_name = image_data['taxon_common_name'];
              if(common_name == null) {
                common_name = '';
              }
              alt_text = scientific_name;
              opts.addSlide('<a href="'+ image_data['taxon_page_path'] + '"><img src="' +
                image_data['image_url'] +
                '" alt="' + alt_text + 
                '" data-scientific_name="' + scientific_name + 
                '" data-common_name="' + common_name + 
                '" width="130" height="130"/></a>');
              // since we had to add a slide we need to change the index of the next slide
              opts.nextSlide = opts.currSlide + 1;
              enable_mouseover_alt_text_for_march_of_life();
            }
          }
        }
      });
      if(cycle_list_item.hasClass("hover")) {
        initiate_alt_text_for_march_of_life($(next).find("img"));
      }
    }
  };

  function enable_mouseover_alt_text_for_march_of_life() {
    // properly shows the march of life name on mouseover
    $(".thumbnails li img").unbind().mouseover(function() { 
      initiate_alt_text_for_march_of_life($(this));
    });
  }
  
  function initiate_alt_text_for_march_of_life(img) {
    var $e = img.parent().parent();
    if ($e.length > 0) {
      $thumbs = $e.closest(".thumbnails");
      var term_p = $thumbs.find(".term p");
      var left_pos = $e.position().left - 100 + 5;
      var right_pos = term_p.outerWidth(true) - $e.position().left - $e.outerWidth(true) - 100;
      if($e.is($(".thumbnails li:last"))) {
        right_pos = right_pos - 15;
      }
      var line_height = 'inherit';
      if(img.attr("data-common_name") == null || img.attr("data-common_name") == '') {
        line_height = $thumbs.find(".term .site_column").css("height");
      }
      var name_html = '<span class="scientific">' + img.attr("data-scientific_name") + '</span>';
      if(img.attr("data-common_name") != null && img.attr("data-common_name") != '') {
        name_html += '<span class="common">' + img.attr("data-common_name") + '</span>';
      }
      term_p.css({
        textAlign: 'center'
      }).css("margin-left", left_pos+"px").css("margin-right", right_pos+"px").css("line-height", line_height).html(name_html);
      $(".thumbnails li").removeClass("hover");
      $e.addClass("hover");
    }
  }
  enable_mouseover_alt_text_for_march_of_life();

});
