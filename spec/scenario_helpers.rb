require 'spec/eol_spec_helpers'
# This gives us the ability to recalculate some DB values:
include EOL::Data
# This gives us the ability to build taxon concepts:
include EOL::Spec::Helpers

# Add some comments for testing re-harvesting preserves such things:
def add_comments_and_tags_to_reharvested_data_objects(tc)
  user = User.last
  
  # 1) create comments on text (and all the same for image)
  #   1a) one is visible, second with visible_at = NULL
  text_dato = tc.overview.last # TODO - this doesn't seem to ACTAULLY be the overview.  Fix it?
  text_dato.comment(user, 'this is a comment applied to the old overview')
  invis_comment = text_dato.comment(user, 'this is an invisible comment applied to the old overview')
  invis_comment.hide! user
  
  image_dato = tc.images.last
  image_dato.comment(user, 'this is a comment applied to the old image')
  invis_image = image_dato.comment(user, 'this is an invisible comment applied to the old image')
  invis_image.hide! user
  
  #   1b) add tags
  image_dato.tag('color', 'yellow', user)
  image_dato.tag('length', 'long', user)

  # 2) create new dato with the same guid
  new_text_dato = DataObject.build_reharvested_dato(text_dato)
  new_image_dato = DataObject.build_reharvested_dato(image_dato)  

  new_image_dato.tag('color', 'green', user)

  #   2a) a new harvest_event
  #   2b) new links in data_objects_harvest_events (should happen automatically)
  old_image_harvest_event = image_dato.harvest_events.first
  new_image_harvest_event = HarvestEvent.gen(
    :resource => old_image_harvest_event.resource
  )
  #  2c

  DataObjectsHarvestEvent.gen(
    :data_object => image_dato,
    :harvest_event => new_image_harvest_event,
    :guid => image_dato.data_objects_harvest_events.first.guid
  )

  old_text_harvest_event = text_dato.harvest_events.first
  new_text_harvest_event = HarvestEvent.gen(
    :resource => old_text_harvest_event.resource
  )

  DataObjectsHarvestEvent.gen(
    :data_object => text_dato,
    :harvest_event => new_text_harvest_event,
    :guid => text_dato.data_objects_harvest_events.first.guid
  )


  # 4) create comments on new version
  new_text_dato.comment(user, 'brand new comment on the re-harvested overview')
  invis_comment = new_text_dato.comment(user, 'and an invisible comment on the re-harvested overview')
  invis_comment.hide! user

  new_image_dato.comment(user, 'lovely comment added after re-harvesting to the image')
  invis_image = new_image_dato.comment(user, 'even wittier invisible comments on image after the harvest was redone.')
  invis_image.hide! user
end

def create_curator(tc)
  curator_for_tc = User.gen(:username => 'curator_for_tc', :password => 'password')
  curator_for_tc.approve_to_curate! tc.entry
  curator_for_tc.save!
  return curator_for_tc
end
