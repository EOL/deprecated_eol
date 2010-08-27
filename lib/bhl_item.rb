class BhlItem

  attr_reader :item_id, :publication_title, :publication_url, :publication_details, :item_year, :item_volume,
              :item_issue, :item_prefix, :item_number, :item_url

  def initialize(hash)
    @item_id             = hash['item_id'] || ''
    @publication_title   = hash['publication_title'] || ''
    @publication_url     = hash['publication_url'] || ''
    @publication_details = hash['publication_details'] || ''
    @item_year           = hash['item_year'] || ''
    @item_volume         = hash['item_volume'] || ''
    @item_issue          = hash['item_issue'] || ''
    @item_prefix         = hash['item_prefix'] || ''
    @item_number         = hash['item_number'] || ''
    @item_url            = hash['item_url'] || ''
  end

  def name
    item_name =  ""
    item_name += @item_year + "." unless @item_year == '' or @item_year == '0'
    item_name +=" Vol." + @item_volume + "," unless @item_volume == '' or @item_volume = '0'
    item_name += " Issue" + @item_issue + "," unless @item_issue == '' or @item_issue = '0'
    item_name
  end

end
