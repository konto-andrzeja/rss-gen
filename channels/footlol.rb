require_relative 'base_html2rss.rb'

module Channels
  class Footlol < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://footroll.pl/footlol', title: 'Footlol' },
        selectors: {
          items: { selector: 'div.post' },
          title: { selector: '.title' },
          link: { selector: 'a', extractor: 'href' },
          enclosure: {
            selector: 'img',
            extractor: 'attribute',
            attribute: 'src',
            post_process: { name: 'gsub', pattern: ' ', replacement: '%20' }
          }
        }
      }
    end
  end
end
