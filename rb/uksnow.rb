require 'rubygems'
require 'eventmachine'

require 'twitter'

POSTAL_MATCHER = / ([A-Z]{1,2}[0-9][0-9A-Z]?) /i
SCORE_MATCHER  = /(\d{1,2})\/(\d{2})/

def filter_for_uk_snow( tweets )
  found_uk_snow = []
  tweets.each do | t |
    postal_district = $1 if ( t.text.match POSTAL_MATCHER )
    score = $1 if ( t.text.match SCORE_MATCHER )
    if postal_district and score
      found_uk_snow << {
        :tw_id  => t.id_str,
        :score  => score,
        :postal => postal_district.upcase
      }
    end
  end
  found_uk_snow
end

require 'dm-core'
require 'dm-migrations'

class SnowTweet
  include DataMapper::Resource
  property :id,         Serial
  property :score,      String    
  property :postal,     String    
end

class Backend
  
  def self.init
    DataMapper.setup(
      :default, 
      ENV['DATABASE_URL'] || 'sqlite:///Users/andrew/Dropbox/uksnow/snow.db'
    )
    DataMapper.finalize
    DataMapper.auto_upgrade!
  end
  
  def self.store( tweets )
    self.init
    tweets.each do | t |
      SnowTweet.first_or_create(
        {
          :id     => t[:tw_id]
        },
        { 
          :postal => t[:postal],
          :score  => t[:score]
        }
      )
    end
  end
end

EM::run do
  EM.add_periodic_timer(30) do 
    uk_snow_tweets = Twitter::Search.new.q("#uksnow").fetch
    tweets = filter_for_uk_snow( uk_snow_tweets )
    p tweets
    Backend::store(tweets)
  end
end
puts "Finished."