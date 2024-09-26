class WeatherForecast
  def initialize(token)
    @weather_token ||= token
  end

  def call(city_name: nil, city_coordinates: nil)
    @city_name = city_name

    # # Убрать все точки в конце, если они есть
    @city_name = @city_name.gsub(/\.{1,}\z/, '') if @city_name.match?(/\.{1,}\z/)

    forecast_raw_data = if city_coordinates
                          coords =  if city_coordinates.is_a?(Array)
                                      city_coordinates.join(',')
                                    else
                                      city_coordinates
                                    end

                          weather_json(coords)
                        else
                          city_name = CGI.escape(city_name)

                          weather_json(city_name)
                        end

    create_forecast(forecast_raw_data)
  end

  private

  def weather_json(city_data)
    uri = URI.parse("https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/weatherdata/forecast?key=#{ @weather_token }&unitGroup=metric&aggregateHours=24&includeAstronomy=true&contentType=json&locationMode=single&iconSet=icons1&locations=#{ city_data }")

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

  def wind_direction(degrees)
    if (338..360).include?(degrees) || (0..23).include?(degrees)
      "&#11015;" + ' С'
    elsif (24..68).include?(degrees)
      "&#8601;" + ' СВ'
    elsif (69..113).include?(degrees)
      "&#11013;" + ' В'
    elsif (114..158).include?(degrees)
      "&#8598;" + ' ЮВ'
    elsif (159..203).include?(degrees)
      "&#11014;" + ' Ю'
    elsif (204..248).include?(degrees)
      "&#8599;" + ' ЮЗ'
    elsif (249..293).include?(degrees)
      "&#10145;" + ' З'
    elsif (294..337).include?(degrees)
      "&#8600;" + ' СЗ'
    end
  end

  def create_forecast(forecast_raw_data)
    out = []

    forecast_raw_data = forecast_raw_data[:location][:values]

    # Форматируем, по сколько дней показывать в одном сообщении. Сейчас по два
    forecast_raw_data.each_slice(2).with_index do |day_forecast, i|
      first_message = true if i == 0

      out << (create_daily_forecast(forecast: day_forecast[0], first_message: first_message) + create_daily_forecast(forecast: day_forecast[1]))
    end

    out
  end

  def create_daily_forecast(forecast:, first_message: nil)
    celsius = "\xE2\x84\x83"

    precipitations = if forecast[:precip].to_f != 0.0
                       " (<b>#{ forecast[:precip]&.to_f }мм</b>)"
                     else
                      ''
                     end

    wind_gust = if forecast[:wgust] && forecast[:wgust].to_f != 0.0   
                  ", порывы до <b>#{ forecast[:wgust].round }м/с</b>"
                else
                  ''
                end

    wind_direction = wind_direction(forecast[:wdir])

    forecast_date = Time.parse(forecast[:datetimeStr]).to_date
    forecast_day_name_rus = if forecast_date == Date.today
                              'Сегодня'
                            elsif forecast_date == Date.today + 1
                              'Завтра'
                            elsif forecast_date == Date.today + 2
                              'Послезавтра'
                            end
    week_day_name_rus = week_days_rus(Time.parse(forecast[:datetimeStr]).wday)
    week_day_name_rus = ' ' + week_day_name_rus.downcase if forecast_day_name_rus

    header         = "#{ forecast_day_name_rus }#{ week_day_name_rus }, #{ Time.parse(forecast[:datetimeStr]).strftime("%d.%m.%Y") }:"
    moon           = "#{ moon_phase(forecast[:moonphase]) }"
    sun            = "&#127774;                 <b>#{ Time.parse(forecast[:sunrise]).strftime("%H:%M") }</b> - <b>#{ Time.parse(forecast[:sunset]).strftime("%H:%M") }</b>"
    humidity       = "Влажность:     <b>#{ forecast[:humidity].to_i }%</b>"
    pressure       = "Давление:       <b>#{ (forecast[:sealevelpressure] * 0.75).round }мм рт. ст.</b>"
    cloudness      = "Облачность:    <b>#{ forecast[:cloudcover].to_i }%</b>"
    temperature    = "Температура: <b>#{ temperature_human(forecast[:temp].round) }</b>#{ celsius } (от <b>#{ temperature_human(forecast[:mint].round) }</b>#{ celsius } до <b>#{ temperature_human(forecast[:maxt].round) }</b>#{ celsius })"
    wind           = "Ветер:              <b>#{ forecast[:wspd].round }м/с #{ wind_direction }</b>#{ wind_gust }"
    precipitation  = "Погода:            #{ emoji(forecast[:icon]) }"
    precipitation2 = if forecast[:pop].to_f != 0.0 && forecast[:precip].to_f != 0.0
                       "Вероятность осадков: <b>#{ (forecast[:pop]).to_i }%</b> #{ precipitations }"
                     else
                       "Осадков не ожидается"
                     end

    if first_message
        forecast = <<~FORECAST
        <b>#{ @city_name }.</b>
        #{ header }
        #{ sun }
        #{ moon }
        #{ temperature }
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
        #{ sun }
        #{ moon }
        #{ temperature }
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
    when 'wind'
      "💨"          # windy
    when (300..310)
      "&#x1F326;"   # light rain (drizzle)
    when (311..399)
      "&#x2614;"    # rain (drizzle)
    when 'rain'
      "&#127783;"   # rain
    when (502..599)
      "&#127783;"   # heavy rain
    when 'snow'
      "&#127784;"   # snow
    when 'fog'
      "&#x1F301;"   # fog
    when 'clear-day'
      "\u{1F31E}"   # clear sky
    when 801
      "\u{1F324}"   # few clouds
    when 
      "\u{26C5}"    # scattered clouds
    when 'partly-cloudy-day'
      "\u{1F325}"   # broken clouds
    when 'cloudy'
      "\u{2601}"    # overcast clouds
    end
  end

  def moon_phase(moon_code)
    case moon_code
    when (0..0.10), (0.95..0.99)
      "&#127761;"    # новолуние
    when (0.11..0.21)
      "&#127762;"    # молодая луна
    when (0.22..0.33)
      "&#127763;"    # первая четверть
    when (0.34..0.48)
      "&#127764;"    # прибывающая луна
    when (0.49..0.55)
      "&#127765;"    # полнолуние
    when (0.56..0.63)
      "&#127766;"    # убывающая луна
    when (0.64..0.77)
      "&#127767;"    # последняя четверть
    when (0.78..0.94)
      "&#127768;"    # старая луна
    end
  end

  def week_days_rus(week_day_nr)
    week_days_rus = { 1 => 'Понедельник', 2 => 'Вторник', 3 => 'Среда', 4 => 'Четверг', 5 => 'Пятница', 6 => 'Суббота', 0 => 'Воскресенье' }
    week_days_rus[week_day_nr]
  end
end
