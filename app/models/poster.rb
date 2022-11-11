class Poster < ApplicationRecord
  include Uploaders::PosterUploader::Attachment(:image)

  belongs_to :anime, optional: true
  belongs_to :manga, optional: true
  belongs_to :character, optional: true
  belongs_to :person, optional: true

  validates :anime_id, exclusive_arc: %i[manga_id character_id person_id]

  default_scope { where is_approved: true }
end
