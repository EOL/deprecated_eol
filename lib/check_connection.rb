class CheckConnection
  def self.all_instantiable_models
    a = []
    i = AgentRole.first
    i.id if i
    a << 'AgentRole' if i
    i = Agent.first
    i.id if i
    i.full_name if i
    i.given_name if i
    i.family_name if i
    i.email if i
    i.homepage if i
    i.logo_url if i
    i.logo_cache_url if i
    i.project if i
    i.organization if i
    i.account_name if i
    i.openid if i
    i.yahoo_id if i
    i.created_at if i
    i.updated_at if i
    a << 'Agent' if i
    i = AgentsDataObject.first
    i.data_object_id if i
    i.agent_id if i
    i.agent_role_id if i
    i.view_order if i
    a << 'AgentsDataObject' if i
    i = AgentsHierarchyEntry.first
    i.hierarchy_entry_id if i
    i.agent_id if i
    i.agent_role_id if i
    i.view_order if i
    a << 'AgentsHierarchyEntry' if i
    i = AgentsSynonym.first
    i.synonym_id if i
    i.agent_id if i
    i.agent_role_id if i
    i.view_order if i
    a << 'AgentsSynonym' if i
    i = Audience.first
    i.id if i
    a << 'Audience' if i
    i = CanonicalForm.first
    i.id if i
    i.string if i
    i.name_id if i
    a << 'CanonicalForm' if i
    i = ChangeableObjectType.first
    i.id if i
    i.ch_object_type if i
    i.created_at if i
    i.updated_at if i
    a << 'ChangeableObjectType' if i
    i = ClassificationCuration.first
    i.id if i
    i.exemplar_id if i
    i.source_id if i
    i.target_id if i
    i.user_id if i
    i.forced if i
    i.error if i
    i.completed_at if i
    i.created_at if i
    i.updated_at if i
    a << 'ClassificationCuration' if i
    i = CollectionItem.first
    i.id if i
    i.name if i
    i.object_type if i
    i.object_id if i
    i.collection_id if i
    i.created_at if i
    i.updated_at if i
    i.annotation if i
    i.added_by_user_id if i
    i.sort_field if i
    a << 'CollectionItem' if i
    i = CollectionType.first
    i.id if i
    i.parent_id if i
    i.lft if i
    i.rgt if i
    a << 'CollectionType' if i
    i = CollectionTypesHierarchy.first
    i.collection_type_id if i
    i.hierarchy_id if i
    a << 'CollectionTypesHierarchy' if i
    i = Collection.first
    i.id if i
    i.name if i
    i.special_collection_id if i
    i.published if i
    i.created_at if i
    i.updated_at if i
    i.logo_cache_url if i
    i.logo_file_name if i
    i.logo_content_type if i
    i.logo_file_size if i
    i.description if i
    i.sort_style_id if i
    i.relevance if i
    i.view_style_id if i
    i.show_references if i
    a << 'Collection' if i
    i = Comment.first
    i.id if i
    i.user_id if i
    i.parent_id if i
    i.parent_type if i
    i.body if i
    i.visible_at if i
    i.created_at if i
    i.updated_at if i
    i.from_curator if i
    i.hidden if i
    i.reply_to_type if i
    i.reply_to_id if i
    i.deleted if i
    a << 'Comment' if i
    i = Community.first
    i.id if i
    i.name if i
    i.description if i
    i.created_at if i
    i.updated_at if i
    i.logo_cache_url if i
    i.logo_file_name if i
    i.logo_content_type if i
    i.logo_file_size if i
    i.published if i
    a << 'Community' if i
    i = ContactRole.first
    i.id if i
    a << 'ContactRole' if i
    i = ContactSubject.first
    i.id if i
    i.recipients if i
    i.active if i
    i.created_at if i
    i.updated_at if i
    a << 'ContactSubject' if i
    i = Contact.first
    i.id if i
    i.contact_subject_id if i
    i.name if i
    i.email if i
    i.comments if i
    i.ip_address if i
    i.referred_page if i
    i.user_id if i
    i.created_at if i
    i.updated_at if i
    i.taxon_group if i
    a << 'Contact' if i
    i = ContentPageArchive.first
    i.id if i
    i.content_page_id if i
    i.page_name if i
    i.content_section_id if i
    i.sort_order if i
    i.original_creation_date if i
    i.created_at if i
    i.updated_at if i
    i.open_in_new_window if i
    i.last_update_user_id if i
    i.parent_content_page_id if i
    a << 'ContentPageArchive' if i
    i = ContentPage.first
    i.id if i
    i.page_name if i
    i.sort_order if i
    i.active if i
    i.open_in_new_window if i
    i.last_update_user_id if i
    i.parent_content_page_id if i
    a << 'ContentPage' if i
    i = ContentPartnerAgreement.first
    i.id if i
    i.content_partner_id if i
    i.template if i
    i.is_current if i
    i.number_of_views if i
    i.created_at if i
    i.updated_at if i
    i.last_viewed if i
    i.mou_url if i
    i.ip_address if i
    i.signed_on_date if i
    i.signed_by if i
    i.body if i
    a << 'ContentPartnerAgreement' if i
    i = ContentPartnerContact.first
    i.id if i
    i.content_partner_id if i
    i.contact_role_id if i
    i.full_name if i
    i.title if i
    i.given_name if i
    i.family_name if i
    i.homepage if i
    i.email if i
    i.telephone if i
    i.address if i
    i.email_reports_frequency_hours if i
    i.last_report_email if i
    i.created_at if i
    i.updated_at if i
    a << 'ContentPartnerContact' if i
    i = ContentPartnerStatus.first
    i.id if i
    a << 'ContentPartnerStatus' if i
    i = ContentPartner.first
    i.id if i
    i.content_partner_status_id if i
    i.user_id if i
    i.full_name if i
    i.display_name if i
    i.acronym if i
    i.homepage if i
    i.description_of_data if i
    i.description if i
    i.notes if i
    i.created_at if i
    i.updated_at if i
    i.public if i
    i.admin_notes if i
    i.logo_cache_url if i
    i.logo_file_name if i
    i.logo_content_type if i
    i.logo_file_size if i
    a << 'ContentPartner' if i
    i = ContentTableItem.first
    i.content_table_id if i
    i.toc_id if i
    i.created_at if i
    i.updated_at if i
    a << 'ContentTableItem' if i
    i = ContentTable.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    a << 'ContentTable' if i
    i = ContentUpload.first
    i.id if i
    i.description if i
    i.link_name if i
    i.attachment_cache_url if i
    i.attachment_extension if i
    i.attachment_content_type if i
    i.attachment_file_name if i
    i.attachment_file_size if i
    i.user_id if i
    i.created_at if i
    i.updated_at if i
    a << 'ContentUpload' if i
    i = CuratedDataObjectsHierarchyEntry.first
    i.id if i
    i.data_object_id if i
    i.data_object_guid if i
    i.hierarchy_entry_id if i
    i.user_id if i
    i.created_at if i
    i.updated_at if i
    i.vetted_id if i
    i.visibility_id if i
    a << 'CuratedDataObjectsHierarchyEntry' if i
    i = CuratedTaxonConceptPreferredEntry.first
    i.id if i
    i.taxon_concept_id if i
    i.hierarchy_entry_id if i
    i.user_id if i
    i.created_at if i
    a << 'CuratedTaxonConceptPreferredEntry' if i
    i = CuratorActivityLogsUntrustReason.first
    i.curator_activity_log_id if i
    i.untrust_reason_id if i
    a << 'CuratorActivityLogsUntrustReason' if i
    i = CuratorLevel.first
    i.id if i
    i.label if i
    i.rating_weight if i
    a << 'CuratorLevel' if i
    i = DataObjectTranslation.first
    i.id if i
    i.data_object_id if i
    i.original_data_object_id if i
    i.language_id if i
    i.created_at if i
    i.updated_at if i
    a << 'DataObjectTranslation' if i
    i = DataObject.first
    i.id if i
    i.guid if i
    i.identifier if i
    i.provider_mangaed_id if i
    i.data_type_id if i
    i.data_subtype_id if i
    i.mime_type_id if i
    i.object_title if i
    i.language_id if i
    i.metadata_language_id if i
    i.license_id if i
    i.rights_statement if i
    i.rights_holder if i
    i.bibliographic_citation if i
    i.source_url if i
    i.description if i
    i.description_linked if i
    i.object_url if i
    i.object_cache_url if i
    i.thumbnail_url if i
    i.thumbnail_cache_url if i
    i.location if i
    i.latitude if i
    i.longitude if i
    i.altitude if i
    i.object_created_at if i
    i.object_modified_at if i
    i.created_at if i
    i.updated_at if i
    i.available_at if i
    i.data_rating if i
    i.published if i
    i.curated if i
    i.derived_from if i
    i.spatial_location if i
    a << 'DataObject' if i
    i = DataObjectsHarvestEvent.first
    i.harvest_event_id if i
    i.data_object_id if i
    i.guid if i
    i.status_id if i
    a << 'DataObjectsHarvestEvent' if i
    i = DataObjectsHierarchyEntry.first
    i.hierarchy_entry_id if i
    i.data_object_id if i
    i.vetted_id if i
    i.visibility_id if i
    a << 'DataObjectsHierarchyEntry' if i
    i = DataObjectsInfoItem.first
    i.data_object_id if i
    i.info_item_id if i
    a << 'DataObjectsInfoItem' if i
    i = DataObjectsRef.first
    i.data_object_id if i
    i.ref_id if i
    a << 'DataObjectsRef' if i
    i = DataObjectsTableOfContent.first
    i.data_object_id if i
    i.toc_id if i
    a << 'DataObjectsTableOfContent' if i
    i = DataObjectsTaxonConcept.first
    i.taxon_concept_id if i
    i.data_object_id if i
    a << 'DataObjectsTaxonConcept' if i
    i = DataType.first
    i.id if i
    i.schema_value if i
    a << 'DataType' if i
    i = EolStatistic.first
    i.id if i
    i.members_count if i
    i.communities_count if i
    i.collections_count if i
    i.pages_count if i
    i.pages_with_content if i
    i.pages_with_text if i
    i.pages_with_image if i
    i.pages_with_map if i
    i.pages_with_video if i
    i.pages_with_sound if i
    i.pages_without_text if i
    i.pages_without_image if i
    i.pages_with_image_no_text if i
    i.pages_with_text_no_image if i
    i.base_pages if i
    i.pages_with_at_least_a_trusted_object if i
    i.pages_with_at_least_a_curatorial_action if i
    i.pages_with_BHL_links if i
    i.pages_with_BHL_links_no_text if i
    i.pages_with_BHL_links_only if i
    i.content_partners if i
    i.content_partners_with_published_resources if i
    i.content_partners_with_published_trusted_resources if i
    i.published_resources if i
    i.published_trusted_resources if i
    i.published_unreviewed_resources if i
    i.newly_published_resources_in_the_last_30_days if i
    i.data_objects if i
    i.data_objects_texts if i
    i.data_objects_images if i
    i.data_objects_videos if i
    i.data_objects_sounds if i
    i.data_objects_maps if i
    i.data_objects_trusted if i
    i.data_objects_unreviewed if i
    i.data_objects_untrusted if i
    i.data_objects_trusted_or_unreviewed_but_hidden if i
    i.udo_published if i
    i.udo_published_by_curators if i
    i.udo_published_by_non_curators if i
    i.rich_pages if i
    i.hotlist_pages if i
    i.rich_hotlist_pages if i
    i.redhotlist_pages if i
    i.rich_redhotlist_pages if i
    i.pages_with_score_10_to_39 if i
    i.pages_with_score_less_than_10 if i
    i.curators if i
    i.curators_assistant if i
    i.curators_full if i
    i.curators_master if i
    i.active_curators if i
    i.pages_curated_by_active_curators if i
    i.objects_curated_in_the_last_30_days if i
    i.curator_actions_in_the_last_30_days if i
    i.lifedesk_taxa if i
    i.lifedesk_data_objects if i
    i.marine_pages if i
    i.marine_pages_in_col if i
    i.marine_pages_with_objects if i
    i.marine_pages_with_objects_vetted if i
    i.created_at if i
    a << 'EolStatistic' if i
    i = ErrorLog.first
    i.id if i
    i.exception_name if i
    i.backtrace if i
    i.url if i
    i.user_id if i
    i.user_agent if i
    i.ip_address if i
    i.created_at if i
    i.updated_at if i
    a << 'ErrorLog' if i
    i = FeedDataObject.first
    i.taxon_concept_id if i
    i.data_object_id if i
    i.data_type_id if i
    i.created_at if i
    a << 'FeedDataObject' if i
    i = GbifIdentifiersWithMap.first
    i.gbif_taxon_id if i
    a << 'GbifIdentifiersWithMap' if i
    i = GlossaryTerm.first
    i.id if i
    i.term if i
    i.definition if i
    i.created_at if i
    i.updated_at if i
    a << 'GlossaryTerm' if i
    i = GoogleAnalyticsPageStat.first
    i.taxon_concept_id if i
    i.year if i
    i.month if i
    i.page_views if i
    i.unique_page_views if i
    i.time_on_page if i
    a << 'GoogleAnalyticsPageStat' if i
    i = GoogleAnalyticsPartnerSummary.first
    i.year if i
    i.month if i
    i.user_id if i
    i.taxa_pages if i
    i.taxa_pages_viewed if i
    i.unique_page_views if i
    i.page_views if i
    i.time_on_page if i
    a << 'GoogleAnalyticsPartnerSummary' if i
    i = GoogleAnalyticsPartnerTaxon.first
    i.taxon_concept_id if i
    i.user_id if i
    i.year if i
    i.month if i
    a << 'GoogleAnalyticsPartnerTaxon' if i
    i = GoogleAnalyticsSummary.first
    i.year if i
    i.month if i
    i.visits if i
    i.visitors if i
    i.pageviews if i
    i.unique_pageviews if i
    i.ave_pages_per_visit if i
    i.ave_time_on_site if i
    i.ave_time_on_page if i
    i.per_new_visits if i
    i.bounce_rate if i
    i.per_exit if i
    i.taxa_pages if i
    i.taxa_pages_viewed if i
    i.time_on_pages if i
    a << 'GoogleAnalyticsSummary' if i
    i = HarvestEvent.first
    i.id if i
    i.resource_id if i
    i.began_at if i
    i.completed_at if i
    i.published_at if i
    i.publish if i
    a << 'HarvestEvent' if i
    i = HarvestEventsHierarchyEntry.first
    i.harvest_event_id if i
    i.hierarchy_entry_id if i
    i.guid if i
    i.status_id if i
    a << 'HarvestEventsHierarchyEntry' if i
    i = HarvestProcessLog.first
    i.id if i
    i.process_name if i
    i.began_at if i
    i.completed_at if i
    a << 'HarvestProcessLog' if i
    i = Hierarchy.first
    i.id if i
    i.agent_id if i
    i.label if i
    i.descriptive_label if i
    i.description if i
    i.indexed_on if i
    i.hierarchy_group_id if i
    i.hierarchy_group_version if i
    i.url if i
    i.outlink_uri if i
    i.ping_host_url if i
    i.browsable if i
    i.complete if i
    i.request_publish if i
    a << 'Hierarchy' if i
    i = HierarchyEntry.first
    i.id if i
    i.guid if i
    i.identifier if i
    i.source_url if i
    i.name_id if i
    i.parent_id if i
    i.hierarchy_id if i
    i.rank_id if i
    i.ancestry if i
    i.lft if i
    i.rgt if i
    i.depth if i
    i.taxon_concept_id if i
    i.vetted_id if i
    i.published if i
    i.visibility_id if i
    i.created_at if i
    i.updated_at if i
    i.taxon_remarks if i
    a << 'HierarchyEntry' if i
    i = HierarchyEntriesFlattened.first
    i.hierarchy_entry_id if i
    i.ancestor_id if i
    a << 'HierarchyEntriesFlattened' if i
    i = HierarchyEntriesRef.first
    i.hierarchy_entry_id if i
    i.ref_id if i
    a << 'HierarchyEntriesRef' if i
    i = HierarchyEntryMove.first
    i.id if i
    i.hierarchy_entry_id if i
    i.classification_curation_id if i
    i.error if i
    i.completed_at if i
    a << 'HierarchyEntryMove' if i
    i = HierarchyEntryStat.first
    i.hierarchy_entry_id if i
    i.text_trusted if i
    i.text_untrusted if i
    i.image_trusted if i
    i.image_untrusted if i
    i.bhl if i
    i.all_text_trusted if i
    i.all_text_untrusted if i
    i.have_text if i
    i.all_image_trusted if i
    i.all_image_untrusted if i
    i.have_images if i
    i.all_bhl if i
    i.total_children if i
    a << 'HierarchyEntryStat' if i
    i = InfoItem.first
    i.id if i
    i.schema_value if i
    i.toc_id if i
    a << 'InfoItem' if i
    i = ItemPage.first
    i.id if i
    i.title_item_id if i
    i.year if i
    i.volume if i
    i.issue if i
    i.prefix if i
    i.number if i
    i.url if i
    i.page_type if i
    a << 'ItemPage' if i
    i = Language.first
    i.id if i
    i.iso_639_1 if i
    i.iso_639_2 if i
    i.iso_639_3 if i
    i.source_form if i
    i.sort_order if i
    i.activated_on if i
    a << 'Language' if i
    i = License.first
    i.id if i
    i.title if i
    i.source_url if i
    i.version if i
    i.logo_url if i
    i.show_to_content_partners if i
    a << 'License' if i
    i = LinkType.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    a << 'LinkType' if i
    i = Member.first
    i.id if i
    i.user_id if i
    i.community_id if i
    i.created_at if i
    i.updated_at if i
    i.manager if i
    a << 'Member' if i
    i = MimeType.first
    i.id if i
    a << 'MimeType' if i
    i = Name.first
    i.id if i
    i.namebank_id if i
    i.string if i
    i.clean_name if i
    i.italicized if i
    i.italicized_verified if i
    i.canonical_form_id if i
    i.ranked_canonical_form_id if i
    i.canonical_verified if i
    a << 'Name' if i
    i = NewsItem.first
    i.id if i
    i.page_name if i
    i.display_date if i
    i.activated_on if i
    i.last_update_user_id if i
    i.active if i
    i.created_at if i
    i.updated_at if i
    a << 'NewsItem' if i
    i = NotificationFrequency.first
    i.id if i
    i.frequency if i
    a << 'NotificationFrequency' if i
    i = Notification.first
    i.id if i
    i.user_id if i
    i.reply_to_comment if i
    i.comment_on_my_profile if i
    i.comment_on_my_contribution if i
    i.comment_on_my_collection if i
    i.comment_on_my_community if i
    i.made_me_a_manager if i
    i.member_joined_my_community if i
    i.comment_on_my_watched_item if i
    i.curation_on_my_watched_item if i
    i.new_data_on_my_watched_item if i
    i.changes_to_my_watched_collection if i
    i.changes_to_my_watched_community if i
    i.member_joined_my_watched_community if i
    i.member_left_my_community if i
    i.new_manager_in_my_community if i
    i.i_am_being_watched if i
    i.eol_newsletter if i
    i.last_notification_sent_at if i
    i.created_at if i
    i.updated_at if i
    a << 'Notification' if i
    i = OpenAuthentication.first
    i.id if i
    i.user_id if i
    i.provider if i
    i.guid if i
    i.token if i
    i.secret if i
    i.verified_at if i
    i.created_at if i
    i.updated_at if i
    a << 'OpenAuthentication' if i
    i = PageName.first
    i.item_page_id if i
    i.name_id if i
    a << 'PageName' if i
    i = PageStatsTaxon.first
    i.id if i
    i.taxa_count if i
    i.taxa_text if i
    i.taxa_images if i
    i.taxa_text_images if i
    i.taxa_BHL_no_text if i
    i.taxa_links_no_text if i
    i.taxa_images_no_text if i
    i.taxa_text_no_images if i
    i.vet_obj_only_1cat_inCOL if i
    i.vet_obj_only_1cat_notinCOL if i
    i.vet_obj_morethan_1cat_inCOL if i
    i.vet_obj_morethan_1cat_notinCOL if i
    i.vet_obj if i
    i.no_vet_obj2 if i
    i.with_BHL if i
    i.vetted_not_published if i
    i.vetted_unknown_published_visible_inCol if i
    i.vetted_unknown_published_visible_notinCol if i
    i.pages_incol if i
    i.pages_not_incol if i
    i.date_created if i
    i.lifedesk_taxa if i
    i.lifedesk_dataobject if i
    i.data_objects_count_per_category if i
    i.content_partners_count_per_category if i
    a << 'PageStatsTaxon' if i
    i = PendingNotification.first
    i.id if i
    i.user_id if i
    i.notification_frequency_id if i
    i.target_id if i
    i.target_type if i
    i.reason if i
    i.sent_at if i
    i.created_at if i
    i.updated_at if i
    a << 'PendingNotification' if i
    i = PublicationTitle.first
    i.id if i
    i.marc_bib_id if i
    i.marc_leader if i
    i.title if i
    i.short_title if i
    i.details if i
    i.call_number if i
    i.start_year if i
    i.end_year if i
    i.language if i
    i.author if i
    i.abbreviation if i
    i.url if i
    a << 'PublicationTitle' if i
    i = RandomHierarchyImage.first
    i.id if i
    i.data_object_id if i
    i.hierarchy_entry_id if i
    i.hierarchy_id if i
    i.taxon_concept_id if i
    i.name if i
    a << 'RandomHierarchyImage' if i
    i = Rank.first
    i.id if i
    i.rank_group_id if i
    a << 'Rank' if i
    i = RefIdentifierType.first
    i.id if i
    i.label if i
    a << 'RefIdentifierType' if i
    i = RefIdentifier.first
    i.ref_id if i
    i.ref_identifier_type_id if i
    i.identifier if i
    a << 'RefIdentifier' if i
    i = Ref.first
    i.id if i
    i.full_reference if i
    i.provider_mangaed_id if i
    i.authors if i
    i.editors if i
    i.publication_created_at if i
    i.title if i
    i.pages if i
    i.page_start if i
    i.page_end if i
    i.volume if i
    i.edition if i
    i.publisher if i
    i.language_id if i
    i.user_submitted if i
    i.visibility_id if i
    i.published if i
    a << 'Ref' if i
    i = ResourceStatus.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    a << 'ResourceStatus' if i
    i = Resource.first
    i.id if i
    i.content_partner_id if i
    i.title if i
    i.accesspoint_url if i
    i.metadata_url if i
    i.dwc_archive_url if i
    i.service_type_id if i
    i.service_version if i
    i.resource_set_code if i
    i.description if i
    i.logo_url if i
    i.language_id if i
    i.subject if i
    i.bibliographic_citation if i
    i.license_id if i
    i.rights_statement if i
    i.rights_holder if i
    i.refresh_period_hours if i
    i.resource_modified_at if i
    i.resource_created_at if i
    i.created_at if i
    i.harvested_at if i
    i.dataset_file_name if i
    i.dataset_content_type if i
    i.dataset_file_size if i
    i.resource_status_id if i
    i.auto_publish if i
    i.vetted if i
    i.notes if i
    i.hierarchy_id if i
    i.dwc_hierarchy_id if i
    i.collection_id if i
    i.preview_collection_id if i
    i.updated_at if i
    a << 'Resource' if i
    i = SearchSuggestion.first
    i.id if i
    i.term if i
    i.language_label if i
    i.taxon_id if i
    i.notes if i
    i.content_notes if i
    i.sort_order if i
    i.active if i
    i.created_at if i
    i.updated_at if i
    a << 'SearchSuggestion' if i
    i = ServiceType.first
    i.id if i
    a << 'ServiceType' if i
    i = SiteConfigurationOption.first
    i.id if i
    i.parameter if i
    i.value if i
    i.created_at if i
    i.updated_at if i
    a << 'SiteConfigurationOption' if i
    i = SortStyle.first
    i.id if i
    a << 'SortStyle' if i
    i = SpecialCollection.first
    i.id if i
    i.name if i
    a << 'SpecialCollection' if i
    i = Status.first
    i.id if i
    a << 'Status' if i
    i = SurveyResponse.first
    i.id if i
    i.taxon_id if i
    i.user_response if i
    i.user_id if i
    i.user_agent if i
    i.ip_address if i
    i.created_at if i
    i.updated_at if i
    a << 'SurveyResponse' if i
    i = SynonymRelation.first
    i.id if i
    a << 'SynonymRelation' if i
    i = Synonym.first
    i.id if i
    i.name_id if i
    i.synonym_relation_id if i
    i.language_id if i
    i.hierarchy_entry_id if i
    i.preferred if i
    i.hierarchy_id if i
    i.vetted_id if i
    i.published if i
    i.taxon_remarks if i
    a << 'Synonym' if i
    i = TaxonClassificationsLock.first
    i.id if i
    i.taxon_concept_id if i
    i.created_at if i
    a << 'TaxonClassificationsLock' if i
    i = TaxonConceptExemplarArticle.first
    i.taxon_concept_id if i
    i.data_object_id if i
    a << 'TaxonConceptExemplarArticle' if i
    i = TaxonConceptExemplarImage.first
    i.taxon_concept_id if i
    i.data_object_id if i
    a << 'TaxonConceptExemplarImage' if i
    i = TaxonConceptMetric.first
    i.taxon_concept_id if i
    i.image_total if i
    i.image_trusted if i
    i.image_untrusted if i
    i.image_unreviewed if i
    i.image_total_words if i
    i.image_trusted_words if i
    i.image_untrusted_words if i
    i.image_unreviewed_words if i
    i.text_total if i
    i.text_trusted if i
    i.text_untrusted if i
    i.text_unreviewed if i
    i.text_total_words if i
    i.text_trusted_words if i
    i.text_untrusted_words if i
    i.text_unreviewed_words if i
    i.video_total if i
    i.video_trusted if i
    i.video_untrusted if i
    i.video_unreviewed if i
    i.video_total_words if i
    i.video_trusted_words if i
    i.video_untrusted_words if i
    i.video_unreviewed_words if i
    i.sound_total if i
    i.sound_trusted if i
    i.sound_untrusted if i
    i.sound_unreviewed if i
    i.sound_total_words if i
    i.sound_trusted_words if i
    i.sound_untrusted_words if i
    i.sound_unreviewed_words if i
    i.flash_total if i
    i.flash_trusted if i
    i.flash_untrusted if i
    i.flash_unreviewed if i
    i.flash_total_words if i
    i.flash_trusted_words if i
    i.flash_untrusted_words if i
    i.flash_unreviewed_words if i
    i.youtube_total if i
    i.youtube_trusted if i
    i.youtube_untrusted if i
    i.youtube_unreviewed if i
    i.youtube_total_words if i
    i.youtube_trusted_words if i
    i.youtube_untrusted_words if i
    i.youtube_unreviewed_words if i
    i.iucn_total if i
    i.iucn_trusted if i
    i.iucn_untrusted if i
    i.iucn_unreviewed if i
    i.iucn_total_words if i
    i.iucn_trusted_words if i
    i.iucn_untrusted_words if i
    i.iucn_unreviewed_words if i
    i.data_object_references if i
    i.info_items if i
    i.BHL_publications if i
    i.content_partners if i
    i.outlinks if i
    i.has_GBIF_map if i
    i.has_biomedical_terms if i
    i.user_submitted_text if i
    i.submitted_text_providers if i
    i.common_names if i
    i.common_name_providers if i
    i.synonyms if i
    i.synonym_providers if i
    i.page_views if i
    i.unique_page_views if i
    i.richness_score if i
    i.map_total if i
    i.map_trusted if i
    i.map_untrusted if i
    i.map_unreviewed if i
    a << 'TaxonConceptMetric' if i
    i = TaxonConceptName.first
    i.taxon_concept_id if i
    i.name_id if i
    i.source_hierarchy_entry_id if i
    i.language_id if i
    i.vern if i
    i.preferred if i
    i.synonym_id if i
    i.vetted_id if i
    a << 'TaxonConceptName' if i
    i = TaxonConceptPreferredEntry.first
    i.id if i
    i.taxon_concept_id if i
    i.hierarchy_entry_id if i
    i.updated_at if i
    a << 'TaxonConceptPreferredEntry' if i
    i = TaxonConcept.first
    i.id if i
    i.supercedure_id if i
    i.split_from if i
    i.vetted_id if i
    i.published if i
    a << 'TaxonConcept' if i
    i = TaxonConceptsFlattened.first
    i.taxon_concept_id if i
    i.ancestor_id if i
    a << 'TaxonConceptsFlattened' if i
    i = TitleItem.first
    i.id if i
    i.publication_title_id if i
    i.bar_code if i
    i.marc_item_id if i
    i.call_number if i
    i.volume_info if i
    i.url if i
    a << 'TitleItem' if i
    i = TopConceptImage.first
    i.taxon_concept_id if i
    i.data_object_id if i
    i.view_order if i
    a << 'TopConceptImage' if i
    i = TopImage.first
    i.hierarchy_entry_id if i
    i.data_object_id if i
    i.view_order if i
    a << 'TopImage' if i
    i = TopUnpublishedConceptImage.first
    i.taxon_concept_id if i
    i.data_object_id if i
    i.view_order if i
    a << 'TopUnpublishedConceptImage' if i
    i = TopUnpublishedImage.first
    i.hierarchy_entry_id if i
    i.data_object_id if i
    i.view_order if i
    a << 'TopUnpublishedImage' if i
    i = TranslatedAgentRole.first
    i.id if i
    i.agent_role_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedAgentRole' if i
    i = TranslatedAudience.first
    i.id if i
    i.audience_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedAudience' if i
    i = TranslatedCollectionType.first
    i.id if i
    i.collection_type_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedCollectionType' if i
    i = TranslatedContactRole.first
    i.id if i
    i.contact_role_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedContactRole' if i
    i = TranslatedContactSubject.first
    i.id if i
    i.contact_subject_id if i
    i.language_id if i
    i.title if i
    i.phonetic_action_code if i
    a << 'TranslatedContactSubject' if i
    i = TranslatedContentPageArchive.first
    i.id if i
    i.translated_content_page_id if i
    i.content_page_id if i
    i.language_id if i
    i.title if i
    i.left_content if i
    i.main_content if i
    i.meta_keywords if i
    i.meta_description if i
    i.original_creation_date if i
    i.created_at if i
    i.updated_at if i
    a << 'TranslatedContentPageArchive' if i
    i = TranslatedContentPage.first
    i.id if i
    i.content_page_id if i
    i.language_id if i
    i.title if i
    i.left_content if i
    i.main_content if i
    i.meta_keywords if i
    i.meta_description if i
    i.created_at if i
    i.updated_at if i
    i.active_translation if i
    a << 'TranslatedContentPage' if i
    i = TranslatedContentPartnerStatus.first
    i.id if i
    i.content_partner_status_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedContentPartnerStatus' if i
    i = TranslatedContentTable.first
    i.id if i
    i.content_table_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedContentTable' if i
    i = TranslatedDataType.first
    i.id if i
    i.data_type_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedDataType' if i
    i = TranslatedInfoItem.first
    i.id if i
    i.info_item_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedInfoItem' if i
    i = TranslatedLanguage.first
    i.id if i
    i.original_language_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedLanguage' if i
    i = TranslatedLicense.first
    i.id if i
    i.license_id if i
    i.language_id if i
    i.description if i
    i.phonetic_description if i
    a << 'TranslatedLicense' if i
    i = TranslatedLinkType.first
    i.id if i
    i.link_type_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedLinkType' if i
    i = TranslatedMimeType.first
    i.id if i
    i.mime_type_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedMimeType' if i
    i = TranslatedNewsItem.first
    i.id if i
    i.news_item_id if i
    i.language_id if i
    i.body if i
    i.title if i
    i.active_translation if i
    i.created_at if i
    i.updated_at if i
    a << 'TranslatedNewsItem' if i
    i = TranslatedRank.first
    i.id if i
    i.rank_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedRank' if i
    i = TranslatedResourceStatus.first
    i.id if i
    i.resource_status_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedResourceStatus' if i
    i = TranslatedServiceType.first
    i.id if i
    i.service_type_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedServiceType' if i
    i = TranslatedSortStyle.first
    i.id if i
    i.name if i
    i.language_id if i
    i.sort_style_id if i
    a << 'TranslatedSortStyle' if i
    i = TranslatedStatus.first
    i.id if i
    i.status_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedStatus' if i
    i = TranslatedSynonymRelation.first
    i.id if i
    i.synonym_relation_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedSynonymRelation' if i
    i = TranslatedUntrustReason.first
    i.id if i
    i.untrust_reason_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedUntrustReason' if i
    i = TranslatedUserIdentity.first
    i.id if i
    i.user_identity_id if i
    i.language_id if i
    i.label if i
    a << 'TranslatedUserIdentity' if i
    i = TranslatedVetted.first
    i.id if i
    i.vetted_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedVetted' if i
    i = TranslatedViewStyle.first
    i.id if i
    i.name if i
    i.language_id if i
    i.view_style_id if i
    a << 'TranslatedViewStyle' if i
    i = TranslatedVisibility.first
    i.id if i
    i.visibility_id if i
    i.language_id if i
    i.label if i
    i.phonetic_label if i
    a << 'TranslatedVisibility' if i
    i = UniqueVisitor.first
    i.id if i
    i.count if i
    i.created_at if i
    i.updated_at if i
    a << 'UniqueVisitor' if i
    i = UntrustReason.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    i.class_name if i
    a << 'UntrustReason' if i
    i = UserIdentity.first
    i.id if i
    i.sort_order if i
    a << 'UserIdentity' if i
    i = UserInfo.first
    i.id if i
    i.areas_of_interest if i
    i.heard_of_eol if i
    i.interested_in_contributing if i
    i.interested_in_curating if i
    i.interested_in_advisory_forum if i
    i.show_information if i
    i.age_range if i
    i.created_at if i
    i.updated_at if i
    i.user_id if i
    i.user_primary_role_id if i
    i.interested_in_development if i
    a << 'UserInfo' if i
    i = UserPrimaryRole.first
    i.id if i
    i.name if i
    a << 'UserPrimaryRole' if i
    i = User.first
    i.id if i
    i.remote_ip if i
    i.email if i
    i.given_name if i
    i.family_name if i
    i.identity_url if i
    i.username if i
    i.hashed_password if i
    i.active if i
    i.language_id if i
    i.created_at if i
    i.updated_at if i
    i.notes if i
    i.curator_approved if i
    i.curator_verdict_by_id if i
    i.curator_verdict_at if i
    i.credentials if i
    i.validation_code if i
    i.failed_login_attempts if i
    i.curator_scope if i
    i.remember_token if i
    i.remember_token_expires_at if i
    i.recover_account_token if i
    i.recover_account_token_expires_at if i
    i.agent_id if i
    i.email_reports_frequency_hours if i
    i.last_report_email if i
    i.api_key if i
    i.logo_url if i
    i.logo_cache_url if i
    i.logo_file_name if i
    i.logo_content_type if i
    i.logo_file_size if i
    i.tag_line if i
    i.agreed_with_terms if i
    i.bio if i
    i.curator_level_id if i
    i.requested_curator_level_id if i
    i.requested_curator_at if i
    i.admin if i
    i.hidden if i
    i.last_notification_at if i
    i.last_message_at if i
    i.disable_email_notifications if i
    i.news_in_preferred_language if i
    a << 'User' if i
    i = UsersDataObject.first
    i.id if i
    i.user_id if i
    i.data_object_id if i
    i.taxon_concept_id if i
    i.vetted_id if i
    i.visibility_id if i
    i.created_at if i
    i.updated_at if i
    a << 'UsersDataObject' if i
    i = UsersDataObjectsRating.first
    i.id if i
    i.user_id if i
    i.data_object_id if i
    i.rating if i
    i.data_object_guid if i
    i.created_at if i
    i.updated_at if i
    i.weight if i
    a << 'UsersDataObjectsRating' if i
    i = UsersUserIdentity.first
    i.user_id if i
    i.user_identity_id if i
    a << 'UsersUserIdentity' if i
    i = Vetted.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    i.view_order if i
    a << 'Vetted' if i
    i = ViewStyle.first
    i.id if i
    i.max_items_per_page if i
    a << 'ViewStyle' if i
    i = Visibility.first
    i.id if i
    i.created_at if i
    i.updated_at if i
    a << 'Visibility' if i
    i = WikipediaQueue.first
    i.id if i
    i.revision_id if i
    i.user_id if i
    i.created_at if i
    i.harvested_at if i
    i.harvest_succeeded if i
    a << 'WikipediaQueue' if i
    i = WorklistIgnoredDataObject.first
    i.id if i
    i.user_id if i
    i.data_object_id if i
    i.created_at if i
    a << 'WorklistIgnoredDataObject' if i
    return a
  end
end
