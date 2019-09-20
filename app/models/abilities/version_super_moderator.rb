class Abilities::VersionSuperModerator
  include CanCan::Ability
  prepend Draper::CanCanCan

  MANAGED_FIELDS = %w[name russian description_ru]

  def initialize _user
    can :rollback_episode, Anime
    can :upload_episode, Anime

    can :sync, [Anime, Manga, Person, Character] do |entry|
      entry.mal_id.present?
    end

    MANAGED_FIELDS.each do |field|
      can :"manage_#{field}", [Anime, Manga, Person, Character]
    end

    can :manage, Version do |version|
      (version.item_diff.keys - MANAGED_FIELDS).none?
    end
  end
end
