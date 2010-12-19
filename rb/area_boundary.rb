require 'net/http'
require 'uri'

class AreaBoundary
  
  def initialize
    @geo_by_postcode_cache = {}
  end
  
  POSTAL_DISTRICT_URL = "http://mapit.mysociety.org/postcode/partial/{POSTCODE}"
  LAT_LONG_URL        = "http://mapit.mysociety.org/point/4326/{LON},{LAT}"
  BOUNDARY_KML_URL    = "http://mapit.mysociety.org/area/{ID}.kml"

  def geo_by_postcode( postcode )
    unless @geo_by_postcode_cache[postcode]
      puts "geo_by_postcode_cache #{postcode} MISS"
      @geo_by_postcode_cache[postcode] = geo_from_postcode( postcode )
    else 
      puts "geo_by_postcode_cache #{postcode} HIT"
    end
    return @geo_by_postcode_cache[postcode]
  end

  def geo_from_postcode( postcode )
    begin
      # Get lat lon of postcode
      postal_district_data = JSON.parse( 
        Net::HTTP.get(
          URI.parse(POSTAL_DISTRICT_URL.gsub('{POSTCODE}', postcode))
        )
      )
      lat = postal_district_data['wgs84_lat']
      lon = postal_district_data['wgs84_lon']
  
      # Map onto 'Lower Layer Super Output Area (Generalised)'
      area_reference = JSON.parse( 
        Net::HTTP.get(
          URI.parse( LAT_LONG_URL.gsub('{LON}', lon.to_s).gsub('{LAT}', lat.to_s) )
        ) 
      ) 
      olg_area = area_reference.find do | area |
        area[1]['type'] == 'OLG'
      end
      olg_id = olg_area[1]['id']
  
      # Get KML data for boundary
      kml_data = Net::HTTP.get(
        URI.parse( BOUNDARY_KML_URL.gsub('{ID}', olg_id.to_s) )
      ) 
      return kml_data
    rescue Exception => e
      return nil
    end
  end
end