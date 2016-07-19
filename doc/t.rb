# This is a temp file used for notes. Ignore it entirely!
resource = Resource.find 267
event = resource.harvest_events.last
# resource.hierarchy.merge_matching_concepts
event.sync_collection
