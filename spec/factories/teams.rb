FactoryGirl.define do
  sequence :name do |n|
    "team#{n}"
  end

  factory :team, aliases: [:to_team] do
    name
    captain
    members { [] }
  end
end