#CREATE DATABASE eol_data DEFAULT CHARACTER SET utf8 COLLATE utf8_general_ci;



DROP TABLE IF EXISTS agents;
CREATE TABLE agents (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , full_name VARCHAR(255) NOT NULL
     , acronym VARCHAR(20) NOT NULL
     , display_name VARCHAR(255) NOT NULL
     , homepage VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , email VARCHAR(75) NOT NULL
     , username VARCHAR(100) NOT NULL
     , hashed_password VARCHAR(100) NOT NULL
     , remember_token VARCHAR(255) NULL
     , remember_token_expires_at TIMESTAMP NULL
     , logo_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci
     , logo_file_name VARCHAR(255)
     , logo_content_type VARCHAR(255)
     , logo_file_size INT UNSIGNED DEFAULT 0
     , agent_status_id TINYINT NOT NULL	 
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , updated_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , PRIMARY KEY (id)
     , INDEX (full_name)
) ENGINE = InnoDB;



DROP TABLE IF EXISTS agent_data_types;
CREATE TABLE agent_data_types (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agent_provided_data_types;
CREATE TABLE agent_provided_data_types (
       agent_data_type_id INT UNSIGNED NOT NULL
     , agent_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (agent_data_type_id, agent_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agent_contact_roles;
CREATE TABLE agent_contact_roles (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agent_contacts;
CREATE TABLE agent_contacts (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , agent_id INT UNSIGNED NOT NULL
     , agent_contact_role_id TINYINT UNSIGNED NOT NULL
     , full_name VARCHAR(255) NOT NULL
     , title VARCHAR(20) NOT NULL
     , given_name VARCHAR(255) NOT NULL
     , family_name VARCHAR(255) NOT NULL
     , homepage VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , email VARCHAR(75) NOT NULL
     , telephone VARCHAR(30) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , address TEXT NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agents_data_objects;
CREATE TABLE agents_data_objects (
       data_object_id INT UNSIGNED NOT NULL
     , agent_id INT UNSIGNED NOT NULL
     , agent_role_id TINYINT UNSIGNED NOT NULL
     , view_order TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (data_object_id, agent_id, agent_role_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agents_hierarchy_entries;
CREATE TABLE agents_hierarchy_entries (
       hierarchy_entry_id INT UNSIGNED NOT NULL
     , agent_id INT UNSIGNED NOT NULL
     , agent_role_id TINYINT UNSIGNED NOT NULL
     , view_order TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (hierarchy_entry_id, agent_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agents_resources;
CREATE TABLE agents_resources (
       agent_id INT UNSIGNED NOT NULL
     , resource_id INT UNSIGNED NOT NULL
     , resource_agent_role_id TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (agent_id, resource_id, resource_agent_role_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agent_roles;
CREATE TABLE agent_roles (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS agent_statuses;
CREATE TABLE agent_statuses (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS audiences;
CREATE TABLE audiences (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS audiences_data_objects;
CREATE TABLE audiences_data_objects (
       data_object_id INT UNSIGNED NOT NULL
     , audience_id TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (data_object_id, audience_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS canonical_forms;
CREATE TABLE canonical_forms (
	   id INT UNSIGNED NOT NULL AUTO_INCREMENT
	 , string VARCHAR (300) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL
	 , PRIMARY KEY (id)
	 , INDEX (string)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS collections;
CREATE TABLE collections (
       id MEDIUMINT UNSIGNED NOT NULL AUTO_INCREMENT
     , agent_id INT UNSIGNED NOT NULL
     , title VARCHAR(150) NOT NULL
     , description VARCHAR(300) NOT NULL
     , uri VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , link VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , logo_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , vetted TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS common_names;
CREATE TABLE common_names (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , common_name VARCHAR(255) NOT NULL
     , language_id SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
     , INDEX (common_name)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS common_names_taxa;
CREATE TABLE common_names_taxa (
       taxon_id INT UNSIGNED NOT NULL
     , common_name_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (taxon_id, common_name_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS content_partners;
CREATE TABLE content_partners (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
	 , agent_id INT NOT NULL
     , description_of_data TEXT NULL
     , partner_seen_step TIMESTAMP NULL
     , partner_complete_step TIMESTAMP NULL
     , contacts_seen_step TIMESTAMP NULL
     , contacts_complete_step TIMESTAMP NULL
     , licensing_seen_step TIMESTAMP NULL
     , licensing_complete_step TIMESTAMP NULL
     , attribution_seen_step TIMESTAMP NULL
     , attribution_complete_step TIMESTAMP NULL
     , roles_seen_step TIMESTAMP NULL
     , roles_complete_step TIMESTAMP NULL
     , transfer_overview_seen_step TIMESTAMP NULL
     , transfer_overview_complete_step TIMESTAMP NULL
     , transfer_upload_seen_step TIMESTAMP NULL
     , transfer_upload_complete_step TIMESTAMP NULL
     , specialist_overview_seen_step TIMESTAMP NULL
     , specialist_overview_complete_step TIMESTAMP NULL
     , specialist_formatting_seen_step TIMESTAMP NULL
     , specialist_formatting_complete_step TIMESTAMP NULL
     , licenses_accept TINYINT NOT NULL DEFAULT '0'
     , description TEXT NOT NULL
     , last_completed_step varchar(40) NULL
     , notes TEXT NOT NULL
     , ipr_accept TINYINT NOT NULL DEFAULT '0'
     , attribution_accept TINYINT NOT NULL DEFAULT '0'
     , roles_accept TINYINT NOT NULL DEFAULT '0'
     , transfer_schema_accept TINYINT NOT NULL DEFAULT '0'
     , active TINYINT NOT NULL DEFAULT '1'
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , updated_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'	 
     , PRIMARY KEY (id)
) ENGINE = InnoDB;



DROP TABLE IF EXISTS data_objects;
CREATE TABLE data_objects (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , guid VARCHAR(20) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , data_type_id SMALLINT UNSIGNED NOT NULL
     , mime_type_id SMALLINT UNSIGNED NOT NULL
     , object_title VARCHAR(255) NOT NULL
     , language_id SMALLINT UNSIGNED NOT NULL
     , license_id TINYINT UNSIGNED NOT NULL
     , rights_statement VARCHAR(300) NOT NULL
     , rights_holder VARCHAR(255) NOT NULL
     , bibliographic_citation VARCHAR(300) NOT NULL
     , source_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , description TEXT NOT NULL
     , object_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , object_cache_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , thumbnail_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , thumbnail_cache_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , location VARCHAR(255) NOT NULL
     , latitude DOUBLE NOT NULL
     , longitude DOUBLE NOT NULL
     , altitude DOUBLE NOT NULL
     , object_created_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , object_modified_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , updated_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , data_rating FLOAT NOT NULL
     , vetted TINYINT UNSIGNED NOT NULL
     , visible TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
     , INDEX (data_type_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS data_objects_info_items;
CREATE TABLE data_objects_info_items (
       data_object_id INT UNSIGNED NOT NULL
     , info_item_id SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (data_object_id, info_item_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS data_objects_refs;
CREATE TABLE data_objects_refs (
       data_object_id INT UNSIGNED NOT NULL
     , ref_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (data_object_id, ref_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS data_objects_table_of_contents;
CREATE TABLE data_objects_table_of_contents (
       data_object_id INT UNSIGNED NOT NULL
     , toc_id SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (data_object_id, toc_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS data_objects_taxa;
CREATE TABLE data_objects_taxa (
       taxon_id INT UNSIGNED NOT NULL
     , data_object_id INT UNSIGNED NOT NULL
     , identifier VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (taxon_id, data_object_id)
     , INDEX (data_object_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS data_types;
CREATE TABLE data_types (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , schema_value VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , label VARCHAR(255) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS hierarchies;
CREATE TABLE hierarchies (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(255) NOT NULL
     , description TEXT NOT NULL
     , indexed_on TIMESTAMP NOT NULL DEFAULT NOW()
     , hierarchy_group_id INT UNSIGNED NOT NULL
     , hierarchy_group_version TINYINT UNSIGNED NOT NULL
     , url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS hierarchies_content;
CREATE TABLE hierarchies_content (
       hierarchy_entry_id INT UNSIGNED NOT NULL
     , text TINYINT UNSIGNED NOT NULL
     , image TINYINT UNSIGNED NOT NULL
     , child_image TINYINT UNSIGNED NOT NULL
     , flash TINYINT UNSIGNED NOT NULL
     , youtube TINYINT UNSIGNED NOT NULL
     , internal_image TINYINT UNSIGNED NOT NULL
     , gbif_image TINYINT UNSIGNED NOT NULL
     , content_level TINYINT UNSIGNED NOT NULL
     , image_object_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (hierarchy_entry_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS hierarchy_entries;
CREATE TABLE hierarchy_entries (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , remote_id VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , parent_id INT UNSIGNED NOT NULL
     , hierarchy_id SMALLINT UNSIGNED NOT NULL
     , rank_id SMALLINT UNSIGNED NOT NULL
     , ancestry VARCHAR(500) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , lft INT UNSIGNED NOT NULL
     , rgt INT UNSIGNED NOT NULL
     , depth TINYINT UNSIGNED NOT NULL
     , taxon_concept_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
     , INDEX (name_id)
     , INDEX (parent_id)
     , INDEX (hierarchy_id)
     , INDEX (lft)
     , INDEX (taxon_concept_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS hierarchy_entry_relationships;
CREATE TABLE hierarchy_entry_relationships (
       hierarchy_entry_id_1 INT UNSIGNED NOT NULL
     , hierarchy_entry_id_2 INT UNSIGNED NOT NULL
     , relationship VARCHAR(30) NOT NULL
     , score DOUBLE NOT NULL
     , extra TEXT NOT NULL
     , PRIMARY KEY (hierarchy_entry_id_1, hierarchy_entry_id_2)
     , INDEX (score)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS hierarchy_entry_names;
CREATE TABLE hierarchy_entry_names (
       hierarchy_entry_id INT UNSIGNED NOT NULL
     , italics VARCHAR(300) NOT NULL
     , italics_canonical VARCHAR(300) NOT NULL
     , normal VARCHAR(300) NOT NULL
     , normal_canonical VARCHAR(300) NOT NULL
     , common_name_en VARCHAR(300) NOT NULL
     , common_name_fr VARCHAR(300) NOT NULL
     , PRIMARY KEY (hierarchy_entry_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS info_items;
CREATE TABLE info_items (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , schema_value VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , label VARCHAR(255) NOT NULL
     , toc_id SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS item_pages;
CREATE TABLE item_pages (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , title_item_id INT UNSIGNED NOT NULL
     , year VARCHAR(20) NOT NULL
     , volume VARCHAR(20) NOT NULL
     , issue VARCHAR(20) NOT NULL
     , prefix VARCHAR(20) NOT NULL
     , number VARCHAR(20) NOT NULL
     , url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , page_type VARCHAR(20) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS languages;
CREATE TABLE languages (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) NOT NULL
     , name VARCHAR(100) NOT NULL
     , iso_639_1 VARCHAR(6) NOT NULL
     , iso_639_2 VARCHAR(6) NOT NULL
     , iso_639_3 VARCHAR(6) NOT NULL
     , source_form VARCHAR(100) NOT NULL
	 , sort_order TINYINT NOT NULL DEFAULT '1'	
	 , activated_on TIMESTAMP NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS licenses;
CREATE TABLE licenses (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , title VARCHAR(255) NOT NULL
     , description VARCHAR(400) NOT NULL
     , source_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , version VARCHAR(6) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , logo_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (title)
     , INDEX (source_url)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS mappings;
CREATE TABLE mappings (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , collection_id MEDIUMINT UNSIGNED NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , foreign_key VARCHAR(600) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (name_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS mime_types;
CREATE TABLE mime_types (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(255) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS name_languages;
CREATE TABLE name_languages (
	   name_id INT UNSIGNED NOT NULL
	 , language_id SMALLINT UNSIGNED NOT NULL
	 , parent_name_id INT UNSIGNED NOT NULL
	 , preferred TINYINT UNSIGNED NOT NULL
	 , PRIMARY KEY (name_id, language_id, parent_name_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS names;
CREATE TABLE names (
	   id INT UNSIGNED NOT NULL AUTO_INCREMENT
	 , namebank_id INT UNSIGNED NOT NULL
	 , string VARCHAR ( 300 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL
	 , italicized VARCHAR ( 300 ) CHARACTER SET utf8 COLLATE utf8_general_ci NOT NULL
	 , italicized_verified TINYINT UNSIGNED NOT NULL
	 , canonical_form_id INT UNSIGNED NOT NULL
	 , canonical_verified TINYINT UNSIGNED NOT NULL
	 , PRIMARY KEY (id)
	 , INDEX (canonical_form_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS normalized_names;
CREATE TABLE normalized_names (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , name_part VARCHAR(100) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (name_part)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS normalized_links;
CREATE TABLE normalized_links (
       normalized_name_id INT UNSIGNED NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , seq TINYINT UNSIGNED NOT NULL
     , normalized_qualifier_id TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (normalized_name_id, name_id)
     , INDEX (name_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS normalized_qualifiers;
CREATE TABLE normalized_qualifiers (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(50) NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS page_names;
CREATE TABLE page_names (
       item_page_id INT UNSIGNED NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (name_id, item_page_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS publication_titles;
CREATE TABLE publication_titles (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , marc_bib_id VARCHAR(40) NOT NULL
     , marc_leader VARCHAR(40) NOT NULL
     , title VARCHAR(300) NOT NULL
     , short_title VARCHAR(300) NOT NULL
     , details VARCHAR(300) NOT NULL
     , call_number VARCHAR(40) NOT NULL
     , start_year VARCHAR(10) NOT NULL
     , end_year VARCHAR(10) NOT NULL
     , language VARCHAR(10) NOT NULL
     , author VARCHAR(150) NOT NULL
     , abbreviation VARCHAR(150) NOT NULL
     , url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS ranks;
CREATE TABLE ranks (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(50) NOT NULL
     , rank_group_id SMALLINT NOT NULL
     , PRIMARY KEY  (id)
     , INDEX (label)
) ENGINE = InnoDB ; 



DROP TABLE IF EXISTS ref_identifiers;
CREATE TABLE ref_identifiers (
       ref_id INT UNSIGNED NOT NULL
     , ref_identifier_type_id SMALLINT UNSIGNED NOT NULL
     , identifier VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (ref_id, ref_identifier_type_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS ref_identifier_types;
CREATE TABLE ref_identifier_types (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(50) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS refs;
CREATE TABLE refs (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , full_reference VARCHAR(400) NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS refs_taxa;
CREATE TABLE refs_taxa (
       taxon_id INT UNSIGNED NOT NULL
     , ref_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (taxon_id, ref_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS resource_agent_roles;
CREATE TABLE resource_agent_roles (
       id TINYINT UNSIGNED NOT NULL AUTO_INCREMENT
     , label VARCHAR(100) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS resources;
CREATE TABLE resources (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , agent_id INT UNSIGNED NOT NULL
     , title VARCHAR(255) NOT NULL
     , accesspoint_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , metadata_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , service_type_id INT NOT NULL 
     , service_version VARCHAR(255) NOT NULL  
     , resource_set_code VARCHAR(255) NOT NULL
     , description VARCHAR(400) NOT NULL 
     , logo_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci
     , language_id SMALLINT UNSIGNED NOT NULL  
     , subject VARCHAR(255) NOT NULL 
     , bibliographic_citation VARCHAR(400) NOT NULL
     , license_id TINYINT UNSIGNED NOT NULL 
     , rights_statement VARCHAR(400) NOT NULL 
     , rights_holder VARCHAR(255) NOT NULL 
     , refresh_period_hours SMALLINT UNSIGNED NOT NULL 
     , resource_modified_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , resource_created_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00' 
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , harvested_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS service_types;
CREATE TABLE service_types (
       id SMALLINT NOT NULL AUTO_INCREMENT
     , label VARCHAR(255) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS synonyms;
CREATE TABLE synonyms (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , name_id INT UNSIGNED NOT NULL
     , synonym_relation_id TINYINT UNSIGNED NOT NULL
     , language_id SMALLINT UNSIGNED NOT NULL
     , hierarchy_entry_id INT UNSIGNED NOT NULL
     , preferred TINYINT UNSIGNED NOT NULL
     , hierarchy_id SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
     , INDEX (hierarchy_entry_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS synonym_relations;
CREATE TABLE synonym_relations (
       id SMALLINT NOT NULL AUTO_INCREMENT
     , label VARCHAR(255) NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS table_of_contents;
CREATE TABLE table_of_contents (
       id SMALLINT UNSIGNED NOT NULL AUTO_INCREMENT
     , parent_id SMALLINT UNSIGNED NOT NULL
     , label VARCHAR(255) NOT NULL
     , view_order TINYINT NOT NULL
     , PRIMARY KEY (id)
     , INDEX (label)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS taxa;
CREATE TABLE taxa (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , resource_id INT UNSIGNED NOT NULL
     , identifier VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , guid VARCHAR(20) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , source_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , taxon_kingdom VARCHAR(255) NOT NULL
     , taxon_phylum VARCHAR(255) NOT NULL
     , taxon_class VARCHAR(255) NOT NULL
     , taxon_order VARCHAR(255) NOT NULL
     , taxon_family VARCHAR(255) NOT NULL
     , scientific_name VARCHAR(255) NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , taxon_created_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , taxon_modified_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , updated_at TIMESTAMP NOT NULL DEFAULT '0000-00-00 00:00:00'
     , PRIMARY KEY (id)
     , INDEX (name_id)
     , INDEX (resource_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS taxon_concept_names;
CREATE TABLE taxon_concept_names (
       taxon_concept_id INT UNSIGNED NOT NULL
     , name_id INT UNSIGNED NOT NULL
     , source_hierarchy_entry_id INT UNSIGNED NOT NULL
     , language_id INT UNSIGNED NOT NULL
     , vern TINYINT UNSIGNED NOT NULL
     , preferred TINYINT UNSIGNED NOT NULL
     , PRIMARY KEY (taxon_concept_id, name_id, source_hierarchy_entry_id,language_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS taxon_concept_content;
CREATE TABLE taxon_concept_content (
       taxon_concept_id INT UNSIGNED NOT NULL
     , text TINYINT UNSIGNED NOT NULL
     , image TINYINT UNSIGNED NOT NULL
     , child_image TINYINT UNSIGNED NOT NULL
     , flash TINYINT UNSIGNED NOT NULL
     , youtube TINYINT UNSIGNED NOT NULL
     , internal_image TINYINT UNSIGNED NOT NULL
     , gbif_image TINYINT UNSIGNED NOT NULL
     , content_level TINYINT UNSIGNED NOT NULL
     , image_object_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (taxon_concept_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS taxon_concepts;
CREATE TABLE taxon_concepts (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , supercedure_id INT UNSIGNED NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS title_items;
CREATE TABLE title_items (
       id INT UNSIGNED NOT NULL AUTO_INCREMENT
     , publication_title_id INT UNSIGNED NOT NULL
     , bar_code VARCHAR(50) NOT NULL
     , marc_item_id VARCHAR(50) NOT NULL
     , call_number VARCHAR(100) NOT NULL
     , volume_info VARCHAR(100) NOT NULL
     , url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , PRIMARY KEY (id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS top_taxa;
CREATE TABLE top_taxa (
       hierarchy_entry_id INT UNSIGNED NOT NULL
     , frequency INT UNSIGNED NOT NULL
     , PRIMARY KEY (hierarchy_entry_id)
) ENGINE = InnoDB ;



DROP TABLE IF EXISTS top_images;
CREATE TABLE top_images (
       hierarchy_entry_id INT UNSIGNED NOT NULL
     , data_object_id INT UNSIGNED NOT NULL
     , view_order SMALLINT UNSIGNED NOT NULL
     , PRIMARY KEY (hierarchy_entry_id, data_object_id)
) ENGINE = InnoDB ;



#I wonder if we need this - or at least need to change this table a bit
DROP TABLE IF EXISTS random_taxa;
CREATE TABLE random_taxa (
       id int(11) NOT NULL AUTO_INCREMENT
     , language_id INT NOT NULL
     , data_object_id INT NOT NULL
     , hierarchy_entry_id INT NOT NULL
     , name_id INT NOT NULL
     , image_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , thumb_url VARCHAR(255) CHARACTER SET ASCII COLLATE ascii_general_ci NOT NULL
     , name VARCHAR(255) NOT NULL
     , common_name_en VARCHAR(255) NOT NULL
     , common_name_fr VARCHAR(255) NOT NULL
     , content_level INT NOT NULL
     , created_at TIMESTAMP NOT NULL DEFAULT NOW()
     , PRIMARY KEY  (id)
) ENGINE=InnoDB ;








INSERT INTO agent_roles VALUES (NULL,'Animator');
INSERT INTO agent_roles VALUES (NULL,'Author');
INSERT INTO agent_roles VALUES (NULL,'Compiler');
INSERT INTO agent_roles VALUES (NULL,'Composer');
INSERT INTO agent_roles VALUES (NULL,'Creator');
INSERT INTO agent_roles VALUES (NULL,'Director');
INSERT INTO agent_roles VALUES (NULL,'Editor');
INSERT INTO agent_roles VALUES (NULL,'Illustrator');
INSERT INTO agent_roles VALUES (NULL,'Photographer');
INSERT INTO agent_roles VALUES (NULL,'Project');
INSERT INTO agent_roles VALUES (NULL,'Publisher');
INSERT INTO agent_roles VALUES (NULL,'Recorder');
INSERT INTO agent_roles VALUES (NULL,'Source');

INSERT INTO agent_data_types VALUES(NULL,'Audio');
INSERT INTO agent_data_types VALUES(NULL,'Image');
INSERT INTO agent_data_types VALUES(NULL,'Text');
INSERT INTO agent_data_types VALUES(NULL,'Video');

INSERT INTO resource_agent_roles VALUES (NULL,'Data Administrator');
INSERT INTO resource_agent_roles VALUES (NULL,'System Administrator');
INSERT INTO resource_agent_roles VALUES (NULL,'Data Supplier');
INSERT INTO resource_agent_roles VALUES (NULL,'Data Host');
INSERT INTO resource_agent_roles VALUES (NULL,'Technical Host');
INSERT INTO resource_agent_roles VALUES (NULL,'Administrative');

INSERT INTO audiences VALUES (NULL,'Expert users');
INSERT INTO audiences VALUES (NULL,'General public');
INSERT INTO audiences VALUES (NULL,'Children');

INSERT INTO normalized_qualifiers VALUES (NULL,'Name');
INSERT INTO normalized_qualifiers VALUES (NULL,'Author');
INSERT INTO normalized_qualifiers VALUES (NULL,'Year');

INSERT INTO data_types VALUES (NULL,'http://purl.org/dc/dcmitype/StillImage','Image');
INSERT INTO data_types VALUES (NULL,'http://purl.org/dc/dcmitype/Sound','Sound');
INSERT INTO data_types VALUES (NULL,'http://purl.org/dc/dcmitype/Text','Text');
INSERT INTO data_types VALUES (NULL,'http://purl.org/dc/dcmitype/MovingImage','Video');

INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Associations','Associations',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Behaviour','Behaviour',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#ConservationStatus','ConservationStatus',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cyclicity','Cyclicity',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Cytology','Cytology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#DiagnosticDescription','DiagnosticDescription',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Diseases','Diseases',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Dispersal','Dispersal',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Distribution','Distribution',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Evolution','Evolution',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#GeneralDescription','GeneralDescription',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Genetics','Genetics',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Growth','Growth',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Habitat','Habitat',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Legislation','Legislation',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeCycle','LifeCycle',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LifeExpectancy','LifeExpectancy',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#LookAlikes','LookAlikes',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Management','Management',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Migration','Migration',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#MolecularBiology','MolecularBiology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Morphology','Morphology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Physiology','Physiology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#PopulationBiology','PopulationBiology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Procedures','Procedures',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Reproduction','Reproduction',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#RiskStatement','RiskStatement',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Size','Size',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TaxonBiology','TaxonBiology',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Threats','Threats',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Trends','Trends',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#TrophicStrategy','TrophicStrategy',0);
INSERT INTO info_items VALUES (NULL,'http://rs.tdwg.org/ontology/voc/SPMInfoItems#Uses','Uses',0);

INSERT INTO mime_types VALUES (NULL,'audio/mpeg');
INSERT INTO mime_types VALUES (NULL,'audio/x-ms-wma');
INSERT INTO mime_types VALUES (NULL,'audio/x-pn-realaudio');
INSERT INTO mime_types VALUES (NULL,'audio/x-realaudio');
INSERT INTO mime_types VALUES (NULL,'audio/x-wav');
INSERT INTO mime_types VALUES (NULL,'image/bmp');
INSERT INTO mime_types VALUES (NULL,'image/gif');
INSERT INTO mime_types VALUES (NULL,'image/jpeg');
INSERT INTO mime_types VALUES (NULL,'image/png');
INSERT INTO mime_types VALUES (NULL,'image/svg+xml');
INSERT INTO mime_types VALUES (NULL,'image/tiff');
INSERT INTO mime_types VALUES (NULL,'text/html');
INSERT INTO mime_types VALUES (NULL,'text/plain');
INSERT INTO mime_types VALUES (NULL,'text/richtext');
INSERT INTO mime_types VALUES (NULL,'text/rtf');
INSERT INTO mime_types VALUES (NULL,'text/xml');
INSERT INTO mime_types VALUES (NULL,'video/mp4');
INSERT INTO mime_types VALUES (NULL,'video/mpeg');
INSERT INTO mime_types VALUES (NULL,'video/quicktime');
INSERT INTO mime_types VALUES (NULL,'video/x-flv');
INSERT INTO mime_types VALUES (NULL,'video/x-ms-wmv');

INSERT INTO ref_identifier_types VALUES (NULL,'bici');
INSERT INTO ref_identifier_types VALUES (NULL,'coden');
INSERT INTO ref_identifier_types VALUES (NULL,'doi');
INSERT INTO ref_identifier_types VALUES (NULL,'eissn');
INSERT INTO ref_identifier_types VALUES (NULL,'handle');
INSERT INTO ref_identifier_types VALUES (NULL,'issn');
INSERT INTO ref_identifier_types VALUES (NULL,'isbn');
INSERT INTO ref_identifier_types VALUES (NULL,'lsid');
INSERT INTO ref_identifier_types VALUES (NULL,'oclc');
INSERT INTO ref_identifier_types VALUES (NULL,'sici');
INSERT INTO ref_identifier_types VALUES (NULL,'url');
INSERT INTO ref_identifier_types VALUES (NULL,'urn');

INSERT INTO licenses VALUES (1,'public domain','No rights reserved','',0,'');
INSERT INTO licenses VALUES (2,'all rights reserved','&#169; All rights reserved','',0,'');
INSERT INTO licenses VALUES (3,'cc-by-nc 3.0','Some rights reserved','http://creativecommons.org/licenses/by-nc/3.0/',0,'/images/licenses/cc_by_nc_small.png');
INSERT INTO licenses VALUES (4,'cc-by 3.0','Some rights reserved','http://creativecommons.org/licenses/by/3.0/',0,'/images/licenses/cc_by_small.png');
INSERT INTO licenses VALUES (5,'cc-by-sa 3.0','Some rights reserved','http://creativecommons.org/licenses/by-sa/3.0/',0,'/images/licenses/cc_by_sa_small.png');
INSERT INTO licenses VALUES (6,'cc-by-nc-sa 3.0','Some rights reserved','http://creativecommons.org/licenses/by-nc-sa/3.0/',0,'/images/licenses/cc_by_nc_sa_small.png');
INSERT INTO licenses VALUES (7,'gnu-fdl','Some rights reserved','http://www.gnu.org/licenses/fdl.html',0,'/images/licenses/gnu_fdl_small.png');
INSERT INTO licenses VALUES (8,'gnu-gpl','Some rights reserved','http://www.gnu.org/licenses/gpl.html',0,'/images/licenses/gnu_fdl_small.png');
INSERT INTO licenses VALUES (9,'no license','The material cannot be licensed','',0,'');

INSERT INTO agent_contact_roles VALUES (NULL,'Primary Contact');
INSERT INTO agent_contact_roles VALUES (NULL,'Administrative Contact');
INSERT INTO agent_contact_roles VALUES (NULL,'Technical Contact');

INSERT INTO agent_statuses VALUES (NULL,'Pending');
INSERT INTO agent_statuses VALUES (NULL,'Active');
INSERT INTO agent_statuses VALUES (NULL,'Archived');

#LOAD DATA INFILE '/data/www/development/conversion/files/hierarchy_entries.txt' INTO TABLE hierarchy_entries;
#LOAD DATA INFILE '/data/www/development/conversion/files/concepts.txt' INTO TABLE concepts;
#LOAD DATA INFILE '/data/www/development/conversion/files/hierarchy_entry_names.txt' INTO TABLE hierarchy_entry_names;
#LOAD DATA INFILE '/data/www/development/conversion/files/publication_titles.txt' INTO TABLE publication_titles;
#LOAD DATA INFILE '/data/www/development/conversion/files/title_items.txt' INTO TABLE title_items;
#LOAD DATA INFILE '/data/www/development/conversion/files/item_pages.txt' INTO TABLE item_pages;
#LOAD DATA INFILE '/data/www/development/conversion/files/page_names.txt' INTO TABLE page_names;
#LOAD DATA INFILE '/data/www/development/conversion/files/normalized_names.txt' INTO TABLE normalized_names;
#LOAD DATA INFILE '/data/www/development/conversion/files/normalized_links.txt' INTO TABLE normalized_links;
#LOAD DATA INFILE '/data/www/development/conversion/files/synonyms.txt' INTO TABLE synonyms;
#LOAD DATA INFILE '/data/www/development/conversion/files/synonym_relations.txt' INTO TABLE synonym_relations;
#LOAD DATA INFILE '/data/www/development/conversion/files/top_images.txt' INTO TABLE top_images;
#LOAD DATA INFILE '/data/www/development/conversion/files/top_taxa.txt' INTO TABLE top_taxa;
#LOAD DATA INFILE '/data/www/development/conversion/files/hierarchies_content.txt' INTO TABLE hierarchies_content;
#LOAD DATA INFILE '/data/www/development/conversion/files/collections.txt' INTO TABLE collections;
#LOAD DATA INFILE '/data/www/development/conversion/files/mappings.txt' INTO TABLE mappings;
#LOAD DATA INFILE '/data/www/development/conversion/files/table_of_contents.txt' INTO TABLE table_of_contents;

#LOAD DATA INFILE '/data/www/development/conversion/files/agents.txt' INTO TABLE agents;
#LOAD DATA INFILE '/data/www/development/conversion/files/agents_data_objects.txt' INTO TABLE agents_data_objects;
#LOAD DATA INFILE '/data/www/development/conversion/files/data_objects.txt' INTO TABLE data_objects;
#LOAD DATA INFILE '/data/www/development/conversion/files/data_objects_table_of_contents.txt' INTO TABLE data_objects_table_of_contents;
#LOAD DATA INFILE '/data/www/development/conversion/files/audiences_data_objects.txt' INTO TABLE audiences_data_objects;
#LOAD DATA INFILE '/data/www/development/conversion/files/taxa.txt' INTO TABLE taxa;
#LOAD DATA INFILE '/data/www/development/conversion/files/data_objects_taxa.txt' INTO TABLE data_objects_taxa;
#LOAD DATA INFILE '/data/www/development/conversion/files/taxa2.txt' INTO TABLE taxa;
#LOAD DATA INFILE '/data/www/development/conversion/files/data_objects_taxa2.txt' INTO TABLE data_objects_taxa;



#INSERT INTO hierarchy_entries SELECT * FROM eolData.hierarchies2;
#INSERT INTO concepts SELECT hierarchiesID, namebankID, vern, languageID, preferred, searchFor FROM eolData.concepts2;
#INSERT INTO hierarchy_entry_names SELECT * FROM eolData.hierarchiesNames;
#INSERT INTO licenses SELECT licenseID, licenseTitle, licenseText, licenseLink, 0, smallLogo FROM eolData.licenses;
#INSERT INTO publication_titles SELECT * FROM eolData.publicationTitles;
#INSERT INTO title_items SELECT * FROM eolData.titleItems;
#INSERT INTO item_pages SELECT * FROM eolData.itemPages;
#INSERT INTO page_names SELECT * FROM eolData.pageNames;
#INSERT INTO normalized_names SELECT * FROM eolData.normalizedNames;
#INSERT INTO normalized_links SELECT * FROM eolData.normalizedLinks;
#INSERT INTO synonyms SELECT * FROM eolData.synonyms;
#INSERT INTO synonym_relations SELECT * FROM eolData.synonymRelations;
#INSERT INTO top_images SELECT * FROM eolData.topImages2;
#INSERT INTO top_taxa SELECT * FROM eolData.topTaxa;
#INSERT INTO hierarchies_content SELECT * FROM eolData.hierarchiesContent2;
#INSERT INTO collections SELECT * FROM eolData.agentCollections;
#INSERT INTO mappings SELECT * FROM eolData.collectionMappings;
#INSERT INTO table_of_contents SELECT * FROM eolData.tableOfContents;

#SELECT * FROM eolData.hierarchies2 INTO OUTFILE '/data/www/development/conversion/files/hierarchy_entries.txt';
#SELECT hierarchiesID, namebankID, vern, languageID, preferred, searchFor FROM eolData.concepts2 INTO OUTFILE '/data/www/development/conversion/files/concepts.txt';
#SELECT * FROM eolData.hierarchiesNames INTO OUTFILE '/data/www/development/conversion/files/hierarchy_entry_names.txt';
#SELECT licenseID, licenseTitle, licenseText, licenseLink, 0, smallLogo FROM eolData.licenses INTO OUTFILE '/data/www/development/conversion/files/licenses.txt';
#SELECT * FROM eolData.publicationTitles INTO OUTFILE '/data/www/development/conversion/files/publication_titles.txt';
#SELECT * FROM eolData.titleItems INTO OUTFILE '/data/www/development/conversion/files/title_items.txt';
#SELECT * FROM eolData.itemPages INTO OUTFILE '/data/www/development/conversion/files/item_pages.txt';
#SELECT * FROM eolData.pageNames INTO OUTFILE '/data/www/development/conversion/files/page_names.txt';
#SELECT * FROM eolData.normalizedNames INTO OUTFILE '/data/www/development/conversion/files/normalized_names.txt';
#SELECT normalizedID, namebankID, seq, normalizedQualifierID FROM eolData.normalizedLinks INTO OUTFILE '/data/www/development/conversion/files/normalized_links.txt';
#SELECT * FROM eolData.synonyms INTO OUTFILE '/data/www/development/conversion/files/synonyms.txt';
#SELECT * FROM eolData.synonymRelations INTO OUTFILE '/data/www/development/conversion/files/synonym_relations.txt';
#SELECT * FROM eolData.topImages2 INTO OUTFILE '/data/www/development/conversion/files/top_images.txt';
#SELECT * FROM eolData.topTaxa INTO OUTFILE '/data/www/development/conversion/files/top_taxa.txt';
#SELECT * FROM eolData.hierarchiesContent2 INTO OUTFILE '/data/www/development/conversion/files/hierarchies_content.txt';
#SELECT * FROM eolData.agentCollections INTO OUTFILE '/data/www/development/conversion/files/collections.txt';
#SELECT * FROM eolData.collectionMappings INTO OUTFILE '/data/www/development/conversion/files/mappings.txt';
#SELECT * FROM eolData.tableOfContents INTO OUTFILE '/data/www/development/conversion/files/table_of_contents.txt';




#TRUNCATE TABLE agents;
#TRUNCATE TABLE agents_data_objects;
#TRUNCATE TABLE data_objects;
#TRUNCATE TABLE data_objects_table_of_contents;
#TRUNCATE TABLE audiences_data_objects;
#TRUNCATE TABLE taxa;
#TRUNCATE TABLE data_objects_taxa;
#TRUNCATE TABLE licenses;
#TRUNCATE TABLE mime_types;
#TRUNCATE TABLE ref_identifier_types;
#TRUNCATE TABLE info_items;
#TRUNCATE TABLE data_types;
#TRUNCATE TABLE audiences;
#TRUNCATE TABLE resource_agent_roles;
#TRUNCATE TABLE agent_roles;
