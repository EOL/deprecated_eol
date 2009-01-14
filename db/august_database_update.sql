set foreign_key_checks = 0
alter table `agents` add column `agent_status_id` tinyint(4) not null after `logo_file_size`
alter table `content_partners` change column `id` `id` int(10) unsigned not null auto_increment first
alter table `content_partners` add column `agent_id` int(11) not null after `id`
alter table `content_partners` drop column `agent_status_id`
alter table `content_partners` add column `created_at` timestamp not null default CURRENT_TIMESTAMP after `active`
alter table `content_partners` add column `updated_at` timestamp not null default '0000-00-00 00:00:00' after `created_at`
alter table `languages` change column `activated_on` `activated_on` timestamp null default NULL after `sort_order`
alter table `random_taxa` drop column `hierarchy_entry_id`
alter table `random_taxa` add column `taxon_concept_id` int(11) default NULL after `created_at`
set foreign_key_checks = 1
