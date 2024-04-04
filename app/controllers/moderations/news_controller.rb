class Moderations::NewsController < ModerationsController
  load_resource class: Topics::NewsTopic.name, except: %i[index]

  PENDING_PER_PAGE = 15
  PROCESSED_PER_PAGE = 25

  def index
    og page_title: i18n_t('page_title')

    @moderators = User
      .where("roles && '{#{Types::User::Roles[:news_moderator]}}'")
      .where.not(id: User::MORR_ID)
      .sort_by { |v| v.nickname.downcase }

    @processed = QueryObjectBase.new(processed_scope).paginate(@page, PROCESSED_PER_PAGE)
    @pending = pending_scope
  end

  def accept
    authorize! :moderate, @resource

    if @resource.may_accept?
      @resource.accept

      NamedLogger.moderation_news.info(
        topic_id: @resource.id,
        action: :accept,
        user_id: current_user.id
      )
    end

    redirect_back fallback_location: moderations_news_index_url
  end

  def reject
    authorize! :moderate, @resource

    if @resource.may_reject?
      @resource.reject

      NamedLogger.moderation_news.info(
        topic_id: @resource.id,
        action: :reject,
        user_id: current_user.id
      )
    end

    redirect_back fallback_location: moderations_news_index_url
  end

private

  def processed_scope
    scope.where.not(forum_id: Forum::PREMODERATION_ID)
  end

  def pending_scope
    scope.where(forum_id: Forum::PREMODERATION_ID)
  end

  def scope
    Topics::NewsTopic
      .where.not(generated: true)
      .includes(:user)
      .order(created_at: :desc)
  end
end
