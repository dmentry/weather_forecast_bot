require 'telegram/bot'
require 'pony'
require_relative 'lib/forecast_openweathermap'
# require_relative 'lib/temperature_helper'

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

cities = { "Железнодорожный" => [55.7471, 38.0224], "Москва" => [55.7532, 37.6252], "Майкоп" => [44.6107, 40.1058] }

Telegram::Bot::Client.run(tg_bot_token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}! Погоду для какого города вы хотите узнать? Выберите его из списка.")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!")
    when '/1'
      choise = 1

      city_coordinates = cities.values[choise - 1]

      forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, cities.keys[choise - 1])

      bot.api.send_message(chat_id: message.chat.id, text: forecast.daily_temp)

      Pony.mail({
        :subject => "Прогноз погоды",
        :body => "Прогноз погоды",
        :to => MAIL_RECIEVER,
        :from => 'weather bot',
        :via => :smtp,
        :via_options => {
          :address => 'smtp.mail.ru',
          :port => '465',
          :tls => true,
          :user_name => MAIL_USERNAME,
          :password => MAIL_PSW,
          :authentication => :plain
        }
      })
    when '/2'
      choise = 2

      city_coordinates = cities.values[choise - 1]

      forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, cities.keys[choise - 1])

      bot.api.send_message(chat_id: message.chat.id, text: forecast.daily_temp)

    when '/3'
      choise = 3

      city_coordinates = cities.values[choise - 1]

      forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, cities.keys[choise - 1])

      bot.api.send_message(chat_id: message.chat.id, text: forecast.daily_temp)
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Не понимаю команду")
    end
  end
end
