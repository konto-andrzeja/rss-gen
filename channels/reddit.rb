# frozen_string_literal: true

require 'cgi'
require 'net/http'
require 'nokogiri'
require 'rss'
require 'time'

module Channels
  # Top posts of a subreddit (`sub`), or of the front page without one, over the
  # period `t`.
  class Reddit
    BASE_URL = 'https://www.reddit.com'
    # Reddit blocks datacenter IPs, so the Dockerfile points this at Tor.
    PROXY = ENV.fetch('REDDIT_PROXY', nil)&.then { |proxy| URI(proxy) }
    # Generous, because over Tor the first request waits for a circuit.
    HTTP_OPTIONS = { use_ssl: true, read_timeout: 90 }.freeze
    PERIODS = %w[hour day week month year all].freeze
    HEADERS = { 'User-Agent' => 'rss-gen/1.0 (personal feed reader)' }.freeze
    MAX_ITEMS = 25

    class << self
      def rss(**params)
        sub = params[:sub].to_s[/\A\w+\z/]
        period = PERIODS.include?(params[:t]) ? params[:t] : 'week'
        url = "#{BASE_URL}/#{"r/#{sub}/" if sub}top/?t=#{period}"
        feed("#{sub ? "r/#{sub}" : 'reddit.com'}: top (#{period})", url, posts(url))
      end

      private

      def feed(title, url, posts)
        RSS::Maker.make('2.0') do |maker|
          maker.channel.title = title
          maker.channel.description = title
          maker.channel.link = url
          posts.each { |post| add_item(maker, post) }
        end.to_s
      end

      def posts(url)
        cookies = {}
        page = get(url, cookies)
        page = answer_check(page, url, cookies) if page.at('input[name=js_challenge]')
        (page.css('shreddit-post').to_a + more_posts(page, cookies)).uniq { |post| post['id'] }.first(MAX_ITEMS)
      end

      # The page itself has only the first 3 posts; the rest load as you scroll,
      # from the one partial that carries a paging cursor.
      def more_posts(page, cookies)
        more = page.at('faceplate-partial[src*="after="]') or return []
        get(URI.join(BASE_URL, more['src']).to_s, cookies).css('shreddit-post').to_a
      end

      # Reddit first serves a page whose script doubles a token and resubmits a
      # hidden form, which a browser does unnoticed. Any other check raises, so a
      # change on Reddit's side shows up as an error instead of an empty feed.
      def answer_check(page, url, cookies)
        token = page.css('script').text[/await\(async e=>e\+e\)\("(\w+)"\)/, 1] or raise 'Unknown Reddit check'
        form = page.at('input[name=js_challenge]').ancestors('form').first
        get(URI.join(url, "#{form['action']}?#{answer_query(form, url, token * 2)}").to_s, cookies)
      end

      # The form's fields plus the page's own query, as the page's script sends them.
      def answer_query(form, url, solution)
        inputs = form.css('input[name]').to_h { |input| [input['name'], input['value'].to_s] }
        URI.encode_www_form(URI.decode_www_form(URI(url).query.to_s).to_h.merge(inputs, 'solution' => solution))
      end

      def get(url, cookies)
        uri = URI(url)
        response = Net::HTTP.start(uri.host, uri.port, PROXY&.host, PROXY&.port, **HTTP_OPTIONS) do |http|
          http.get(uri.request_uri, headers(cookies))
        end
        response.value
        store_cookies(cookies, response)
        # Reddit declares no charset, and the default guess garbles anything non-ASCII.
        Nokogiri::HTML(response.body, nil, 'UTF-8')
      end

      def headers(cookies)
        cookie = cookies.map { |name, value| "#{name}=#{value}" }.join('; ')
        cookie.empty? ? HEADERS : HEADERS.merge('Cookie' => cookie)
      end

      def store_cookies(cookies, response)
        Array(response.get_fields('set-cookie')).each do |set_cookie|
          name, value = set_cookie[/\A[^;]*/].split('=', 2)
          cookies[name] = value
        end
      end

      def add_item(maker, post)
        link = "#{BASE_URL}#{post['permalink']}"
        maker.items.new_item do |item|
          item.title = post['post-title']
          item.link = link
          item.guid.content = link
          item.updated = Time.parse(post['created-timestamp'])
          item.description = description(post)
        end
      end

      # Image posts link the full image; others may have a preview thumbnail.
      def description(post)
        image = post['post-type'] == 'image' ? post['content-href'] : post.at('img[src*="preview.redd.it"]')&.[]('src')
        source = %(<a href="#{CGI.escapeHTML(post['content-href'].to_s)}">#{CGI.escapeHTML(post['domain'].to_s)}</a>)
        html = "<p>#{source} · #{post['score']} points · #{post['comment-count']} comments</p>"
        image ? %(#{html}<p><img src="#{CGI.escapeHTML(image)}"></p>) : html
      end
    end
  end
end
