require 'rubygems'
require 'sinatra'
require 'json'

require 'rb/backend'
require 'rb/area_boundary'

Backend::init

set :area_boundary, AreaBoundary.new

set :public, File.join(File.dirname(__FILE__), "../js") 
enable :static

before do
  content_type '.json'
end

get '/' do
  SnowTweet.all.to_json
end

get '/by/postcode/:code' do
  postcode = params[:code]
  SnowTweet.all( :postal => postcode ).to_json
end

get '/score/by/postcode' do 
  averages_by_postcode = SnowTweet.aggregate( :postal, :score.avg )
  hsh = {}
  averages_by_postcode.each do | av |
    postcode  = av[0]
    score     = av[1]
    hsh[ postcode ] = {
      :score  => score,
      #:area   => settings.area_boundary.geo_by_postcode( postcode )
      :area_url=> "/geo/#{postcode}"
    }
  end
  return hsh.to_json
end

get '/score/by/postcode/:postcode' do 
  postcode = params[:postcode]
  average  = SnowTweet.avg(:score, :conditions => [ 'postal = ?', postcode ]).to_json
  #tweets = SnowTweet.all( :postal => postcode )
  return {
    postcode.to_s => average
  }.to_json
end

get '/geo/:postcode.kml' do | postcode |
  content_type '.xml'
  kml = settings.area_boundary.geo_from_postcode( postcode )
  return kml
end

get '/geo/:postcode' do | postcode |
  kml = settings.area_boundary.geo_from_postcode( postcode )
  return {
    'kml' => kml
  }.to_json
end
