class AddFieldsToResources < ActiveRecord::Migration
  def change
    change_table :resources do |t|
      t.integer dataset_license_id       # Because the existing license_id is a *default* for the items *in* the resource.
      t.string dataset_rights_holder,    #        "            "
        limit: 255
      t.string dataset_rights_statement, #        "            "
        limit: 400
      t.string dataset_source_url,       # This points to, say, the original paper from which the data were harvested.
        limit: 255
      t.string dataset_hosted_url,       # This points to OUR LOCAL copy of the importable resource
        limit: 255
    end
  end
end
