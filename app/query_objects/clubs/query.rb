class Clubs::Query < QueryObjectBase
  FAVOURED_IDS = [72, 315, 2046]
  SEARCH_LIMIT = 999

  def self.fetch user
    scope = new Club
      .joins(:topic)
      .preload(:owner, :topic)
      .order(Arel.sql('topics.updated_at desc, id'))

    if user
      scope
        .without_shadowbanned(user)
    else
      scope
        .without_censored
        .without_shadowbanned
    end
  end

  def favourites
    chain @scope.where(id: FAVOURED_IDS)
  end

  def without_favourites
    chain @scope.where.not(id: FAVOURED_IDS)
  end

  def without_censored
    chain @scope.where(is_censored: false)
  end

  def without_shadowbanned decorated_user = nil
    chain(
      decorated_user ?
        @scope.where(
          'is_shadowbanned = false or clubs.id in (?)',
          decorated_user.club_ids
        ) :
        @scope.where(is_shadowbanned: false)
    )
  end

  def search phrase
    return self if phrase.blank?

    chain Search::Club.call(
      scope: @scope,
      phrase: phrase,
      ids_limit: SEARCH_LIMIT
    )
  end
end