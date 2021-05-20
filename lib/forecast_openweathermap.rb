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
    # температура на остаток текущего дня и следующие сутки
      forecast_raw_data_today = weather_json[:daily][0]

      forecast_raw_data_tomorrow = weather_json[:daily][1]

      hour = Time.now.hour

      case hour

      when 0..8
        temp_morning = "Утром:   #{ temperature_human(forecast_raw_data_today[:temp][:morn].round) }°C"
        temp_day = "Днем:    #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C"
        temp_evening = "Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C"
        temp_night = "Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C"
      when 9..13
        temp_day = "Днем:    #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C"
        temp_evening = "Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C"
        temp_night = "Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C"
      when 14..17
        temp_evening = "Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C"
        temp_night = "Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C"
      when 18..24
        temp_night = "Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C"
      end

      forecast_now = <<~FORECAST1
      #{ @city_name }:
      Прогноз погоды на сегодня:
      #{ temp_morning }
      #{ temp_day }
      #{ temp_evening }
      #{ temp_night }
      Ветер:   7 м/с
      Вероятность осадков: #{ 0.6*100.to_i }%
FORECAST1

      forecast_tomorrow = <<~FORECAST2

      Прогноз погоды на 22.05.2022:
      Утром:   Утром:   5°C
      Днем:    Днем:    10°C
      Вечером: Вечером: 8°C
      Ночью:   Ночью:   3°C
      Ветер:   5 м/с
      Вероятность осадков: #{ 0.55*100.to_i }%
FORECAST2

      "#{ forecast_now.gsub(/^$\n/, '') + forecast_tomorrow }"

    # <<-FORECAST
    #   #{ @city_name }:
    #   Прогноз погоды на сегодня:
    #   #{ temp_morning }
    #   #{ temp_day }
    #   #{ temp_evening }
    #   #{ temp_night }
    #   Ветер:   #{ forecast_raw_data_today[:wind_speed] } м/с
    #   #{ forecast_raw_data_today[:weather][0][:description].capitalize }
    #   Вероятность осадков: #{ (forecast_raw_data_today[:pop]*100).to_i }%

    #   Прогноз погоды на #{ Time.at(forecast_raw_data_tomorrow[:dt]).strftime("%d.%m.%Y") }:
    #   Утром:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:morn].round) }°C
    #   Днем:    #{ temperature_human(forecast_raw_data_tomorrow[:temp][:day].round) }°C
    #   Вечером: #{ temperature_human(forecast_raw_data_tomorrow[:temp][:eve].round) }°C
    #   Ночью:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:night].round) }°C
    #   Ветер:   #{ forecast_raw_data_tomorrow[:wind_speed] } м/с
    #   #{ forecast_raw_data_tomorrow[:weather][0][:description].capitalize }
    #   Вероятность осадков: #{ (forecast_raw_data_tomorrow[:pop]*100).to_i }%
    # FORECAST

    # <<-FORECAST
    #   #{ @city_name }:
    #   Прогноз погоды на сегодня:
    #   Утром:   #{ temperature_human(forecast_raw_data_today[:temp][:morn].round) }°C
    #   Днем:    #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C
    #   Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C
    #   Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C
    #   Ветер:   #{ forecast_raw_data_today[:wind_speed] } м/с
    #   #{ forecast_raw_data_today[:weather][0][:description].capitalize }
    #   Вероятность осадков: #{ (forecast_raw_data_today[:pop]*100).to_i }%

    #   Прогноз погоды на #{ Time.at(forecast_raw_data_tomorrow[:dt]).strftime("%d.%m.%Y") }:
    #   Утром:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:morn].round) }°C
    #   Днем:    #{ temperature_human(forecast_raw_data_tomorrow[:temp][:day].round) }°C
    #   Вечером: #{ temperature_human(forecast_raw_data_tomorrow[:temp][:eve].round) }°C
    #   Ночью:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:night].round) }°C
    #   Ветер:   #{ forecast_raw_data_tomorrow[:wind_speed] } м/с
    #   #{ forecast_raw_data_tomorrow[:weather][0][:description].capitalize }
    #   Вероятность осадков: #{ (forecast_raw_data_tomorrow[:pop]*100).to_i }%
    # FORECAST
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
