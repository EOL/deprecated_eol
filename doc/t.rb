# This is a temp file used for notes. Ignore it entirely!
@resource = Resource.find(544)
@event = @resource.harvest_events.last
@event.publish
