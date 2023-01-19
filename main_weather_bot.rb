require 'telegram/bot'
require_relative 'lib/forecast_openweathermap'
require_relative 'lib/yandex_coordinates'
require 'dotenv/load'
require 'net/http'
require 'json'
require 'date'
require "erb"

include ERB::Util

tg_bot_token         = ENV['TELEGRAM_BOT_API_TOKEN']
yandex_api_token     = ENV['YANDEX_API_KEY']
openweathermap_token = ENV['OPENWEATHERMAP_KEY']
@cities              = { "Балашиха" => [55.7471, 38.0224], "Майкоп" => [44.6107, 40.1058], "Геленджик" => [44.5641, 38.08606] }

def respond_for_default_city(choise, bot, message)
  city_coordinates = @cities.values[choise - 1]

  bot.api.send_message(chat_id: message.chat.id, text: @forecast.call(city_coordinates, @cities.keys[choise - 1]), parse_mode: 'HTML')
end

@forecast = ForecastOpenweathermap.new(openweathermap_token)

Telegram::Bot::Client.run(tg_bot_token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{ message.from.first_name }! Погоду для какого города вы хотите узнать? Выберите его из списка или введите название.")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{ message.from.first_name }!")
    when '/1'
      choise = 1

      respond_for_default_city(choise, bot, message)
    when '/2'
      choise = 2

      respond_for_default_city(choise, bot, message)
    when '/3'
      choise = 3

      respond_for_default_city(choise, bot, message)
    else
      city_name = message.text

      city_info = YandexCoordinates.new(yandex_api_token).city_info(city_name)

      if city_info
        city_coordinates = city_info[1]

        city_name = city_info[0]

        bot.api.send_message(chat_id: message.chat.id, text: @forecast.call(city_coordinates, city_name), parse_mode: 'HTML')
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Указанный населенный пункт не найден.")
      end
    end
  end
end
