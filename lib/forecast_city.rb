def forecast_city(forecast_raw_data, city_name)
  <<-FORECAST
    #{ city_name } - прогноз погоды на #{ Time.at(forecast_raw_data[:dt]).strftime("%d.%m.%Y") }:
    Утром:   #{ temperature_human(forecast_raw_data[:temp][:morn].round) }°C
    Днем:    #{ temperature_human(forecast_raw_data[:temp][:day].round) }°C
    Вечером: #{ temperature_human(forecast_raw_data[:temp][:eve].round) }°C
    Ночью:   #{ temperature_human(forecast_raw_data[:temp][:night].round) }°C
    Ветер:   #{ forecast_raw_data[:wind_speed] } м/с
    Вероятность осадков #{ (forecast_raw_data[:pop]*100).to_i }% - #{ forecast_raw_data[:weather][0][:description] }
  FORECAST
end
