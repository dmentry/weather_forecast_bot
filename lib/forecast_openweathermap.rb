class ForecastOpenweathermap
  def initialize(token, coordinates, city_name)
    @token ||= token

    @coordinates = coordinates

    @city_name = city_name

    @celsius = "\xE2\x84\x83"
  end

  def daily_temp
    # температура на остаток текущего дня и следующие сутки
    forecast_raw_data_today = weather_json[:daily][0]

    precipitations_today = if forecast_raw_data_today[:rain]
                             forecast_raw_data_today[:rain]
                           else
                             forecast_raw_data_today[:snow]
                           end
    precipitations_today = ' (выпадет <b>' + precipitations_today.to_s  + 'мм</b>).' if precipitations_today

    wind_gust_today = forecast_raw_data_today[:wind_gust].round if forecast_raw_data_today[:wind_gust]
    wind_gust_today = ', порывы до <b>' + wind_gust_today.to_s + 'м/с</b>' if wind_gust_today

    wind_direction_today = wind_direction(forecast_raw_data_today[:wind_deg])

    forecast_raw_data_tomorrow = weather_json[:daily][1]

    precipitations_tomorrow = if forecast_raw_data_tomorrow[:rain]
                                forecast_raw_data_tomorrow[:rain]
                              else
                                forecast_raw_data_tomorrow[:snow]
                              end
    precipitations_tomorrow = ' (выпадет <b>' + precipitations_tomorrow.to_s  + 'мм</b>).' if precipitations_tomorrow

    wind_gust_tomorrow = forecast_raw_data_tomorrow[:wind_gust].round if forecast_raw_data_tomorrow[:wind_gust]
    wind_gust_tomorrow = ', порывы до <b>' + wind_gust_tomorrow.to_s + 'м/с</b>' if wind_gust_tomorrow

    wind_direction_tomorrow = wind_direction(forecast_raw_data_tomorrow[:wind_deg])

    hour = Time.now.hour

    # Убрать все точки в конце, если они есть, сделать первую букву заглавной и стиль шрифта - жирный
    @city_name = @city_name.gsub(/\.{1,}\z/, '') if @city_name.match?(/\.{1,}\z/)
    @city_name = @city_name.dup
    @city_name[0] = @city_name[0].capitalize
    @city_name = '<b>' + @city_name + '</b>'

    header    = "Погодные данные на сегодня, <b>#{ Time.at(forecast_raw_data_today[:dt]).strftime("%d.%m.%Y") }</b>:"
    sun       = "Восход:          <b>#{ time_normalize(forecast_raw_data_today[:sunrise]) }</b>.                    Закат: <b>#{ time_normalize(forecast_raw_data_today[:sunset]) }</b>"
    humidity  = "Влажность:   <b>#{ forecast_raw_data_today[:humidity] }%</b>"
    cloudness = "Облачность: <b>#{ forecast_raw_data_today[:clouds] }%</b>"
    morning   = "Утром:            <b>#{ temperature_human(forecast_raw_data_today[:temp][:morn].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_today[:feels_like][:morn].round) }</b>#{ @celsius }"
    day       = "Днем:             <b>#{ temperature_human(forecast_raw_data_today[:temp][:day].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_today[:feels_like][:day].round) }</b>#{ @celsius }"
    evening   = "Вечером:       <b>#{ temperature_human(forecast_raw_data_today[:temp][:eve].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_today[:feels_like][:eve].round) }</b>#{ @celsius }"
    night     = "Ночью:           <b>#{ temperature_human(forecast_raw_data_today[:temp][:night].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_today[:feels_like][:night].round) }</b>#{ @celsius }"

    case hour
    when 0..8
      forecast_now = <<~FORECAST1
      #{ @city_name }.
      #{ header }
      #{ sun }
      #{ humidity }
      #{ cloudness }
      #{ morning }
      #{ day }
      #{ evening }
      #{ night }
FORECAST1
    when 9..13
      forecast_now = <<~FORECAST1
      #{ @city_name }.
      #{ header }
      #{ sun }
      #{ humidity }
      #{ cloudness }
      #{ day }
      #{ evening }
      #{ night }
FORECAST1
    when 14..17
      forecast_now = <<~FORECAST1
      #{ @city_name }.
      #{ header }
      #{ sun }
      #{ humidity }
      #{ cloudness }
      #{ evening }
      #{ night }
FORECAST1
    when 18..23
      forecast_now = <<~FORECAST1
      #{ @city_name }.
      #{ header }
      #{ sun }
      #{ humidity }
      #{ cloudness }
      #{ night }
FORECAST1
    end

    forecast_now_2 = <<~FORECAST2
    Ветер:             #{ wind_direction_today }<b>#{ forecast_raw_data_today[:wind_speed].round } м/с</b>#{ wind_gust_today }
    В течение дня: #{ forecast_raw_data_today[:weather][0][:description] },\nвероятность осадков: <b>#{ (forecast_raw_data_today[:pop]*100).to_i }%</b> #{ precipitations_today }
FORECAST2

    forecast_tomorrow = <<~FORECAST3

    Погодные данные на завтра, <b>#{ Time.at(forecast_raw_data_tomorrow[:dt]).strftime("%d.%m.%Y") }</b>:
    Восход:          <b>#{ time_normalize(forecast_raw_data_tomorrow[:sunrise]) }</b>.                  Закат: <b>#{ time_normalize(forecast_raw_data_tomorrow[:sunset]) }</b>
    Влажность:   <b>#{ forecast_raw_data_tomorrow[:humidity] }%</b>
    Облачность: <b>#{ forecast_raw_data_today[:clouds] }%</b>
    Утром:            <b>#{ temperature_human(forecast_raw_data_tomorrow[:temp][:morn].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:morn].round) }</b>#{ @celsius }
    Днем:             <b>#{ temperature_human(forecast_raw_data_tomorrow[:temp][:day].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:day].round) }</b>#{ @celsius }
    Вечером:       <b>#{ temperature_human(forecast_raw_data_tomorrow[:temp][:eve].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:eve].round) }</b>#{ @celsius }
    Ночью:           <b>#{ temperature_human(forecast_raw_data_tomorrow[:temp][:night].round) }</b>#{ @celsius }, ощущается, как <b>#{ temperature_human(forecast_raw_data_tomorrow[:feels_like][:night].round) }</b>#{ @celsius }
    Ветер:             #{ wind_direction_tomorrow }<b>#{ forecast_raw_data_tomorrow[:wind_speed].round }м/с</b>#{ wind_gust_tomorrow }
    В течение дня: #{ forecast_raw_data_tomorrow[:weather][0][:description] },\nвероятность осадков: <b>#{ (forecast_raw_data_tomorrow[:pop]*100).to_i }%</b> #{ precipitations_tomorrow }
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
    DateTime.strptime((time + 3 * 60 * 60).to_s,'%s').strftime("%H:%M")
  end

  def wind_direction(degrees)
    if (338..360).include?(degrees) || (0..23).include?(degrees)
      # " северный, "
      "\xE2\xAC\x86" + ', '
    elsif (24..68).include?(degrees)
      # " северо-восточный, "
      "\xE2\x86\x97" + ', '
    elsif (69..113).include?(degrees)
      # " восточный, "
      "\xE2\x9E\xA1" + ', '
    elsif (114..158).include?(degrees)
      # " юго-восточный, "
      "\xE2\x86\x98" + ', '
    elsif (159..203).include?(degrees)
      # " южный, "
      "\xE2\xAC\x87" + ', '
    elsif (204..248).include?(degrees)
      # " юго-западный, "
      "\xE2\x86\x99"
    elsif (249..293).include?(degrees)
      # " западный, "
      "\xE2\xAC\x85" + ', '
    elsif (294..337).include?(degrees)
      # " северо-западный, "
      "\xE2\x86\x96" + ', '
    end
  end
end
