require 'dotenv/load'
require 'net/http'
require 'json'

class ForecastOpenweathermap
  def initialize(token, coordinates)
    @token ||= token

    @coordinates = coordinates
  end

  def daily_temp
    # температура на сутки вперед
    weather_json[:daily][0]
  end

  private

  def weather_json
    uri = URI.parse("https://api.openweathermap.org/data/2.5/onecall?lat=#{@coordinates[0]}&lon=#{@coordinates[1]}&units=metric&exclude=hourly,current,minutely,alerts&lang=ru&appid=#{@token}")

    response = Net::HTTP.get_response(uri)

    JSON.parse(response.body, symbolize_names: true)
  end
end
