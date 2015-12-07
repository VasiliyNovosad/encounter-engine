class Image < ActiveRecord::Base
  has_attached_file :file
  validates_attachment :file, presence: true, content_type: { content_type: ['image/jpg', 'image/jpeg', 'image/png', 'image/gif'] }
end
