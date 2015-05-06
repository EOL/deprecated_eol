module Refable
  def add_ref(reference)
    if reference.strip != ''
      ref = Ref.find_by_full_reference_and_user_submitted_and_published_and_visibility_id(reference, 1, 1, $visible_global.id)
      if (ref)
        self.refs << ref
      else
        self.refs << Ref.new(full_reference: reference, user_submitted: true, published: 1, visibility: $visible_global)
      end        
    end    
  end
end
