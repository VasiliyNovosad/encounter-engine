FactoryBot.define do
  factory :penalty_hint do
    level_id { 1 }
    name { "MyString" }
    text { "MyText" }
    penalty { 1 }
    team_id { "MyString" }
    integer { "MyString" }
  end
end
