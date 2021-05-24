require 'dotenv/load'
require 'net/http'
require 'json'

class YandexCoordinates

  attr_accessor :jsn

  def initialize(yandex_api, city_name)
    @yandex_api ||= yandex_api

    @city_name = city_name

      uri = URI.parse("https://geocode-maps.yandex.ru/1.x/?apikey=ab33258f-6d87-46fb-a6ff-1abfee8edeb5&format=json&geocode=#{URI.encode(@city_name)}&results=3")

  response = Net::HTTP.get_response(uri)

  @jsn = JSON.parse(response.body, symbolize_names: true)
  end



  def results_number
    @jsn[:response][:GeoObjectCollection][:metaDataProperty][:GeocoderResponseMetaData][:found].to_i
  end

  def coordinates_name(number)
    #достаем координаты и меняем их местами
    coordinates = @jsn[:response][:GeoObjectCollection][:featureMember][number][:GeoObject][:Point][:pos]
      .split(/ /)
        .map(&:to_f)
          .reverse!

    city_name = "#{ @jsn[:response][:GeoObjectCollection][:featureMember][number][:GeoObject][:name] }, #{ jsn[:response][:GeoObjectCollection][:featureMember][number][:GeoObject][:description] }"

    {coordinates: coordinates, city_name: city_name}
  end
end