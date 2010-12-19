require 'dm-core'
require 'dm-aggregates'
require 'dm-migrations'
require 'dm-serializer'

class SnowTweet
  include DataMapper::Resource
  property :id,         Serial
  property :score,      Integer    
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