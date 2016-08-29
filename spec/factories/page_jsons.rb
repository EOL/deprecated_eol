# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :page_json do
    page_id 1
    json "MyText"
  end
end
