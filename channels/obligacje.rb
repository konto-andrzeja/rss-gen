require_relative 'base_html2rss.rb'

module Channels
  class Obligacje < BaseHtml2rss
    # The page lists every emission since 2013, newest first.
    MAX_ITEMS = 20

    def self.feed_config(**_params)
      {
        channel: { url: 'https://obligacje.pl/pl/emisje', title: 'obligacje.pl' },
        selectors: {
          items: { selector: ".emission-box:nth-child(-n+#{MAX_ITEMS})" },
          title: { selector: '.txt' },
          series: { selector: 'table.table-7 tr:nth-child(2) td:first-child' },
          description: { selector: 'table', extractor: 'html' },
          updated: { selector: '.date', post_process: { name: 'gsub', pattern: 'Zapisy do: ', replacement: '' } },
          link: { extractor: 'static', static: 'https://obligacje.pl/pl/emisje' },
          # Issuers come back with new emissions, so the title alone is not unique.
          guid: %i[title series updated]
        }
      }
    end
  end
end
