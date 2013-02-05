# encoding: utf-8

require Rails.root.join('spec', 'eol_spec_helpers.rb')
include EOL::RSpec::Helpers

load_scenario_with_caching(:bootstrap)

categories = {
  "EOL API Forums" => {
    "Getting started" => {
      "How do I use the API?" => [
        {
          :subject => "How do I use the API?",
          :text => "Seriously, what's the deal?" },
        {
          :subject => "How else do I use the API?",
          :text => "Seriously, what's the deal?" },
        {
          :subject => "Re: How else do I use the API?",
          :text => "Seriously, what's the deal?" }
      ],
      "What is the pages API for?" => [
        {
          :subject => "What is the pages API for?",
          :text => "I just don't understand." }
      ]
    },
    "Advanced API" => {
      "API keys" => [
        {
          :subject => "API keys",
          :text => "I just don't understand." }
      ]
    },
    "Feature requests" => {
      "Create a Users API" => [
        {
          :subject => "Create a Users API",
          :text => "please" }
      ]
    }
  },
  "Questions and Assistance" => {
    "Basic site usage" => {
      "How do I sign up?" => [
        {
          :subject => "How do I sign up?",
          :text => "where do I sign up?" }
      ]
    },
    "Curator questions" => {
      "How do I become a curator?" => [
        {
          :subject => "How do I become a curator?",
          :text => "where do I sign up?" }
      ]
    }
  }
}

u = User.gen

# Categories
categories.each do |category_name, forums|
  category = ForumCategory.gen(:title => category_name, :user => u)

  # Forums
  forums.each do |forum_name, topics|
    forum = Forum.gen(:name => forum_name, :forum_category => category, :user => u)

    # Topics
    topics.each do |topic_name, post_data|
      topic = ForumTopic.gen(:title => topic_name, :forum => forum, :user => u)

      # Posts
      post_data.each do |post|
        ForumPost.gen(:subject => post[:subject], :text => post[:text], :user => u, :forum_topic => topic)
      end

      # making a bunch of random posts
      60.times do
        ForumPost.gen(:forum_topic => topic)
      end
    end
  end
end
