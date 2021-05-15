require "net/http"
require "uri"
require "rexml/document"
require_relative "lib/forecast_openweathermap"
require_relative 'lib/temperature_helper'

cities = { "Москва" => [55.7532, 37.6252], "Майкоп" => [44.6107, 40.1058] }

puts "Погоду для какого города Вы хотите узнать?"

cities.each_key.with_index(1) {|key, index| puts "#{index}: #{key}"}

choise = gets.to_i

city_coordinates = cities.values[choise - 1]

forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates)

forecast_raw_data = forecast.daily_temp

forecast = <<HEREDOC

#{cities.keys[choise - 1]} - прогноз погоды на #{Time.at(forecast_raw_data[:dt]).strftime("%d.%m.%Y")}:
Утром:   #{ temperature_human(forecast_raw_data[:temp][:morn].round) }°C
Днем:    #{ temperature_human(forecast_raw_data[:temp][:day].round) }°C
Вечером: #{ temperature_human(forecast_raw_data[:temp][:eve].round) }°C
Ночью:   #{ temperature_human(forecast_raw_data[:temp][:night].round) }°C
Ветер:   #{ forecast_raw_data[:wind_speed] } м/с
Вероятность осадков #{ (forecast_raw_data[:pop]*100).to_i }% - #{ forecast_raw_data[:weather][0][:description] }

HEREDOC

puts forecast
