# frozen_string_literal: true

# NOTE: called in before_save callback
class Animes::TrackStatusChanges
  method_object :anime

  def call
    return unless @anime.status_changed?

    try_rollback_anons_to_ongoing_change
    try_rollback_ongoing_to_released_change

    remove_released_topic
  end

private

  def try_rollback_anons_to_ongoing_change
    return unless status_changed? 'anons' => 'ongoing'
    return if @anime.aired_on.blank?
    return if aired_not_in_future?

    @anime.status = :anons
  end

  def try_rollback_ongoing_to_released_change
    return unless status_changed? 'ongoing' => 'released'
    # when ancient anime without released_on is marked released
    return if @anime.released_on.blank?
    return if released_in_past_or_today? || all_episodes_aired?

    @anime.status = :ongoing
    @anime.released_on = IncompleteDate.new if released_in_past_or_today?
  end

  def aired_not_in_future?
    @anime.aired_on <= Time.zone.today
  end

  def released_in_past_or_today?
    @anime.released_on <= Time.zone.today
  end

  def all_episodes_aired?
    @anime.episodes_aired.positive? && @anime.episodes_aired == @anime.episodes
  end

  def status_changed? change
    # when status has already been rollbacked previously
    return false if @anime.status_change.nil?

    from_status = change.keys.first
    to_status = change.values.first

    @anime.status_change[0] == from_status &&
      @anime.status_change[1] == to_status
  end

  def remove_released_topic
    return unless status_changed? 'released' => 'ongoing'

    Topics::NewsTopic
      .where(linked: @anime)
      .where(action: AnimeHistoryAction::Released)
      .destroy_all
  end
end
