module Types
  module Anime
    KINDS = %i[tv movie ova ona special tv_special music pv cm]
    STATUSES = %i[anons ongoing released]

    Kind = Types::Strict::Symbol
      .constructor(&:to_sym)
      .enum(*KINDS)

    Status = Types::Strict::Symbol
      .constructor(&:to_sym)
      .enum(*STATUSES)

    Rating = Types::Strict::Symbol
      .constructor(&:to_sym)
      .enum(:none, :g, :pg, :pg_13, :r, :r_plus, :rx)

    OPTIONS = %w[
      strict_torrent_name_match
      disabled_torrents_sync
      disabled_anime365_sync
    ]

    Options = Types::Strict::String
      .constructor(&:to_s)
      .enum(*OPTIONS)
  end
end
