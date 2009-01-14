class CountryLogDaily < LogDaily
  
  set_unique_data_column :string, :country_code

  set_mine_data_options :select => 'count(*) AS total, agent_id, data_type_id, DATE(data_object_logs.created_at) AS day, ip_addresses.country_code',
                        :joins  => 'LEFT JOIN ip_addresses ON ip_addresses.id = ip_address_id',
                        :group  => 'agent_id, data_type_id, ip_addresses.country_code, DATE(data_object_logs.created_at)'

end
