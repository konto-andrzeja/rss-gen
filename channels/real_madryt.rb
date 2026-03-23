require_relative 'base_html2rss.rb'

module Channels
  class RealMadryt < BaseHtml2rss
    def self.feed_config(**_params)
      {
        channel: { url: 'https://www.realmadryt.pl/aktualnosci', title: 'realmadryt.pl' },
        selectors: {
          items: { selector: '.news-item' },
          title: { selector: '.news-item__title' },
          description: { selector: '.news-item__intro' },
          link: { selector: '.news-item__link', extractor: 'href' },
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
