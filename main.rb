require 'telegram/bot'
require_relative 'lib/forecast_openweathermap'
require_relative 'lib/temperature_helper'
require_relative 'lib/forecast_city'

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

cities = { "Москва" => [55.7532, 37.6252], "Майкоп" => [44.6107, 40.1058] }

Telegram::Bot::Client.run(tg_bot_token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}! Погоду для какого города вы хотите узнать? Выберите город")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!")
    when '/1'
      choise = 1

      city_coordinates = cities.values[choise - 1]

      forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, cities.keys[choise - 1])

      forecast_city = forecast.daily_temp

      bot.api.send_message(chat_id: message.chat.id, text: forecast_city)
    when '/2'
      # choise = 2

      # city_coordinates = cities.values[choise - 1]

      # forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates)

      # forecast_raw_data = forecast.daily_temp

      # bot.api.send_message(chat_id: message.chat.id, text: forecast_city(forecast_raw_data, cities.keys[choise - 1]))
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Не понимаю команду")
    end
  end
end
