xml.instruct! :xml, :version => "1.0", :encoding => "UTF-8", :standalone => "yes"
xml.results do
  unless params[:batch]
    xml <<  render(partial: 'search_by_provider', layout: false, locals: { :json_response => @json_response } )
  else
     xml << render(partial: 'search_by_provider_batches', layout: false, locals: { :json_response => @json_response } )
  end
end
