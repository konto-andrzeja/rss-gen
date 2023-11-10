require_relative 'base_html2rss.rb'

module Channels
  class VicePhysics < BaseHtml2rss
    def self.config(**_params)
      {
        channel: { url: 'https://www.vice.com/en/topic/physics', title: 'vice.com - physics' },
        selectors: {
          items: { selector: '.vice-card' },
          title: { selector: 'h3' },
          description: { selector: 'p' },
          link: { selector: 'h3 a', extractor: 'href' }
        }
      }
    end
  end
end
