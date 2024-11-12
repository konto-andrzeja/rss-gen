require 'html2rss'

module Channels
  class BaseHtml2rss
    def self.rss(**params)
      config = Html2rss::Config.new(feed_config(**params))
      Html2rss.feed(config).to_s
    end
  end
end
