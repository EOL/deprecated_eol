module EOL
  module CuratableAssociation

    def show(user)
      set_visibility(user, Visibility.get_visible.id)
    end

    def hide(user)
      set_visibility(user, Visibility.get_invisible.id)
    end

    def preview?
      visibility_id == Visibility.get_preview.id
    end

    def visible?
      visibility_id == Visibility.get_visible.id
    end

    def invisible?
      visibility_id == Visibility.get_invisible.id
    end
    alias hidden? invisible?

    def inappropriate?
      vetted_id == Vetted.inappropriate.id
    end

    def untrusted?
      vetted_id == Vetted.untrusted.id
    end

    def unknown?
      vetted_id == Vetted.unknown.id
    end
    alias unreviewed? unknown?

    def vetted?
      vetted_id == Vetted.trusted.id
    end
    alias is_vetted? vetted?
    alias trusted? vetted?

    def trust(user)
      update_attributes(:vetted_id => Vetted.trusted.id)
    end

    def untrust(user)
      update_attributes(:vetted_id => Vetted.untrusted.id)
    end

    def unreviewed(user)
      update_attributes(:vetted_id => Vetted.unknown.id)
    end

    def inappropriate(user)
      update_attributes(:vetted_id => Vetted.inappropriate.id)
    end

    def set_visibility(user, visibility_id)
      vetted_by = user
      update_attributes(:visibility_id => visibility_id)
    end

  end
end
