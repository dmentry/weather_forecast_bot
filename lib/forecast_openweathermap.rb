class ForecastOpenweathermap
  def initialize(token, coordinates, city_name)
    @token ||= token

    @coordinates = coordinates

    @city_name = city_name
  end

  def daily_temp
    # температура на остаток текущего дня и следующие сутки
      forecast_raw_data_today = weather_json[:daily][0]

      precipitations_today = if forecast_raw_data_today[:rain]
                               forecast_raw_data_today[:rain]
                             else
                               forecast_raw_data_today[:snow]
                             end
      precipitations_today = ' (выпадет ' + precipitations_today.to_s  + 'мм).' if precipitations_today

      wind_gust_today = forecast_raw_data_today[:wind_gust].round if forecast_raw_data_today[:wind_gust]
      wind_gust_today = ', порывы до ' + wind_gust_today.to_s + 'м/с.' if wind_gust_today

      forecast_raw_data_tomorrow = weather_json[:daily][1]

      precipitations_tomorrow = if forecast_raw_data_tomorrow[:rain]
                                  forecast_raw_data_tomorrow[:rain]
                                else
                                  forecast_raw_data_tomorrow[:snow]
                                end
      precipitations_tomorrow = ' (выпадет ' + precipitations_tomorrow.to_s  + 'мм).' if precipitations_tomorrow

      wind_gust_tomorrow = forecast_raw_data_tomorrow[:wind_gust].round if forecast_raw_data_tomorrow[:wind_gust]
      wind_gust_tomorrow = ', порывы до ' + wind_gust_tomorrow.to_s + 'м/с.' if wind_gust_tomorrow

      # переводим с серверного в локальное время
      # hour = Time.now.hour + 3
      # hour -= 24 if hour > 23

      hour = Time.now.hour

      case hour

      when 0..8
        forecast_now = <<~FORECAST1
        #{ @city_name }.
        Погодные данные на сегодня:
        Восход:          #{ time_normalize(forecast_raw_data_today[:sunrise]) }. Закат: #{ time_normalize(forecast_raw_data_today[:sunset]) }.
        Влажность:   #{ forecast_raw_data_today[:humidity] }%.
        Облачность: #{ forecast_raw_data_today[:clouds] }%.
        Утром:            #{ temperature_human(forecast_raw_data_today[:temp][:morn].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:morn].round) }°C).
        Днем:             #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:day].round) }°C).
        Вечером:      #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:eve].round) }°C).
        Ночью:          #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:night].round) }°C).
FORECAST1
      when 9..13
        forecast_now = <<~FORECAST1
        #{ @city_name }.
        Погодные данные на сегодня:
        Восход:          #{ time_normalize(forecast_raw_data_today[:sunrise]) }. Закат: #{ time_normalize(forecast_raw_data_today[:sunset]) }.
        Влажность:   #{ forecast_raw_data_today[:humidity] }%.
        Облачность: #{ forecast_raw_data_today[:clouds] }%.
        Днем:             #{ temperature_human(forecast_raw_data_today[:temp][:day].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:day].round) }°C).
        Вечером:      #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:eve].round) }°C).
        Ночью:          #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:night].round) }°C).
FORECAST1
      when 14..17
        forecast_now = <<~FORECAST1
        #{ @city_name }.
        Погодные данные на сегодня:
        Восход:          #{ time_normalize(forecast_raw_data_today[:sunrise]) }. Закат: #{ time_normalize(forecast_raw_data_today[:sunset]) }.
        Влажность:   #{ forecast_raw_data_today[:humidity] }%.
        Облачность: #{ forecast_raw_data_today[:clouds] }%.
        Вечером:      #{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:eve].round) }°C).
        Ночью:          #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:night].round) }°C).
FORECAST1
      when 18..23
        forecast_now = <<~FORECAST1
        #{ @city_name }.
        Погодные данные на сегодня:
        Восход:          #{ time_normalize(forecast_raw_data_today[:sunrise]) }. Закат: #{ time_normalize(forecast_raw_data_today[:sunset]) }.
        Влажность:   #{ forecast_raw_data_today[:humidity] }%.
        Облачность: #{ forecast_raw_data_today[:clouds] }%.
        Ночью:            #{ temperature_human(forecast_raw_data_today[:temp][:night].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_today[:feels_like][:night].round) }°C).
FORECAST1
      end

      forecast_now_2 = <<~FORECAST2
      Ветер:             #{ forecast_raw_data_today[:wind_speed].round } м/с#{ wind_gust_today }
      В течение дня: #{ forecast_raw_data_today[:weather][0][:description] },\nвероятность осадков: #{ (forecast_raw_data_today[:pop]*100).to_i }% #{ precipitations_today }
FORECAST2

      forecast_tomorrow = <<~FORECAST3

      Погодные данные на завтра, #{ Time.at(forecast_raw_data_tomorrow[:dt]).strftime("%d.%m.%Y") }:
      Восход:          #{ time_normalize(forecast_raw_data_tomorrow[:sunrise]) }. Закат: #{ time_normalize(forecast_raw_data_tomorrow[:sunset]) }.
      Влажность:   #{ forecast_raw_data_tomorrow[:humidity] }%.
      Облачность: #{ forecast_raw_data_today[:clouds] }%.
      Утром:            #{ temperature_human(forecast_raw_data_tomorrow[:temp][:morn].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:morn].round) }°C).
      Днем:              #{ temperature_human(forecast_raw_data_tomorrow[:temp][:day].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:day].round) }°C).
      Вечером:       #{ temperature_human(forecast_raw_data_tomorrow[:temp][:eve].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:eve].round) }°C).
      Ночью:           #{ temperature_human(forecast_raw_data_tomorrow[:temp][:night].round) }°C (ощущается, как #{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:night].round) }°C).
      Ветер:             #{ forecast_raw_data_tomorrow[:wind_speed].round } м/с#{ wind_gust_tomorrow }
      В течение дня: #{ forecast_raw_data_tomorrow[:weather][0][:description] },\nвероятность осадков: #{ (forecast_raw_data_tomorrow[:pop]*100).to_i }% #{ precipitations_tomorrow }
FORECAST3

      "#{ forecast_now + forecast_now_2 + forecast_tomorrow }"
  end

  private

  def weather_json
    uri = URI.parse("https://api.openweathermap.org/data/2.5/onecall?lat=#{ @coordinates[0] }&lon=#{ @coordinates[1] }&units=metric&exclude=hourly,current,minutely,alerts&lang=ru&appid=#{ @token }")

    response = Net::HTTP.get_response(uri)

    JSON.parse(response.body, symbolize_names: true)
  end

  def temperature_human(ambient_temp)
    if ambient_temp > 0
      return "+#{ ambient_temp }"
    else
      return ambient_temp
    end
  end

  def time_normalize(time)
    DateTime.strptime((time + 3*60*60).to_s,'%s').strftime("%H:%M")
  end
end
