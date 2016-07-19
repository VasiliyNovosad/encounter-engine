class Task < ActiveRecord::Base
  belongs_to :level
  belongs_to :team
end