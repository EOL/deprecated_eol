module EOL
  module CuratableAssociation

    def show(user)
      set_visibility(user, Visibility.visible.id)
    end

    def hide(user)
      set_visibility(user, Visibility.invisible.id)
    end

    def inappropriate(user)
      set_visibility(user, Visibility.inappropriate.id)
    end

    def visible?
      visibility_id == Visibility.visible.id
    end

    def invisible?
      visibility_id == Visibility.invisible.id
    end

    def inappropriate?
      visibility_id == Visibility.inappropriate.id
    end

    def untrusted?
      vetted_id == Vetted.untrusted.id
    end

    def unknown?
      vetted_id == Vetted.unknown.id
    end

    def vetted?
      vetted_id == Vetted.trusted.id
    end
    alias is_vetted? vetted?
    alias trusted? vetted?

    def preview?
      visibility_id == Visibility.preview.id
    end

    def trust(user)
      update_attributes({:vetted_id => Vetted.trusted.id})
    end

    def untrust(user)
      update_attributes({:vetted_id => Vetted.untrusted.id})
    end

    def unreviewed(user)
      update_attributes({:vetted_id => Vetted.unknown.id})
    end

    def set_visibility(user, visibility_id)
      vetted_by = user
      update_attributes({:visibility_id => visibility_id})
    end

  end
end
