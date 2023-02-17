class Moderations::VersionsView < ViewObjectBase
  instance_cache :moderators, :pending, :processed

  PER_PAGE = 25
  IGNORED_FIELDS = %w[source action]
  FILTERABLE_TYPES = [Anime, Manga, Character, Person].map(&:name)

  def processed_scope
    Moderation::ProcessedVersionsQuery
      .fetch(type_param, h.params[:created_on])
  end

  def pending_scope
    Moderation::VersionsItemTypeQuery.fetch(type_param)
  end

  def moderators_scope nickname
    return User.none if nickname.blank?

    scope = processed_scope
      .where.not(state: %i[auto_accepted deleted])
      .distinct
      .select(:moderator_id)
      .except(:order)

    User
      .where(id: scope)
      .where('nickname ilike ?', "#{nickname}%")
  end

  def authors_scope nickname
    return User.none if nickname.blank?

    User
      .where(id: processed_scope.distinct.select(:user_id).except(:order))
      .or(User.where(id: pending_scope.distinct.pluck(:user_id)))
      .where('nickname ilike ?', "#{nickname}%")
  end

  def processed
    scope = processed_scope
    scope = apply_filters scope

    scope
      .paginate(page, PER_PAGE)
      .lazy_map(&:decorate)
  end

  def pending
    scope = pending_scope
    scope = apply_filters scope

    scope
      .includes(:user, :moderator)
      .where(state: :pending)
      .order(created_at: sort_order)
      .paginate(page, PER_PAGE)
      .lazy_map(&:decorate)
  end

  def next_page_url is_pending
    h.current_url(
      page: page + 1,
      type: h.params[:type],
      order: sort_order,
      created_on: h.params[:created_on],
      is_pending: is_pending ? '1' : '0'
    )
  end

  def moderators
    type_suffix = h.params[:type] + '_' if h.params[:type] && h.params[:type] != 'content'
    role = "version_#{type_suffix}moderator"

    User
      .where("roles && '{#{role}}'")
      .where.not(id: User::MORR_ID)
      .sort_by { |v| v.nickname.downcase }
  end

  def type_param
    h.params[:type] || :all_content
  end

  def filtered_user
    return unless h.can?(:filter, Version) && h.params[:user_id].present?

    @filtered_user ||= User.find_by id: h.params[:user_id]
  end

  def filtered_moderator
    return unless h.can?(:filter, Version) && h.params[:moderator_id].present?

    @filtered_moderator ||= User.find_by id: h.params[:moderator_id]
  end

  def filtered_item_type
    return unless h.can?(:filter, Version) && h.params[:item_type].present?

    h.params[:item_type]
  end

  def filtered_field
    return unless h.can?(:filter, Version) && h.params[:field].present?

    h.params[:field]
  end

  def filterable_options
    @filterable_options ||=
      Rails.cache.fetch([:filterable_options, type_param], expires_in: 1.day) do
        filterable_fields.deep_merge filterable_types
      end
  end

  def sort_order
    h.params[:order] == 'asc' ? :asc : :desc
  end

private

  def apply_filters scope
    scope = scope.where user_id: filtered_user.id if filtered_user
    scope = scope.where moderator_id: filtered_moderator.id if filtered_moderator

    if filtered_item_type
      scope = scope.where(
        'item_type = :type or associated_type = :type',
        type: filtered_item_type
      )
    end

    scope = filter_by_field scope if filtered_field

    scope
  end

  def filter_by_field scope
    if filtered_field[0].match?(/[[:upper:]]/)
      scope.where item_type: filtered_field
    else
      scope.where '(item_diff->>:field) is not null', field: filtered_field
    end
  end

  def filterable_fields
    FILTERABLE_TYPES.index_with do |type|
      (
        Moderation::ProcessedVersionsQuery
          .fetch(type_param, nil)
          .except(:order)
          .where(item_type: type)
          .distinct
          .pluck(Arel.sql('jsonb_object_keys(item_diff)')) - IGNORED_FIELDS
      )
        .index_with { |key| type.constantize.human_attribute_name key }
    end
  end

  def filterable_types
    FILTERABLE_TYPES.index_with do |type|
      Moderation::ProcessedVersionsQuery
        .fetch(type_param, nil)
        .except(:order)
        .where(associated_type: type)
        .distinct
        .pluck(:item_type)
        .index_with { |item_type| item_type.constantize.model_name.human count: 1 }
    end
  end
end
