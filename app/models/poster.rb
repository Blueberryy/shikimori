class Poster < ApplicationRecord
  include Uploaders::PosterUploader::Attachment(:image)

  belongs_to :anime, optional: true
  belongs_to :manga, optional: true
  belongs_to :character, optional: true
  belongs_to :person, optional: true

  validates :anime_id, exclusive_arc: %i[manga_id character_id person_id]

  scope :active, -> { where is_approved: true, deleted_at: nil }

  def target
    anime || manga || character || person
  end
end
