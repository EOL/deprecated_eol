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

function textCounter(field,cntfield,maxlimit) {
	if (field.value.length > maxlimit) // if too long...trim it!
		field.value = field.value.substring(0, maxlimit);
	else // otherwise, update 'characters left' counter
		cntfield.html(maxlimit - field.value.length + ' remaining');
}

// update the content area
function eol_update_content_area(taxon_concept_id, category_id, allow_user_text) {
    if($('#insert_text_popup')) {
      EOL.popup_links['new_text_toc_text'].popup.toggle();
    }
    $.ajax(
      url: '/taxa/content/',
      data: { id: taxon_concept_id, category_id: category_id },         
      complete:function(request){hideAjaxIndicator(true);updateReferences();},
      success:function(request){hideAjaxIndicator(true);updateReferences();},
      error: function(request){hideAjaxIndicator(true);},
      beforeSend:function(request){showAjaxIndicator(true);},
    );
    $('#toc .active').addClass('toc_item');
}

// show the pop-up in the div 
function eol_show_pop_up(div_name, partial_name, taxon_name) {
  if (partial_name==null) partial_name=div_name;
  if (taxon_name==null) taxon_name='';
  $.ajax(
    url: '/taxa/show_popup',
    type: 'POST', 
    complete:function(request){hideAjaxIndicator();EOL.Effect.toggle_with_effect(div_name);},
    beforeSend:function(request){showAjaxIndicator();},
    success:function(result){$('#'+div_name).html(result);},
    data:{name: partial_name, taxon_name: taxon_name}
  );
}

// Displays the Photosynth interface in the image pane.
function load_photosynth_interface(source_url)
{
  // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
  synth = "<table id='main-image-table'><tr><td><iframe frameborder='0' src='" + source_url.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe><img id='main-image'></td></tr></table>";
  $('#main-image-bg').html = synth;  
}

// Updates the main image and calls eol_update_credit()
function eol_update_image(large_image_url, params) {

  /* Working if u want to see the Photosynth interface right away after clicking on a thumbnail
  var string = params.source_url;//source_url is from [views/taxa/_image_collection]
  if(string.search(/photosynth.net/) == -1)
  { //regular static image
    $('#main-image-bg').innerHTML = "<img id='main-image'>";      
    $('#main-image').src = large_image_url;
    $('#main-image').alt=params.nameString;
    $('#main-image').title=params.nameString;    
  }
  else
  { //photosynth image
    // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
    synth = "<iframe frameborder='0' src='" + string.replace("view.aspx", "embed.aspx") + "&delayLoad=true&slideShowPlaying=false' width='425' height='355'></iframe><img id='main-image'>";
    $('#main-image-bg').innerHTML = synth;  
  }
  */  

  // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
  $('#main-image-bg').html = "<table id='main-image-table'><tr><td><img id='main-image'></td></tr></table>";                
  $('#main-image').attr('src', large_image_url);
  $('#main-image').attr('alt', params.nameString);
  $('#main-image').attr('title', params.nameString);

  // This will display a photosynth icon if a thumbnail photosynth image is clicked.
  var string = params.source_url; //source_url is from [views/taxa/_image_collection]
  if(string.search(/photosynth.net/) == -1) { //regular static image    
      $('#photosynth-message').html = "";          
  } else { //photosynth image
    // TODO - put this in the view, and just show/hide it.  We don't want HTML here.
    $('#photosynth-message').html = "<a href=javascript:load_photosynth_interface('" + escape(params.source_url) + "')><img src='http://mslabs-999.vo.llnwd.net/e1/inc/images/master/logo.png' height='27' alt='Photosynth' title='Image is part of a Photosynth'></a>";    
  }

  // update the hrefs for the comment, curation, etc popups
  $('div#large-image-trust-button a').each(function() {
    if (!params.curated) {
      this.attr('href', "/data_objects/"+params.data_object_id+"/curate?_method=put&curator_activity_id=3");
      this.attr('href', "/data_objects/"+params.data_object_id+"/curate?_method=put&curator_activity_id=7");
      this.attr('data-data_object_id', params.data_object_id);
      this.attr('data-data_object_id', params.data_object_id);

      $('#large-image-trust-button').fadeIn();
      $('#large-image-untrust-button').fadeIn();
    } else {
      $('#large-image-trust-button').fadeOut();
      $('#large-image-untrust-button').fadeOut();
    }
  });
  $('#large-image-comment-button-popup-link').attr('href', "/data_objects/" + params.data_object_id + "/comments");
  $('#large-image-attribution-button-popup-link').attr('href', "/data_objects/" + params.data_object_id + "/attribution"); 
  $('#large-image-tagging-button-popup-link').attr('href', "/data_objects/" + params.data_object_id + "/tags"); 
  $('#large-image-curator-button-popup-link').attr('href', "/data_objects/" + params.data_object_id + "/curation");

  //update star rating links
  $('div.image-rating ul.user-rating a.one-star').attr('href', '/data_objects/rate/' + params.data_object_id +'?stars=1');
  $('div.image-rating ul.user-rating a.one-star').attr('data-data_object_id', params.data_object_id);
  $('div.image-rating ul.user-rating a.two-stars').attr('href', '/data_objects/rate/' + params.data_object_id +'?stars=2');
  $('div.image-rating ul.user-rating a.two-stars').attr('data-data_object_id', params.data_object_id);
  $('div.image-rating ul.user-rating a.three-stars').attr('href', '/data_objects/rate/' + params.data_object_id +'?stars=3');
  $('div.image-rating ul.user-rating a.three-stars').attr('data-data_object_id', params.data_object_id);
  $('div.image-rating ul.user-rating a.four-stars').attr('href', '/data_objects/rate/' + params.data_object_id +'?stars=4');
  $('div.image-rating ul.user-rating a.four-stars').attr('data-data_object_id', params.data_object_id);
  $('div.image-rating ul.user-rating a.five-stars').attr('href', '/data_objects/rate/' + params.data_object_id +'?stars=5');
  $('div.image-rating ul.user-rating a.five-stars').attr('data-data_object_id', params.data_object_id);

  EOL.Rating.update_average_image_rating(params.data_object_id, params.average_rating);

  EOL.Rating.update_user_image_rating(params.data_object_id, params.user_rating);

  eol_update_credit(params);

  return false;
}

// Updates the image credit box
//
// TODO - this should be fetched from the server-side ... way too much HTML generation in the javascript
//
// ... this updates abunchof stuff and is pretty disorganized  :(
//
function eol_update_credit(params){

  // ! FIELD NOTES ! <start> NOTE: this should really be moved into a partial on the server side!
  field_notes_area = '';

  if (params.taxaIDs.length > 0 ) {
    var current_page_name_or_id = parseInt(window.location.toString().sub(/.*\//,'').sub(/\?.*/,''));
    var other_taxon_concept_index = null;
    // loop thru and find a taxa that's NOT the current page's taxa
    // if the image IS linked to the current taxa then don't show an alternative
    for(var i=0; i<params.taxaIDs.length; i++)
    {
        if(parseInt(params.taxaIDs[i]) == current_page_name_or_id) {
            other_taxon_concept_index = null;
            break;
        }else if(other_taxon_concept_index == null) {
            other_taxon_concept_index = i;
        }
    }


    // if it exists, show it ...
    if ( other_taxon_concept_index != null ) {
      field_notes_area += 'Image of <a href="/pages/' + params.taxaIDs[other_taxon_concept_index] + '">' + params.taxaNames[other_taxon_concept_index] + '</a><br />';
    }
  }
  license_info='COPYRIGHT: ';
  if (params.license_text != '') {
      license_info += params.license_text;
  }
  if (params.license_logo != '') {
      license_info += '&nbsp;&nbsp;<a href="' + params.license_link + '"  class="external_link"><img src="' + params.license_logo + '" border="0"></a>';
  }
  field_notes_area += license_info+'<br />'

  if (params.data_supplier != '') {
    if (params.data_supplier_url != '') {
  field_notes_area += 'SUPPLIER: <a href="'+params.data_supplier_url+'" class="external_link">' + params.data_supplier + ' <img alt="external link" src="/images/external_link.png"></a> ' + params.data_supplier_icon  + '<br />';
    } else { 
      field_notes_area += 'SUPPLIER: ' + params.data_supplier + '<br />';
    }
  }
  if (params.authors_linked != '') {
      field_notes_area += 'AUTHOR: ' + params.authors_linked + '<br />';
  }
  if (params.sources != '' && params.info_url != '' && params.info_url != null) {
  field_notes_area += 'SOURCE: <a href="'+params.info_url+'" class="external_link">' +  params.sources + ' <img alt="external link" src="/images/external_link.png"></a><br />';
  }
  else if (params.sources_linked != '') {
      field_notes_area += 'SOURCE:' + params.sources_linked + '<br />';
  }   
  if (params.sources_icons_linked != '') {
      field_notes_area += params.sources_icons_linked + '<br />';
  }
  field_notes_area += '<br /><br />';
  field_notes_area += params.field_notes ? params.field_notes : "";				

  $('#large-image-button-group .published_icon').hide();
  $('#large-image-button-group .unpublished_icon').hide();
  $('#large-image-button-group .inappropriate_icon').hide();
  $('#large-image-button-group .invisible_icon').hide();

  if (params.published_by_agent){
    $('#large-image-button-group .published_icon').show();
  } else if(!params.published) {
    $('#large-image-button-group .unpublished_icon').show();
  }

  if (params.visibility_id == EOL.Curation.INVISIBLE_ID) {
    $('#large-image-button-group .invisible_icon').show();
  } else if (params.visibility_id == EOL.Curation.INAPPROPRIATE_ID) {
    $('#large-image-button-group .inappropriate_icon').show();
  }

  $('#large-image-attribution-button').removeClass('unknown');
  $('#large-image-attribution-button').removeClass('untrusted');
  $('#mc-notes').removeClass('unknown-background-text');
  $('#mc-notes').removeClass('untrusted-background-text');
  $('#main-image-bg').removeClass('unknown-background-image');
  $('#main-image-bg').removeClass('untrusted-background-image');

  if (params.vetted_id == EOL.Curation.UNKNOWN_ID) {
    $('#mc-notes').addClass('unknown-background-text');
    $('#main-image-bg').addClass('unknown-background-image');
    $('#large-image-attribution-button').addClass('unknown');
    field_notes_area += '<br /><br /><strong>Note:</strong> The image from this source has not been reviewed.';
  } else if (params.vetted_id == EOL.Curation.UNTRUSTED_ID) {
    $('#mc-notes').addClass('untrusted-background-text');
    $('#main-image-bg').addClass('untrusted-background-image');
    $('#large-image-attribution-button').addClass('untrusted');
    field_notes_area += '<br /><br /><strong>Note:</strong> The image from this source is not trusted.';
  }

  $('#field-notes').innerHTML = field_notes_area; // this is the 'gray box'
  // ! FIELD NOTES ! </end>

}

// Updates the main image and calls eol_update_credit()
function eol_update_video(params) {
    $('div#media-videos div.attribution_link').show();
    for(var i in EOL.popups) {
      EOL.popups[i].destroy();
    }
    $('#video_attributions').attr('href', "/data_objects/" + params.data_object_id + "/attribution");

    $.ajax(
      url: '/taxa/show_video/',
      data: { video_type: params.video_type, video_url: params.video_url, video_mime_type_id: params.mime_type_id, data_object_id: params.data_object_id, video_object_cache_url: params.object_cache_url },
      complete:function(request){hideAjaxIndicator();},
      beforeSend:function(request){showAjaxIndicator();},
    );

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

    $('#video-notes').innerHTML = video_notes_area;

    return false;
}

function displayNode(id) {
	displayNode(id, false);
}

// call remote function to show the selected node in the text-based navigational tree view
function displayNode(id, for_selection) {
	url = '/navigation/show_tree_view'
	if(for_selection) {
		url = '/navigation/show_tree_view_for_selection'
	}
  $.ajax(
      type: 'POST', 
      complete: function(){hideAjaxIndicator();},
      beforeSend: function(){showAjaxIndicator();},
      success: function(response){$('#browser-text').html(response);},
      data: {id: id}
  );
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser(hierarchy_entry_id, expand) {
  url = '/navigation/browse'
  $.ajax(
    url: url,
    type: 'POST', 
    complete: function(){hideAjaxIndicator(); scroll(0,100);},
    beforeSend: function(){showAjaxIndicator();},
    success: function(response){$('#hierarchy_browser').html(response);},
    data: {id: hierarchy_entry_id, expand: expand }
  );
}

// call remote function to show the selected node in the text-based navigational tree view
function update_browser_stats(hierarchy_entry_id, expand) {
    url = '/navigation/browse_stats'
    new Ajax.Updater(
    'hierarchy_browser', url,
      {
        asynchronous:true, 
        evalScripts:true, 
        method:'post', 
        onComplete:function(request){hideAjaxIndicator(); scroll(0,100);},
        onLoading:function(request){showAjaxIndicator();},
        parameters: {id: hierarchy_entry_id, expand: expand }
      } );
}

// for re-rendering TOC
function refresh_toc() {
    jquery_post(null, '/administrator/table_of_contents/show_tree', $('#edit_toc'));
}
function toc_move_up(toc_id, top) {
    jquery_post("id="+toc_id+"&top="+top, '/administrator/table_of_contents/move_up', $('#edit_toc'));
}
function toc_move_down(toc_id, bottom) {
    jquery_post("id="+toc_id+"&bottom="+bottom, '/administrator/table_of_contents/move_down', $('#edit_toc'));
}
function toc_add_sub_chapter(parent_id, input_id) {
    input_value = $("#"+input_id).val();
    if(input_value == '') {
        alert('You must enter a sub-chapter label');
        return false;
    }else {
        jquery_post("label="+input_value+"&parent_id="+parent_id, '/administrator/table_of_contents/create', $('#edit_toc'));
    }
}
function toc_add_chapter(input_id) {
    input_value = $("#"+input_id).val();
    if(input_value == '') {
        alert('You must enter a chapter label');
        return false;
    }else {
        jquery_post("label="+input_value+"&parent_id=0", '/administrator/table_of_contents/create', $('#edit_toc'));
    }
}
function toc_edit_label(toc_id, toc_label) {
    new_html = '<input id="toc_edit_label_'+toc_id+'" type="text" size="40" value="'+ toc_label +'">';
    new_html+= '<a href="" onclick="submit_new_label('+toc_id+', \'toc_edit_label_'+toc_id+'\'); return false;"><img title="edit" style="float: right;" src="/images/checked.png" alt="edit"></a>';
    $("#toc_label_"+toc_id).html(new_html);
}
function submit_new_label(toc_id, input_id) {
    input_value = $("#"+input_id).val();
    if(input_value == '') {
        alert('You must enter a new label');
        return false;
    }else {
        jquery_post("id="+toc_id+"&label="+input_value, '/administrator/table_of_contents/update', $('#edit_toc'));
    }
}

function jquery_post(data, url, target)
{
    $.ajax({
      type: "POST",
      url: url,
      data: data,
      beforeSend: function(request) {showAjaxIndicator();},
      success: function(data) {
        target.html(data);
      },
      complete: function(request) {hideAjaxIndicator();}
    });
}


function toggle_children() {
    Element.toggle('taxonomic-children');
    if ($('#toggle_children_link').innerHTML=='-') {
        $('#toggle_children_link').innerHTML='+';
    }
    else
    {
        $('#toggle_children_link').innerHTML='-';
    }
}

// DEPRECATED!  let's use EOL.Ajax.start() / .finish()
function showAjaxIndicator(on_content_area) {
    on_content_area = on_content_area || false
    if (on_content_area)
    {
        Element.show('center-page-content-loading');
    }
    Element.show('ajax-indicator');
}
function hideAjaxIndicator(on_content_area) {
    on_content_area = on_content_area || false    
    if (on_content_area)
    {
        Element.hide('center-page-content-loading');
    }    
    Element.hide('ajax-indicator');        
}

function taxon_comments_permalink(comment_id) {
  $(document).ready(function() {
    EOL.load_taxon_comments_tab({page_to_comment_id: comment_id});
    $('#media-images').hide();
    $('#image').children().removeClass('active');
    $('#taxa-comments').children().addClass('active');
  });
  $('#tab_media_center li').children().click(function() {
    $('#media-taxa-comments').hide();
  });
}

function text_comments_permalink(data_object_id, text_comment_id, comment_page) {
  $(document).ready(function(e) {
    textComments        = "text-comments-" + data_object_id;
    textCommentsWrapper = "text-comments-wrapper-" + data_object_id;
    if ($(textCommentsWrapper).style.display == 'none') {
      new Ajax.Updater(textComments, '/data_objects/'+data_object_id+'/comments',
                       {asynchronous:true, evalScripts:true, method:'get',
                        parameters: { body_div_name: textComments,
                          comment_id: text_comment_id, 
                          page: comment_page},
                        onLoading: Effect.BlindDown(textCommentsWrapper),
                        onComplete: function() {
                          $('#comment_'+text_comment_id).scrollTo();
                         }
                        });
      } else {
        Effect.DropOut(textCommentsWrapper);
      }
      e.stop();
  });
}
