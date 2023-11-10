require_relative 'base_html2rss.rb'

module Channels
  class Anime24 < BaseHtml2rss
    def self.config(**_params)
      {
        channel: { url: 'https://anime24.pl/', title: 'anime24.pl' },
        selectors: {
          items: { selector: '.views-infinite-scroll-content-wrapper article' },
          title: { selector: 'h5' },
          description: { selector: '.node__content' },
          link: { selector: 'h5 a', extractor: 'href' },
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
