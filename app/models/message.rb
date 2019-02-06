class Message < ActiveRecord::Base
  belongs_to :user
  belongs_to :game
  has_and_belongs_to_many :levels, join_table: 'messages_levels'

  delegate :nickname, to: :user, prefix: true
end