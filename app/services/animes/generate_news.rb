# frozen_string_literal: true

# NOTE: call in before_save callback
class Animes::GenerateNews
  method_object :anime, :old_status, :new_status

  delegate :aired_on, :released_on, to: :anime
  delegate :status_change, to: :anime

  NEW_RELEASE_INTERVAL_FOR_RELEASED_ON = 2.weeks
  NEW_RELEASE_INTERVAL_FOR_AIRED_ON = 15.months

  def call
    raise ArgumentError, 'status not changed' if @old_status == @new_status

    generate_anons_topics
    generate_ongoing_topics
    generate_release_topics
  end

private

  def generate_anons_topics
    return unless anime.anons?
    return if status_changed? 'ongoing', 'anons'

    Shikimori::DOMAIN_LOCALES.each do |locale|
      Topics::Generate::News::AnonsTopic.call(
        model: anime,
        user: anime.topic_user,
        locale: locale
      )
    end
  end

  def generate_ongoing_topics
    return unless anime.ongoing?
    return if status_changed? 'released', 'ongoing'

    Shikimori::DOMAIN_LOCALES.each do |locale|
      Topics::Generate::News::OngoingTopic.call(
        model: anime,
        user: anime.topic_user,
        locale: locale
      )
    end
  end

  def generate_release_topics
    return unless anime.released?
    return unless new_release?

    Shikimori::DOMAIN_LOCALES.each do |locale|
      Topics::Generate::News::ReleasedTopic.call(
        model: anime,
        user: anime.topic_user,
        locale: locale
      )
    end
  end

  def new_release?
    return released_on >= NEW_RELEASE_INTERVAL_FOR_RELEASED_ON.ago.to_date if released_on.present?
    return aired_on >= NEW_RELEASE_INTERVAL_FOR_AIRED_ON.ago.to_date if aired_on.present?

    false
  end

  def status_changed? from_status, to_status
    @old_status.to_s == from_status.to_s &&
      @new_status.to_s == to_status.to_s
  end
end
