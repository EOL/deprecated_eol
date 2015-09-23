module Refable
  def add_ref(reference)
    if reference.strip != ''
      ref = Ref.find_by_full_reference_and_user_submitted_and_published_and_visibility_id(reference, 1, 1, Visibility.get_visible.id)
      if (ref)
        self.refs << ref
      else
        self.refs << Ref.new(full_reference: reference, user_submitted: true, published: 1, visibility: Visibility.get_visible)
      end        
    end    
  end
end
