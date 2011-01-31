if (!EOL) { EOL = {}; }
// Updates the main video area... does this by building HTML. TODO - convert this to views and show/hide them.
EOL.update_video = function(params) {
    $('div#media-videos div.attribution_link').show();
    EOL.close_open_overlays();
    $('#video_attributions').attr('href', "/data_objects/" + params.data_object_id + "/attribution");

    $.ajax({
      url: '/taxa/show_video/',
      // TODO - sloppy.  With a few controller-side tweaks, we could use params directly.
      data: { data_object_id: params.data_object_id }
    });

    notes = $('#video-notes');
    player = $('#video-player');
    attributions = $('#video_attributions');

    notes.removeClass('untrusted-text unknown-text');
    player.removeClass('untrusted-video unknown-video');
    attributions.removeClass('untrusted unknown');

    if (params.trust == 'untrusted') {
      notes.addClass('untrusted-text');
      player.addClass('untrusted-video');
      attributions.addClass('untrusted');
    } else if (params.trust == 'unknown') {
      notes.addClass('unknown-text');
      player.addClass('unknown-video');
      attributions.addClass('unknown');
    }

    // TODO - i18n (really, all of this should be moved to a view and shown/hidden).
    license_info = 'COPYRIGHT: ';
    if (params.license_text != '') { license_info += params.license_text; }
    if (params.license_logo != '') {
      license_info += '&nbsp;&nbsp;<a href="'+params.license_link+
        '" class="external_link"><img src="' + params.license_logo + '" border="0"></a>';
    }

    video_notes_area = '';
    video_notes_area += params.title +'<br /><br />';
    if (license_info != '') { video_notes_area += license_info + '<br />'; }

    data_supplier      = params.video_data_supplier;
    data_supplier_name = params.video_supplier_name;
    data_supplier_url  = params.video_supplier_url;
    if (data_supplier != '') {
      // TODO - i18n
      if (data_supplier_url != '') {
        video_notes_area += 'SUPPLIER: <a href="'+data_supplier_url+
          '" class="external_link">'+data_supplier+
          ' <img alt="external link" src="/images/external_link.png"></a> '+params.video_supplier_icon+
          '<br />';
      } else {
        video_notes_area += 'SUPPLIER: ' + data_supplier + '<br />';
      }
    }

    // TODO - i18n
    if (params.author != '') { video_notes_area += 'AUTHOR: ' + params.author + '<br />'; }
    if (params.collection != '') { video_notes_area += 'SOURCE: ' + params.collection + '<br />'; }
    video_notes_area += params.field_notes ? '<br />' + params.field_notes : '';

    notes.html(video_notes_area);

    return false;
};
