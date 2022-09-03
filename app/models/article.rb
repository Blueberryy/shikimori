class Article < ApplicationRecord
  include AntispamConcern
  include DecomposableBodyConcern
  include ModeratableConcern
  include TopicsConcern

  antispam(
    per_day: 5,
    user_id_key: :user_id
  )
  update_index('articles#article') { self if saved_change_to_name? }

  belongs_to :user,
    touch: Rails.env.test? ? false : :activity_at
  validates :name, :user, :body, presence: true
  validates :name, length: { maximum: 255 }
  validates :body, length: { maximum: 140_000 }

  enumerize :state, in: Types::Article::State.values, predicates: true

  scope :unpublished, -> { where state: Types::Article::State[:unpublished] }
  scope :published, -> { where state: Types::Article::State[:published] }

  scope :available, -> { visible.published }

  def to_param
    "#{id}-#{name.permalinked}"
  end

  # compatibility with TopicsConcern
  def topic_user
    user
  end
end
