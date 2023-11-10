require 'html2rss'

module Channels
  class BaseHtml2rss
    def self.rss(**params)
      Html2rss.feed(config(**params)).to_s
    end
  end
end
