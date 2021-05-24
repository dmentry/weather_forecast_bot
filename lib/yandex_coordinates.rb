class YandexCoordinates
  def initialize(yandex_api)
    @yandex_api ||= yandex_api
  end

  def city_info(city_name)
    city_json = city_data(city_name)
    #смотрим, определился ли город
    if city_json[:response][:GeoObjectCollection][:metaDataProperty][:GeocoderResponseMetaData][:found].to_i != 0
      #достаем координаты и меняем их местами
      city_coordinates = city_json[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:Point][:pos]
        .split(/ /)
          .map(&:to_f)
            .reverse!
      #достаем полное название населенного пункта
      full_city_name = "#{ city_json[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:name] }, #{ city_json[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:description] }."

      return [full_city_name, city_coordinates]
    else
      ['City not found']
    end
  end

  private

  def city_data(city_name)
    uri = URI.parse("https://geocode-maps.yandex.ru/1.x/?apikey=#{@yandex_api}&format=json&geocode=#{URI.encode(city_name)}&results=3")

    response = Net::HTTP.get_response(uri)

    JSON.parse(response.body, symbolize_names: true)
  end
end
