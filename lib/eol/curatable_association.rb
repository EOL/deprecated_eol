module EOL
  module CuratableAssociation

    def curate(user, opts)
      vetted_id = opts[:vetted_id]
      visibility_id = opts[:visibility_id]
      curation_comment = opts[:curation_comment]

      raise "Curator should supply at least visibility or vetted information" unless (vetted_id || visibility_id || curation_comment)
      if opts[:curate_vetted_status]
        if vetted_id
          case vetted_id.to_i
          when Vetted.untrusted.id
            raise "Curator should supply at least untrust reason(s) and/or curation comment" if (opts[:untrust_reason_ids].blank? && curation_comment.blank?)
            untrust(user, opts)
          when Vetted.trusted.id
            trust(user, opts)
          when Vetted.unknown.id
            unreviewed(user, opts)
          else
            raise "Cannot set data object vetted id to #{vetted_id}"
          end
        end
      end

      if opts[:curate_visibility_status]
        if visibility_id
          changeable_object_type = opts[:changeable_object_type]
          case visibility_id.to_i
          when Visibility.visible.id
            show(user, opts[:type], changeable_object_type)
          when Visibility.invisible.id
            hide(user, opts[:type], changeable_object_type)
          when Visibility.inappropriate.id
            inappropriate(user, opts[:type], changeable_object_type)
          else
            raise "Cannot set data object visibility id to #{visibility_id}"
          end
        end
      end
    end

    def show(user, type, changeable_object_type)
      set_visibility(user, Visibility.visible.id, :show, I18n.t("dato_shown_note", :username => user.username, :type => data_object.data_type.simple_type), changeable_object_type)
    end

    def hide(user, type, changeable_object_type)
      set_visibility(user, Visibility.invisible.id, :hide, I18n.t("dato_hidden_note", :username => user.username, :type => data_object.data_type.simple_type), changeable_object_type)
    end

    def inappropriate(user, type, changeable_object_type)
      set_visibility(user, Visibility.inappropriate.id, :inappropriate, I18n.t(:dato_inappropriate_note, :username => user.username, :type => data_object.data_type.simple_type), changeable_object_type)
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

  private

    def trust(user, opts = {})
      update_attributes({:vetted_id => Vetted.trusted.id})
      user.track_curator_activity(curator_activity_object(opts[:changeable_object_type]), opts[:changeable_object_type], 'trusted', :comment => opts[:comment], :taxon_concept_id => opts[:taxon_concept_id])
    end

    def untrust(user, opts = {})
      untrust_reason_ids = opts[:untrust_reason_ids].is_a?(Array) ? opts[:untrust_reason_ids] : []
      untrust_reasons_comment = nil
      update_attributes({ :vetted_id => Vetted.untrusted.id })
      these_untrust_reasons = []
      if untrust_reason_ids
        untrust_reason_ids.each do |untrust_reason_id|
          ur = UntrustReason.find(untrust_reason_id)
          # this is used to save the untrust reasons in the untrust_reasons table via track_curator_activity method
          these_untrust_reasons << ur
        end
        # TODO: This should be changed to show the proper labels using Ajax/JQuery
        untrust_reasons_comment = "Reasons to Untrust: #{these_untrust_reasons.collect{|ur| ur.label}.to_sentence}"
      end
      user.track_curator_activity(curator_activity_object(opts[:changeable_object_type]), opts[:changeable_object_type], 'untrusted', :comment => opts[:comment], :untrust_reasons => these_untrust_reasons, :taxon_concept_id => opts[:taxon_concept_id])
    end

    def unreviewed(user, opts = {})
      update_attributes({ :vetted_id => Vetted.unknown.id })
      user.track_curator_activity(curator_activity_object(opts[:changeable_object_type]), opts[:changeable_object_type], 'unreviewed', :comment => opts[:comment], :taxon_concept_id => opts[:taxon_concept_id])
    end

    def set_visibility(user, visibility_id, verb, note, changeable_object_type)
      vetted_by = user
      update_attributes({ :visibility_id => visibility_id })
      user.track_curator_activity(curator_activity_object(changeable_object_type), changeable_object_type, verb)
    end

    def curator_activity_object(changeable_object_type)
      changeable_object_type == 'data_object' ? data_object : self
    end

  end
end
