require "net/http"
require "uri"
require "rexml/document"
require_relative "lib/forecast"
require_relative 'lib/temperature_helper'
# require_relative "lib/overall_forecast"

# cities = {"Москва" => 37, "Санкт-Петербург" => 69, "Майкоп" => 158, "Гузерипль" => 9705, "Геленджик" => 2876, "Для текущего местоположения" => "current"}
cities = { "Москва" => [55.7532, 37.6252], "Майкоп" => [44.6107, 40.1058] }

puts "Погоду для какого города Вы хотите узнать?"

cities.each_key.with_index(1) {|key, index| puts "#{index}: #{key}"}

choise = gets.to_i

city_coordinates = cities.values[choise - 1]

uri = URI.parse("https://www.meteoservice.ru/en/export/gismeteo?point=#{city_code}")

response = Net::HTTP.get_response(uri)

doc = REXML::Document.new(response.body)

overall = OverallForecast.forecasts_collecting(doc)

puts "#{cities.keys[choise - 1]} - прогноз погоды:\n\n"

overall.forecasts.each do |forecast|
  puts "#{forecast.date}, #{forecast.part_of_day}:"

  puts "#{forecast.min_temp}..#{forecast.max_temp}, ветер #{forecast.max_wind} м/с, #{forecast.clouds}"

  puts
end
