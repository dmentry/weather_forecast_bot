require 'dotenv/load'
require 'net/http'
require 'json'

class ForecastOpenweathermap
  def initialize(token, coordinates, city_name)
    @token ||= token

    @coordinates = coordinates

    @city_name = city_name
  end

  def daily_temp
    # температура на следующие сутки
    forecast_raw_data = weather_json[:daily][1]

    <<FORECAST
      #{ @city_name } - прогноз погоды на #{ Time.at(forecast_raw_data[:dt]).strftime("%d.%m.%Y") }:
      Утром:   #{ temperature_human(forecast_raw_data[:temp][:morn].round) }°C
      Днем:    #{ temperature_human(forecast_raw_data[:temp][:day].round) }°C
      Вечером: #{ temperature_human(forecast_raw_data[:temp][:eve].round) }°C
      Ночью:   #{ temperature_human(forecast_raw_data[:temp][:night].round) }°C
      Ветер:   #{ forecast_raw_data[:wind_speed] } м/с
      #{ forecast_raw_data[:weather][0][:description].capitalize }
      Вероятность осадков: #{ (forecast_raw_data[:pop]*100).to_i }%
    FORECAST
  end

  private

  def weather_json
    uri = URI.parse("https://api.openweathermap.org/data/2.5/onecall?lat=#{@coordinates[0]}&lon=#{@coordinates[1]}&units=metric&exclude=hourly,current,minutely,alerts&lang=ru&appid=#{@token}")

    response = Net::HTTP.get_response(uri)

    JSON.parse(response.body, symbolize_names: true)
  end

  def temperature_human(ambient_temp)
    if ambient_temp > 0
      return "+#{ambient_temp}"
    else
      return ambient_temp
    end
  end
end
