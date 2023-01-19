class ForecastOpenweathermap
  def initialize(token)
    @openweathermap_token ||= token
  end

  def call(coordinates, city_name)
    @city_name = city_name
    # Убрать все точки в конце, если они есть, сделать первую букву заглавной и стиль шрифта - жирный
    @city_name    = @city_name.gsub(/\.{1,}\z/, '') if @city_name.match?(/\.{1,}\z/)
    @city_name    = @city_name.dup
    @city_name[0] = @city_name[0].capitalize
    @city_name    = '<b>' + @city_name + '</b>'

    forecast_raw_data = weather_json(coordinates)[:daily]

    create_forecast(forecast_raw_data)
  end

  private

  def weather_json(coordinates)
    uri = URI.parse("https://api.openweathermap.org/data/2.5/onecall?lat=#{ coordinates[0] }&lon=#{ coordinates[1] }&units=metric&exclude=hourly,current,minutely,alerts&lang=ru&appid=#{ @openweathermap_token }")

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

  def create_forecast(forecast_raw_data)
    # прогноз на остаток текущего дня и следующие дни
    today_forecast = create_dayly_forecast(forecast_raw_data[0])

    tomorrow_forecast = create_dayly_forecast(forecast_raw_data[1])

    after_tomorrow_forecast = create_dayly_forecast(forecast_raw_data[2])

    "#{ today_forecast + tomorrow_forecast + after_tomorrow_forecast }"  
  end

  def create_dayly_forecast(forecast)
    celsius = "\xE2\x84\x83"

    precipitations = if forecast[:rain]
                       forecast[:rain]
                     else
                       forecast[:snow]
                     end
    precipitations = ' (выпадет <b>' + precipitations.to_s  + 'мм</b>).' if precipitations

    wind_gust = forecast[:wind_gust].round if forecast[:wind_gust]
    wind_gust = ', порывы до <b>' + wind_gust.to_s + 'м/с</b>' if wind_gust

    wind_direction = wind_direction(forecast[:wind_deg])

    forecast_date = Time.at(forecast[:dt]).to_date
    forecast_day_name_rus = if forecast_date == Date.today
                              'сегодня'
                            elsif forecast_date == Date.today + 1
                              'завтра'
                            else
                              'послезавтра'
                            end

    header        = "Погодные данные на #{ forecast_day_name_rus }, <b>#{ Time.at(forecast[:dt]).strftime("%d.%m.%Y") }</b>:"
    sun           = "Восход:          <b>#{ time_normalize(forecast[:sunrise]) }</b>.                    Закат: <b>#{ time_normalize(forecast[:sunset]) }</b>"
    humidity      = "Влажность:   <b>#{ forecast[:humidity] }%</b>"
    cloudness     = "Облачность: <b>#{ forecast[:clouds] }%</b>"
    morning       = "Утром:            <b>#{ temperature_human(forecast[:temp][:morn].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:morn].round) }</b>#{ celsius }"
    day           = "Днем:             <b>#{ temperature_human(forecast[:temp][:day].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:day].round) }</b>#{ celsius }"
    evening       = "Вечером:       <b>#{ temperature_human(forecast[:temp][:eve].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:eve].round) }</b>#{ celsius }"
    night         = "Ночью:           <b>#{ temperature_human(forecast[:temp][:night].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:night].round) }</b>#{ celsius }"
    wind          = "Ветер:             #{ wind_direction }<b>#{ forecast[:wind_speed].round } м/с</b>#{ wind_gust }"
    precipitation = "В течение дня: #{ forecast[:weather][0][:description] },\nвероятность осадков: <b>#{ (forecast[:pop]*100).to_i }%</b> #{ precipitations }"

    if forecast_day_name_rus == 'сегодня'
      case Time.now.hour
      when 0..8
        forecast_temp = <<~FORECAST.strip
          #{ morning }
          #{ day }
          #{ evening }
          #{ night }
        FORECAST
      when 9..13
        forecast_temp = <<~FORECAST.strip
          #{ day }
          #{ evening }
          #{ night }
        FORECAST
      when 14..17
        forecast_temp = <<~FORECAST.strip
          #{ evening }
          #{ night }
        FORECAST
      when 18..23
        forecast_temp = <<~FORECAST.strip
          #{ night }
        FORECAST
      end

      forecast = <<~FORECAST
        #{ @city_name }.
        #{ header }
        #{ sun }
        #{ humidity }
        #{ cloudness }
        #{ forecast_temp }
        #{ wind }
        #{ precipitation }
      FORECAST
    else
      forecast = <<~FORECAST

        #{ header }
        #{ sun }
        #{ humidity }
        #{ cloudness }
        #{ morning }
        #{ day }
        #{ evening }
        #{ night }
        #{ wind }
        #{ precipitation }
      FORECAST
    end
  end
end
