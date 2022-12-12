class Moderations::ChangelogsController < ModerationsController
  MAX_LOG_LINES = 1_000
  TAIL_COMMAND = "tail -n #{MAX_LOG_LINES}"
  PER_PAGE = 20

  before_action :check_access!

  def index
    og page_title: i18n_t('page_title')
    @collection = `ls #{Rails.root.join 'log'} | grep changelog`
      .strip
      .split("\n")
      .map do |v|
        id = v.gsub(/changelog_|\.log/, '')
        {
          id: id,
          name: id.classify.constantize.model_name.human
        }
      rescue NameError
      end
      .compact
      .sort_by { |changelog| changelog[:name] }
  end

  def show # rubocop:disable all
    @item_type = params[:id].classify
    begin
      @item_klass = @item_type.constantize
    rescue NameError
      raise ActiveRecord::RecordNotFound
    end
    @item_type_name = @item_klass.model_name.human

    og page_title: @item_type_name

    breadcrumb i18n_t('page_title'), moderations_changelogs_url

    log_name = Shellwords.shellescape(params[:id]).gsub(/[^\w_]/, '')
    log_file = Rails.root.join "log/changelog_#{log_name}.log"

    raise ActiveRecord::RecordNotFound unless File.exist? log_file

    command =
      if params[:search].present?
        "grep \"#{safe_search}\" #{log_file} | #{TAIL_COMMAND}"
      else
        "#{TAIL_COMMAND} #{log_file}"
      end

    log_lines = `#{command}`.strip.each_line.map(&:strip).reverse

    @collection = QueryObjectBase # rubocop:disable BlockLength
      .new(log_lines[PER_PAGE * (page - 1), PER_PAGE])
      .paginated_slice(page, PER_PAGE)
      .lazy_map do |log_entry|
        split = log_entry.split(/(?<=\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}\]) /)

        changes = split[1]
          .gsub(/ ?:([a-z_]+)=>/, '"\1":')
          .gsub(/"([a-z_]+)"=>/, '"\1":')
          .gsub(/"action"::(update|destroy)/, '"action":"\1"')
          .gsub(/(\w{3}, \d{2} \w{3} \d{4} \d{2}:\d{2}:\d{2}\.\d{9} \w{3} \+\d{2}:\d{2})/, '"\1"')
          .gsub(/\[nil, /, '[null, ')
          .gsub(/, nil\]/, ', null]')
          .gsub(/(?<=":)#<\w+(?<model>[\s\S]+)>(?=}\Z)/) do
            '{' +
              $LAST_MATCH_INFO[:model]
                .gsub(/ ([a-z_]+): /, '"\1":')
                .gsub(':nil', ':null') +
              '}'
          end

        details = JSON.parse(changes, symbolize_names: true)

        if details[:model].is_a? String
          details[:model] = JSON.parse(details[:model], symbolize_names: true)
        end

        {
          details: details,
          raw: log_entry,
          date: Time.zone.parse(split[0].gsub(/[\[\]]/, '')),
          user_id: details[:user_id],
          model_id: details[:id],
          user: nil,
          model: nil,
          url: nil,
          is_tooltip_url: nil
        }
      end

    @users = User.where(id: @collection.pluck(:user_id)).index_by(&:id)
    @models = @item_klass.where(id: @collection.pluck(:model_id)).index_by(&:id)

    @collection.each do |changelog|
      changelog[:user] = @users[changelog[:user_id]]
      changelog[:model] = @models[changelog[:model_id]]
      changelog[:url] = model_url changelog[:model] if changelog[:model]
      changelog[:tooltip_url] = tooltip_url changelog[:model] if changelog[:model]
    end
  end

private

  def check_access!
    authorize! :access_changelog, ApplicationRecord
  end

  def safe_search
    Shellwords
      .shellescape(params[:search])
      .gsub(/\\(=|>)/, '\1')
  end

  def model_url model
    # .includes(:topic)
    if model.is_a? Comment
      comment_url model
    elsif model.is_a? ClubPage
      club_club_page_path model.club, model
    elsif model.is_a? Topic
      UrlGenerator.instance.topic_url model
    else
      UrlGenerator.instance.topic_url model.topic
    end
  end

  def tooltip_url model
    if model.is_a? Comment
      comment_url model
    elsif model.is_a? ClubPage
      nil
    elsif model.is_a? Topic
      topic_tooltip_url model
    else
      topic_tooltip_url model.topic
    end

    # .includes(:topic)
    # if model.is_a? Comment
    #   comment_url model
    # else
    # end
  end
end
