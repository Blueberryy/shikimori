module AgeRestrictionsConcern
  extend ActiveSupport::Concern
  COOKIE_CENSORED_REJECTED = :censored_rejected

  def censored_forbidden?
    return false if %w[rss os].include? request.format
    return false if params[:action] == 'tooltip' && request.xhr?

    current_user&.censored_forbidden?
  end

  def censored_rejected?
    censored_forbidden? && (
      (current_user&.age && current_user.age < 18) ||
        cookies[COOKIE_CENSORED_REJECTED] == 'true'
    )
  end

  def verify_age_restricted! collection # rubocop:disable PerceivedComplexity, CyclomaticComplexity
    return collection unless collection && censored_forbidden?

    if collection.respond_to? :any?
      raise AgeRestricted if collection.count(&:censored?) > (collection.count * 0.1)
    elsif collection.respond_to? :censored?
      raise AgeRestricted if collection.censored?
    else
      raise ArgumentError
    end
  end
end
