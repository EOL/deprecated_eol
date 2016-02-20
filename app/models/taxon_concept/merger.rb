class TaxonConcept
  # NOTE: this does not update collection items. You may wish to do so. ...Among
  # many other things (see various denormalization functions, in TODOs). Sigh.
  # NOTE: you may wish to run this in a transaction (if you aren't in one
  # already); that is the _caller's_ responsibility. NOTE: this returns the
  # SUPERCEDED TaxonConcept!!! Why? So you can see both the id that was
  # superceded as well as the supercedure_id to see where it went. If you're
  # calling this, you probably care about both.
  class Merger
    class << self
      def ids(id1, id2)
        tc1 = TaxonConcept.find(id1)
        return tc1 if id1 == id2
        # Always take the LOWEST id first; id1 is "kept", id2 "goes away"
        (id1, id2) = [id1, id2].sort
        raise "Missing an ID (#{id1}, #{id2})" if id1 <= 0
        raise "Cannot merge to unpublished taxon!" unless tc1.published?
        tc2 = TaxonConcept.find(id2)
        raise "Missing merge-to concept (#{id2})" unless tc2
        EOL.log("MERGE: concept #{id2} into #{id1}")
        tc2.update_attributes(supercedure_id: id1, published: false)
        HierarchyEntry.where(taxon_concept_id: id2).
          update_all(taxon_concept_id: id1)
        UsersDataObject.where(taxon_concept_id: id2).
          update_all(taxon_concept_id:id1)
        # TODO: these don't actually delete records that need to be deleted. This
        # algorithm is wrong.
        update_ignore_id(TaxonConceptName, id1, id2)
        update_ignore_id(DataObjectsTaxonConcept, id1, id2)
        update_ignore_id(TaxonConceptsFlattened, id1, id2)
        update_ignore_ancestor_id(TaxonConceptsFlattened, id1, id2)
        move_traits(id1, id2)
        TaxonConceptReindexing.reindex(tc1)
        # NOTE: this one used to also do a join to hierarchy_entries and ensure that
        # the tc id was id2. ...But that has already changed by this point, sooo...
        # that never worked. :| Also, it seems entirely superfluous. Just using the
        # tc id on that table:
        update_ignore_id(RandomHierarchyImage, id1, id2)
        tc2
      end

      def move_traits(id1, id2)
        traits = TraitBank.page_traits(id2)
        clauses = []
        traits.each do |trait|
          clauses << "#{trait[:predicate].to_ntriples} #{trait[:trait].to_ntriples}"
        end
        old_traits = clauses.map { |c| "<http://eol.org/pages/#{id2}> #{c}" }
        # TODO: we still need a delete method...
        del_q = "WITH GRAPH <#{TraitBank.graph}> DELETE "\
        "{ #{old_traits.join(" . ")} } WHERE { #{old_traits.join(" . ")} }"
        begin
          TraitBank.connection.query(del_q)
        rescue EOL::Exceptions::SparqlDataEmpty => e
          # Do nothing... this is acceptable for a delete...
        end
        new_traits = clauses.map { |c| "<http://eol.org/pages/#{id1}> #{c}" }
        TraitBank.connection.insert_data(data: new_traits,
        graph_name: TraitBank.graph)
      end

      # TODO: Rails doesn't have a way to UPDATE IGNORE ... WTF?
      def update_ignore_id(klass, id1, id2)
        EOL::Db.update_ignore_id_by_field(klass, id1, id2, "taxon_concept_id")
      end

      def update_ignore_ancestor_id(klass, id1, id2)
        EOL::Db.update_ignore_id_by_field(klass, id1, id2, "ancestor_id")
      end
    end
  end
end
