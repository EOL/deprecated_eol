if(!EOL) var EOL = {};
if(!EOL.MediaCenter) EOL.MediaCenter = {};

EOL.MediaCenter.image_hash = {};

EOL.MediaCenter.update_thumbnail_icons = function(element) {
  data_object_id = element.readAttribute('data-data_object_id');
  image = EOL.MediaCenter.image_hash[data_object_id];

  $$('a#thumbnail_'+data_object_id+' .inappropriate_icon')[0].hide();
  $$('a#thumbnail_'+data_object_id+' .invisible_icon')[0].hide();
  $$('a#thumbnail_'+data_object_id+' .unpublished_icon')[0].hide();
  $$('a#thumbnail_'+data_object_id+' .published_icon')[0].hide();

  if (image.published_by_agent){
    $$('a#thumbnail_'+data_object_id+' .published_icon')[0].show();
  } else if(!image.published) {
    $$('a#thumbnail_'+data_object_id+' .unpublished_icon')[0].show();
  }

  if (image.visibility_id == EOL.Curation.INVISIBLE_ID) {
    $$('a#thumbnail_'+data_object_id+' .invisible_icon')[0].show();
  } else if (image.visibility_id == EOL.Curation.INAPPROPRIATE_ID) {
    $$('a#thumbnail_'+data_object_id+' .inappropriate_icon')[0].show();
  }
};

EOL.MediaCenter.Behaviors = {
};
