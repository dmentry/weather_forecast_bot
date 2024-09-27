class WeatherForecast
  def initialize(token)
    @weather_token ||= token
  end

  def call(city_name: nil, city_coordinates: nil)
    @time_zone = nil
    @time_zone_shift = nil

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
    # /forecast end point
    # uri = URI.parse("https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/weatherdata/forecast?key=#{ @weather_token }&unitGroup=metric&aggregateHours=24&includeAstronomy=true&contentType=json&locationMode=single&iconSet=icons1&locations=#{ city_data }")

    # /timeline end point
    uri = URI.parse("https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline?key=#{ @weather_token }&lang=ru&iconSet=icons2&unitGroup=metric&include=days&elements=datetime,tempmax,tempmin,temp,feelslike,humidity,precip,precipprob,preciptype,snow,windgust,windspeed,winddir,pressure,cloudcover,sunrise,sunset,moonphase,conditions,description,icon&location=#{ city_data }")

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

    @time_zone = forecast_raw_data[:timezone]
    @time_zone_shift = forecast_raw_data[:tzoffset]

    forecast_raw_data = forecast_raw_data[:days]

    # Форматируем, по сколько дней показывать в одном сообщении. Сейчас по два
    forecast_raw_data.each_slice(2).with_index do |day_forecast, i|
      first_message = true if i == 0

      out << (create_daily_forecast(forecast: day_forecast[0], first_message: first_message) + create_daily_forecast(forecast: day_forecast[1]))
    end

    out
  end

  def create_daily_forecast(forecast:, first_message: nil)
    return '' if !forecast

    celsius = "\xE2\x84\x83"

    precipitation_volume =  if forecast[:preciptype]
                              case forecast[:preciptype]&.first
                              when 'rain'
                                "<b>#{ forecast[:precip]&.to_f }мм</b>"
                              when 'snow'
                                "<b>#{ forecast[:snow]&.to_f }см</b>"
                              when 'freezing rain'
                                "<b>#{ forecast[:precip]&.to_f }мм</b>"
                              when 'ice'
                                "<b>#{ forecast[:precip]&.to_f }мм</b>"
                              end
                            else
                              ''
                            end

    precipitation2 = "#{ emoji(forecast[:icon]) }"

    wind_gust = if forecast[:windgust] && forecast[:windgust].to_f != 0.0   
                  ", порывы до <b>#{ forecast[:windgust].round }м/с</b>"
                else
                  ''
                end

    forecast_date = Date.parse(forecast[:datetime])
    forecast_day_name_rus = if forecast_date == Date.today
                              'Сегодня'
                            elsif forecast_date == Date.today + 1
                              'Завтра'
                            elsif forecast_date == Date.today + 2
                              'Послезавтра'
                            end
    week_day_name_rus = week_days_rus(Date.parse(forecast[:datetime]).wday)
    week_day_name_rus = ' ' + week_day_name_rus.downcase if forecast_day_name_rus

    header         = "#{ forecast_day_name_rus }#{ week_day_name_rus }, <b>#{ Date.parse(forecast[:datetime]).strftime("%d.%m.%Y") }</b>:"
    sun            = "&#127774; <b>#{ Time.parse(forecast[:sunrise]).strftime("%H:%M") }</b> - <b>#{ Time.parse(forecast[:sunset]).strftime("%H:%M") }</b>, световой день: <b>#{ time_difference(forecast[:sunset], forecast[:sunrise]) }</b>"
    moon           = "#{ moon_phase(forecast[:moonphase]) }"
    temperature    = "Температура: <b>#{ temperature_human(forecast[:tempmin].round) }</b>#{ celsius }...<b>#{ temperature_human(forecast[:tempmax].round) }</b>#{ celsius }, ощущается как <b>#{ temperature_human(forecast[:feelslike].round) }</b>#{ celsius }"
    pressure       = "Давление:       <b>#{ (forecast[:pressure] * 0.75).round }мм рт. ст.</b>"
    humidity       = "Влажность:     <b>#{ forecast[:humidity].to_i }%</b>"
    wind           = "Ветер:              <b>#{ forecast[:windspeed].round }м/с #{ wind_direction(forecast[:winddir]) }</b>#{ wind_gust }"
    cloudness      = "Облачность:    <b>#{ forecast[:cloudcover].to_i }%</b>"
    weather_descr  = "#{ forecast[:description] }"
    precipitation2 += if forecast[:preciptype]
                       " вероятность осадков: <b>#{ (forecast[:precipprob]).to_f }%</b>, выпадет #{ precipitation_volume }"
                     else
                       " осадков не ожидается"
                     end

    if first_message
        forecast = <<~FORECAST
        <b>#{ @city_name }</b>.\nЧасовой пояс: #{ @time_zone } (#{ @time_zone_shift }ч).\n
        #{ header }
        #{ sun }
        #{ moon }
        #{ temperature }
        #{ pressure }
        #{ humidity }
        #{ wind }
        #{ cloudness }
        #{ weather_descr }
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
        #{ cloudness }
        #{ weather_descr }
        #{ precipitation2 }
      FORECAST
    end
  end

  def emoji(weather_code)
    case weather_code
    when 'wind'                  # Wind speed is high (greater than 30 kph or mph) 
      "💨"
    when 'showers-day'           # Rain showers during the day
      "&#x2614;"
    when 'showers-night'         # Rain showers during the night
      "&#x2614;"
    when 'rain'                  # Amount of rainfall is greater than zero 
      "&#127783;"
    when 'thunder-rain'          # Thunderstorms throughout the day or night
      "&#9928;"
    when 'thunder-showers-day'   # Possible thunderstorms throughout the day
      "&#9928;"
    when 'thunder-showers-night' # Possible thunderstorms throughout the night 
      "&#9928;"
    when 'snow'                  # Amount of snow is greater than zero
      "&#127784;"
    when 'snow-showers-day'      # Periods of snow during the day
      "&#127784;"
    when 'snow-showers-night'    # Periods of snow during the night
      "&#127784;"
    when 'fog'                   # Visibility is low (lower than one kilometer or mile)
      "&#x1F301;"
    when 'clear-day'             # clear day sky
      "&#9728;"
    when 'clear-night'           # clear night sky
      "&#9728;"
    when 'partly-cloudy-day'     # Cloud cover is greater than 20% cover during day time
      "\u{26C5}"
    when 'partly-cloudy-night'   # Cloud cover is greater than 20% cover during night time
      "\u{26C5}"
    when 'cloudy'                # Cloud cover is greater than 90% cover
      "\u{2601}"
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

  def time_difference(t2, t1)
    hours   = (((Time.parse(t2) - Time.parse(t1))/3600)%24).to_i
    minutes = (((Time.parse(t2) - Time.parse(t1))/60)%60).to_i

    "#{ hours }ч #{ minutes }м"
  end
end
