/*
 * Misc Javascript variables and functions.
 *
 * This could all likely use some cleanup.  Some of this stuff could be:
 *
 *  - turned into event-based unobtrusive javascript
 *  - simply named/namespaced a bit better
 *  - the html generated from javascript strings could likely be improved or moved to the server-side
 *
 */ 

// Updates the main image and calls eol_update_credit()
function eol_update_image(large_image_url, params) {

  /* Working if u want to see the Photosynth interface right away after clicking on a thumbnail
  var string = params.source_url;//source_url is from [views/taxa/_image_collection]
  if(string.search(/photosynth.net/) == -1)
  { //regular static image
    $('#main-image-bg').html = "<img id='main-image'>";      
    $('#main-image').src = large_image_url;
    $('#main-image').alt=params.nameString;
    $('#main-image').title=params.nameString;    
  }
  else
  { //photosynth image
    // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
    synth = "<iframe frameborder='0' src='" + string.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe><img id='main-image'>";
    $('#main-image-bg').html = synth;  
  }
  */  

  // This will display a photosynth icon if a thumbnail photosynth image is clicked.
  var string = params.source_url; //source_url is from [views/taxa/_image_collection]
  if(string.search(/photosynth.net/) == -1) { //regular static image    
      $('#photosynth-message').html = "";          
  } else { //photosynth image
    // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
    $('#photosynth-message').html = "<a href=javascript:load_photosynth_interface('" + escape(params.source_url) + "')><img src='http://mslabs-999.vo.llnwd.net/e1/inc/images/master/logo.png' height='27' alt='Photosynth' title='Image is part of a Photosynth'></a>";    
  }

}

// Updates the main image and calls eol_update_credit()
function eol_update_video(params) {
    $('div#media-videos div.attribution_link').show();
    for(var i in EOL.popups) {
      EOL.popups[i].destroy();
    }
    $('#video_attributions').attr('href', "/data_objects/" + params.data_object_id + "/attribution");

    $.ajax({
      url: '/taxa/show_video/',
      data: { video_type: params.video_type, video_url: params.video_url, video_mime_type_id: params.mime_type_id, data_object_id: params.data_object_id, video_object_cache_url: params.object_cache_url },
    });

    $('#video-notes').removeClass('untrusted-background-text');         
    $('#video-player').removeClass('untrusted-background-color');         
    $('#video_attributions').removeClass('untrusted');     

    $('#video-notes').removeClass('unknown-background-text');         
    $('#video-player').removeClass('unknown-background-color');         
    $('#video_attributions').removeClass('unknown');

    if (params.video_trusted == EOL.Curation.UNTRUSTED_ID){
      $('#video-notes').addClass('untrusted-background-text');
      $('#video-player').addClass('untrusted-background-color');         
      $('#video_attributions').addClass('untrusted');         
    }
    else if (params.video_trusted == EOL.Curation.UNKNOWN_ID){
      $('#video-notes').addClass('unknown-background-text');
      $('#video-player').addClass('unknown-background-color');         
      $('#video_attributions').addClass('unknown');         
    }

    license_info='COPYRIGHT: ';
    if (params.license_text != '') {
        license_info += params.license_text;
    }
    if (params.license_logo != '') {
        license_info += '&nbsp;&nbsp;<a href="' + params.license_link + '" class="external_link"><img src="' + params.license_logo + '" border="0"></a>';
    }

    video_notes_area = '';
    video_notes_area += params.title +'<br /><br />';
    if (license_info != '') {video_notes_area += license_info + '<br />';}

    data_supplier      = params.video_data_supplier;
    data_supplier_name = params.video_supplier_name;
    data_supplier_url  = params.video_supplier_url;
    if (data_supplier != '') {
      if (data_supplier_url != '') {
       video_notes_area += 'SUPPLIER: <a href="'+data_supplier_url+'" class="external_link">' + data_supplier + ' <img alt="external link" src="/images/external_link.png"></a> ' + params.video_supplier_icon + '<br />';
      } else { 
        video_notes_area += 'SUPPLIER: ' + data_supplier + '<br />';
      }
    }

    if (params.author != '') {video_notes_area += 'AUTHOR: ' + params.author + '<br />';}
    if (params.collection != '') {video_notes_area += 'SOURCE: ' + params.collection + '<br />';}
    video_notes_area += params.field_notes ? '<br />' + params.field_notes : '';

    $('#video-notes').html = video_notes_area;

    return false;
}
