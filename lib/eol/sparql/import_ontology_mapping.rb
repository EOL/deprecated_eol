module EOL
  module Sparql
    class ImportOntologyMapping < EOL::Sparql::Importer

      # this creates a named graph with some ontology mapping rules
      # in virtuoso you can run this to create a rule set:
      #    rdfs_rule_set ('http://eol.org/ontology_mappings', 'http://eol.org/ontology_mappings');
      # you can delete a rule set with:
      #    delete from sys_rdf_schema where RS_NAME='http://eol.org/ontology_mappings';
      # learn more at http://docs.openlinksw.com/virtuoso/rdfsparqlrule.html

      def initialize(options={})
        super(options)
        self.graph_name ||= "http://eol.org/ontology_mappings"
      end

      def begin
        sparql_client.delete_graph(graph_name)
        data = []
        data << "<http://adw.org/hasPredator> owl:inverseOf <http://adw.org/preysOn>"
        data << "<http://bioinfo.org/builds_nest_using> owl:inverseOf <http://bioinfo.org/is_used_to_build_or_strengthen_the_nest_by>"
        data << "<http://bioinfo.org/causes_gall_of> owl:inverseOf <http://bioinfo.org/is_galled_by>"
        data << "<http://bioinfo.org/causes_galls_on> owl:inverseOf <http://bioinfo.org/is_galled_by>"
        data << "<http://bioinfo.org/causes_shot_holes_on> owl:inverseOf <http://bioinfo.org/has_leaves_shot_holed_by>"
        data << "<http://bioinfo.org/causes_spots_on> owl:inverseOf <http://bioinfo.org/is_spotted_by>"
        data << "<http://bioinfo.org/causes_swelling_of> owl:inverseOf <http://bioinfo.org/is_swollen_by>"
        data << "<http://bioinfo.org/collects> owl:inverseOf <http://bioinfo.org/is_collected_by>"
        data << "<http://bioinfo.org/ectoparasitises> owl:inverseOf <http://bioinfo.org/is_ectoparasitised_by>"
        data << "<http://bioinfo.org/endoparasitises> owl:inverseOf <http://bioinfo.org/is_endoparasitised_by>"
        data << "<http://bioinfo.org/endophyte_within> owl:inverseOf <http://bioinfo.org/may_house_endophytic>"
        data << "<http://bioinfo.org/feeds_from_immobile_silken_tube_on> owl:inverseOf <http://bioinfo.org/is_grazed_by_fixed_silken_tube-dwelling>"
        data << "<http://bioinfo.org/feeds_from_web_on> owl:inverseOf <http://bioinfo.org/is_grazed_by_web-dwelling>"
        data << "<http://bioinfo.org/feeds_on> owl:inverseOf <http://bioinfo.org/is_food_source_of>"
        data << "<http://bioinfo.org/feeds_on> owl:inverseOf <http://bioinfo.org/may_contain>"
        data << "<http://bioinfo.org/feeds_on_dead> owl:inverseOf <http://bioinfo.org/dead_is_eaten_by>"
        data << "<http://bioinfo.org/feeds_on_dung/debris> owl:inverseOf <http://bioinfo.org/dung/debris_may_support>"
        data << "<http://bioinfo.org/feeds_on_honeydew> owl:inverseOf <http://bioinfo.org/honeydew_may_support>"
        data << "<http://bioinfo.org/feeds_within> owl:inverseOf <http://bioinfo.org/may_contain>"
        data << "<http://bioinfo.org/grazes_in_mobile_case_on> owl:inverseOf <http://bioinfo.org/is_grazed_by_mobile_cased>"
        data << "<http://bioinfo.org/grazes_on> owl:inverseOf <http://bioinfo.org/is_grazed_by>"
        data << "<http://bioinfo.org/grows_among> owl:inverseOf <http://bioinfo.org/may_house>"
        data << "<http://bioinfo.org/grows_inside> owl:inverseOf <http://bioinfo.org/may_house>"
        data << "<http://bioinfo.org/grows_on> owl:inverseOf <http://bioinfo.org/may_have_epiphytic>"
        data << "<http://bioinfo.org/grows_on_or_over> owl:inverseOf <http://bioinfo.org/may_be_grown_over_by>"
        data << "<http://bioinfo.org/hibernates_inside> owl:inverseOf <http://bioinfo.org/may_house_hibernating>"
        data << "<http://bioinfo.org/hitches_a_ride_on> owl:inverseOf <http://bioinfo.org/may_give_a_ride_to>"
        data << "<http://bioinfo.org/infects> owl:inverseOf <http://bioinfo.org/may_be_infected_by>"
        data << "<http://bioinfo.org/infects_and_damages> owl:inverseOf <http://bioinfo.org/may_be_infected_and_damaged_by>"
        data << "<http://bioinfo.org/inhabits_dung_of> owl:inverseOf <http://bioinfo.org/dung_may_contain>"
        data << "<http://bioinfo.org/inhibits> owl:inverseOf <http://bioinfo.org/is_inhibited_by>"
        data << "<http://bioinfo.org/is_a_guest_in> owl:inverseOf <http://bioinfo.org/has_guest>"
        data << "<http://bioinfo.org/is_associated_with> owl:inverseOf <http://bioinfo.org/is_associate_of>"
        data << "<http://bioinfo.org/is_cross-fertilised_by> owl:inverseOf <http://bioinfo.org/cross-fertilises>"
        data << "<http://bioinfo.org/is_ectomycorrhizal_with> owl:inverseOf <http://bioinfo.org/is_ectomycorrhizal_host_of>"
        data << "<http://bioinfo.org/is_ectoparasitoid_of> owl:inverseOf <http://bioinfo.org/is_ectoparasitoid_host_of>"
        data << "<http://bioinfo.org/is_endomycorrhizal_with> owl:inverseOf <http://bioinfo.org/is_endomycorrhizal_host_of>"
        data << "<http://bioinfo.org/is_endoparasitoid_of> owl:inverseOf <http://bioinfo.org/is_endoparasitoid_host_of>"
        data << "<http://bioinfo.org/is_hemiparasitic_on> owl:inverseOf <http://bioinfo.org/is_parasitised_by>"
        data << "<http://bioinfo.org/is_inquiline_in> owl:inverseOf <http://bioinfo.org/with_inquiline>"
        data << "<http://bioinfo.org/is_mutualistic_with> owl:inverseOf <http://bioinfo.org/is_mutualistic_with>"
        data << "<http://bioinfo.org/is_mycorrhizal_with> owl:inverseOf <http://bioinfo.org/is_mycorrhizal_host_of>"
        data << "<http://bioinfo.org/is_parasitoid_of> owl:inverseOf <http://bioinfo.org/is_parasitoid_host_of>"
        data << "<http://bioinfo.org/is_predator_of> owl:inverseOf <http://bioinfo.org/is_predated_by>"
        data << "<http://bioinfo.org/is_saprobic_in/on_dung_or_excretions_of> owl:inverseOf <http://bioinfo.org/dung_may_support>"
        data << "<http://bioinfo.org/is_saprobic_on> owl:inverseOf <http://bioinfo.org/is_decayed_by>"
        data << "<http://bioinfo.org/is_spread_by> owl:inverseOf <http://bioinfo.org/spreads>"
        data << "<http://bioinfo.org/kleptoparasitises> owl:inverseOf <http://bioinfo.org/is_kleptoparasitised_by>"
        data << "<http://bioinfo.org/lives_on> owl:inverseOf <http://bioinfo.org/is_lived_on_by>"
        data << "<http://bioinfo.org/lives_on/in> owl:inverseOf <http://bioinfo.org/may_support>"
        data << "<http://bioinfo.org/lives_within> owl:inverseOf <http://bioinfo.org/is_inhabited_by>"
        data << "<http://bioinfo.org/makes_a_slave_of> owl:inverseOf <http://bioinfo.org/may_be_a_slave_of>"
        data << "<http://bioinfo.org/may_be_found_among> owl:inverseOf <http://bioinfo.org/may_house>"
        data << "<http://bioinfo.org/may_be_found_in> owl:inverseOf <http://bioinfo.org/may_house>"
        data << "<http://bioinfo.org/may_be_found_on> owl:inverseOf <http://bioinfo.org/may_have>"
        data << "<http://bioinfo.org/may_be_found_under> owl:inverseOf <http://bioinfo.org/may_shelter>"
        data << "<http://bioinfo.org/may_have_as_photobiont> owl:inverseOf <http://bioinfo.org/may_be_a_photobiont_of>"
        data << "<http://bioinfo.org/mines> owl:inverseOf <http://bioinfo.org/is_mined_by>"
        data << "<http://bioinfo.org/overwinters_on> owl:inverseOf <http://bioinfo.org/may_house_hibernating>"
        data << "<http://bioinfo.org/overwinters_under> owl:inverseOf <http://bioinfo.org/may_shelter_hibernating>"
        data << "<http://bioinfo.org/parasitises> owl:inverseOf <http://bioinfo.org/is_parasitised_by>"
        data << "<http://bioinfo.org/pollenates_or_fertilises> owl:inverseOf <http://bioinfo.org/is_pollenated_or_fertilised_by>"
        data << "<http://bioinfo.org/provisions_nest_with> owl:inverseOf <http://bioinfo.org/is_collected_to_provision_nest_of>"
        data << "<http://bioinfo.org/rests_inside> owl:inverseOf <http://bioinfo.org/accommodates>"
        data << "<http://bioinfo.org/robs> owl:inverseOf <http://bioinfo.org/is_robbed_by>"
        data << "<http://bioinfo.org/rolls> owl:inverseOf <http://bioinfo.org/is_rolled_by>"
        data << "<http://bioinfo.org/secondarily_infects> owl:inverseOf <http://bioinfo.org/may_be_secondarily_infected_by>"
        data << "<http://bioinfo.org/sequestrates> owl:inverseOf <http://bioinfo.org/is_sequestrated_by>"
        data << "<http://bioinfo.org/spins> owl:inverseOf <http://bioinfo.org/is_spun_by>"
        data << "<http://bioinfo.org/spreads_or_disperses> owl:inverseOf <http://bioinfo.org/is_spread_or_dispersed_by>"
        data << "<http://bioinfo.org/stocks_nest_with> owl:inverseOf <http://bioinfo.org/is_taken_to_the_nest_of>"
        data << "<http://bioinfo.org/sucks_sap_of> owl:inverseOf <http://bioinfo.org/has_sap_sucked_by>"
        data << "<http://bioinfo.org/sucks_the_blood_of> owl:inverseOf <http://bioinfo.org/has_blood_sucked_by>"
        data << "<http://bioinfo.org/sucks_the_sweat_of> owl:inverseOf <http://bioinfo.org/has_sweat_sucked_by>"
        data << "<http://bioinfo.org/takes_over> owl:inverseOf <http://bioinfo.org/is_taken_over_by>"
        data << "<http://bioinfo.org/visits_for_nectar_and/or_pollen> owl:inverseOf <http://bioinfo.org/is_visited_for_nectar_and/or_pollen_by>"

        sparql_client.insert_data(:data => data, :graph_name => graph_name)
      end
    end
  end
end