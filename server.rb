# frozen_string_literal: true

require 'rss'
require 'sinatra'

set :app_file, __FILE__

Dir['./channels/*.rb'].each { |file| require file }

Database.setup!
Tables::SeenItems.setup!

CHANNEL_CLASSES = {
  footlol: Channels::Footlol,
  realmadryt_pl: Channels::RealMadryt,
  anime24_pl: Channels::Anime24,
  obligacje_pl: Channels::Obligacje,
  sport_tvp_pl: Channels::SportTvpPl,
  nhk_easy: Channels::NhkEasy,
  reddit: Channels::Reddit,
  tiktok: Channels::Tiktok,
  twitter: Channels::Twitter
}.freeze

# Kept out of the repo: FEED_PASSWORD if set, otherwise the untracked password.txt.
PASSWORD = ENV.fetch('FEED_PASSWORD') { File.read(File.join(__dir__, 'password.txt')) }.strip
abort 'The feed password is empty' if PASSWORD.empty?

set :bind, '0.0.0.0'
set :port, 8080

get '/' do
  halt 404 if params[:password] != PASSWORD

  content_type 'text/xml'
  CHANNEL_CLASSES[params[:id].to_sym].rss(**params)
end
