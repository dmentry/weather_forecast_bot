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
      # переводим с серверного в локальное время
      hour = Time.now.hour + 3

      hour -= 24 if hour > 23

      case hour

      when 0..8
        forecast_now = <<~FORECAST1
        #{ @city_name }
        Прогноз погоды на сегодня:
        Утром:   #{ temperature_human(forecast_raw_data_today[:temp][:morn].round) }°C
        Днем:    #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C
        Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C
        Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C
FORECAST1
      when 9..13
        forecast_now = <<~FORECAST1
        #{ @city_name }
        Прогноз погоды на сегодня:
        Днем:    #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C
        Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C
        Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C
FORECAST1
      when 14..17
        forecast_now = <<~FORECAST1
        #{ @city_name }
        Прогноз погоды на сегодня:
        Вечером: #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C
        Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C
FORECAST1
      when 18..23
        forecast_now = <<~FORECAST1
        #{ @city_name }
        Прогноз погоды на сегодня:
        Ночью:   #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C
FORECAST1
      end

      forecast_now_2 = <<~FORECAST2
      Ветер:   #{ forecast_raw_data_today[:wind_speed] } м/с
      В течение дня: #{ forecast_raw_data_today[:weather][0][:description] }, вероятность осадков: #{ (forecast_raw_data_today[:pop]*100).to_i }%
FORECAST2

      forecast_tomorrow = <<~FORECAST3

      Прогноз погоды на #{ Time.at(forecast_raw_data_tomorrow[:dt]).strftime("%d.%m.%Y") }:
      Утром:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:morn].round) }°C
      Днем:    #{ temperature_human(forecast_raw_data_tomorrow[:temp][:day].round) }°C
      Вечером: #{ temperature_human(forecast_raw_data_tomorrow[:temp][:eve].round) }°C
      Ночью:   #{ temperature_human(forecast_raw_data_tomorrow[:temp][:night].round) }°C
      Ветер:   #{ forecast_raw_data_tomorrow[:wind_speed] } м/с
      В течение дня: #{ forecast_raw_data_tomorrow[:weather][0][:description] }, вероятность осадков: #{ (forecast_raw_data_tomorrow[:pop]*100).to_i }%
FORECAST3

      "#{ forecast_now + forecast_now_2 + forecast_tomorrow }"
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
