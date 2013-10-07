class DataFileMaker

  @queue = 'data'

  def self.perform(args)
    puts "++ DataFileMaker: #{args.values.join(', ')}"
    user = args["user_id"] || EOL::AnonymousUer.new(Language.find(args["language_id"]) || Language.default)
    DataFile.new(q: args["querystring"], uri: args["attribute"], from: args["from"], to: args["to"],
                 sort: args["sort"], known_uri: KnownUri.find(args["known_uri_id"]),
                 user: Language.find(args["language_id"]))
    puts "   ...Done."
  end

end
