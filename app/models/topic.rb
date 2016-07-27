# frozen_string_literal: true

class Topic < ActiveRecord::Base
  include Moderatable
  include Antispam
  include Viewable

  FORUM_IDS = {
    'Anime' => 1,
    'Manga' => 1,
    'Character' => 1,
    'Person' => 1,
    'Club' => Forum::CLUBS_ID,
    'Review' => 12,
    'Contest' => Forum::CONTESTS_ID,
    'CosplayGallery' => Forum::COSPLAY_ID
  }

  belongs_to :anime_history

  validates :title, :body, presence: true, unless: :generated?
  validates :locale, presence: true

  enumerize :locale, in: %i(ru en), predicates: { prefix: true }

  def title
    return self[:title]&.html_safe if user&.bot?
    self[:title]
  end

  def any_comments?
    comments_count > 0
  end

  def any_summaries?
    summaries_count > 0
  end

  def all_summaries?
    summaries_count == comments_count
  end

  def summaries_count
    @summaries_count ||= comments.summaries.count
  end
end
