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
    out = []

    # Форматируем, по сколько дней показывать в одном сообщении. Сейчас по два
    forecast_raw_data.each_slice(2) do |day_forecast|
      out << (create_daily_forecast(day_forecast[0]) + create_daily_forecast(day_forecast[1]))
    end

    out
  end

  def create_daily_forecast(forecast)
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
                              'сегодня,'
                            elsif forecast_date == Date.today + 1
                              'завтра,'
                            elsif forecast_date == Date.today + 2
                              'послезавтра,'
                            end

    header         = "Погодные данные на #{ forecast_day_name_rus } <b>#{ Time.at(forecast[:dt]).strftime("%d.%m.%Y") }</b>:"
    # moon           = "Фаза луны: #{ moon_phase(forecast[:moon_phase]) }"
    moon           = "#{ moon_phase(forecast[:moon_phase]) }                     <b>#{ time_normalize(forecast[:moonrise]) }</b> - <b>#{ time_normalize(forecast[:moonset]) }</b>"
    # sun            = "Восход:          <b>#{ time_normalize(forecast[:sunrise]) }</b>.                    Закат: <b>#{ time_normalize(forecast[:sunset]) }</b>"
    sun            = "&#127774;                     <b>#{ time_normalize(forecast[:sunrise]) } - #{ time_normalize(forecast[:sunset]) }</b>"
    humidity       = "Влажность:   <b>#{ forecast[:humidity] }%</b>"
    pressure       = "Давление:     <b>#{ (forecast[:pressure] * 0.75).round } мм рт. ст.</b>"
    cloudness      = "Облачность: <b>#{ forecast[:clouds] }%</b>"
    morning        = "Утром:            <b>#{ temperature_human(forecast[:temp][:morn].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:morn].round) }</b>#{ celsius }"
    day            = "Днем:             <b>#{ temperature_human(forecast[:temp][:day].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:day].round) }</b>#{ celsius }"
    evening        = "Вечером:       <b>#{ temperature_human(forecast[:temp][:eve].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:eve].round) }</b>#{ celsius }"
    night          = "Ночью:           <b>#{ temperature_human(forecast[:temp][:night].round) }</b>#{ celsius }, ощущается, как <b>#{ temperature_human(forecast[:feels_like][:night].round) }</b>#{ celsius }"
    wind           = "Ветер:             #{ wind_direction }<b>#{ forecast[:wind_speed].round } м/с</b>#{ wind_gust }"
    # precipitation  = "В течение дня: #{ emoji(forecast[:weather][0][:id]) } #{ forecast[:weather][0][:description] }"
    precipitation  = "Днем:             #{ emoji(forecast[:weather][0][:id]) }"
    precipitation2 = if forecast[:pop].to_f != 0.0
                       "Вероятность осадков: <b>#{ (forecast[:pop]*100).to_i }%</b> #{ precipitations }"
                     else
                       "Осадков не ожидается"
                     end

    if forecast_date == Date.today
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
        #{ moon }
        #{ sun }
        #{ forecast_temp }
        #{ pressure }
        #{ humidity }
        #{ wind }
        #{ precipitation }
        #{ cloudness }
        #{ precipitation2 }
      FORECAST
    else
      forecast = <<~FORECAST

        #{ header }
        #{ moon }
        #{ sun }
        #{ morning }
        #{ day }
        #{ evening }
        #{ night }
        #{ pressure }
        #{ humidity }
        #{ wind }
        #{ precipitation }
        #{ cloudness }
        #{ precipitation2 }
      FORECAST
    end
  end

  def emoji(weather_code)
    case weather_code
    when (200..209), (230..209)
      "&#x26C8;"    # thunderstorm with rain
    when (210..221)
      "&#x1F329;"   # thunderstorm
    when (300..310)
      "&#x1F326;"   # light rain (drizzle)
    when (311..399)
      "&#x2614;"    # rain (drizzle)
    when (500..501)
      "&#127783;"   # rain
    when (502..599)
      "&#127783;"   # heavy rain
    when (600..699)
      "&#127784;"   # snow
    when 701, 741
      "&#x1F301;"   # fog
    when 800
      "\u{1F31E}"   # clear sky
    when 801
      "\u{1F324}"   # few clouds
    when 802
      "\u{26C5}"    # scattered clouds
    when 803
      "\u{1F325}"   # broken clouds
    when 804
      "\u{2601}"    # overcast clouds
    end
  end

  def moon_phase(moon_code)
    case moon_code
    when (0..0.12)
      "&#127761;"    # новолуние
    when (0.13..0.20)
      "&#127762;"    # молодая
    when (0.21..0.34)
      "&#127763;"    # первая четверть
    when (0.35..0.47)
      "&#127764;"    # прибывающая
    when (0.48..0.5)
      "&#127765;"    # полнолуние
    when (0.51..0.63)
      "&#127766;"    # убывающая
    when (0.64..0.77)
      "&#127767;"    # последняя четверть
    when (0.78..0.94)
      "&#127768;"    # старая
    when (0.95..0.99)
      "&#127761;"    # новолуние
    end
  end
end
