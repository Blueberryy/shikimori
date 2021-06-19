class Summary < ApplicationRecord
  include AntispamConcern
  include Moderatable
  include Viewable

  antispam(
    interval: 1.minute,
    disable_if: -> { user.admin? && Rails.env.development? },
    user_id_key: :user_id
  )

  belongs_to :user
  belongs_to :anime, optional: true
  belongs_to :manga, optional: true

  enumerize :tone, in: Types::Summary::Tone.values

  validates :body, presence: true
  # validates :anime, presence: true, if: -> { manga_id.nil? }
  # validates :manga, presence: true, if: -> { anime_id.nil? }

  def html_body
    BbCodes::Text.call body
  end
end
