require 'telegram/bot'
require_relative 'lib/forecast_openweathermap'

tg_bot_token = ENV['TELEGRAM_BOT_API_TOKEN']

yandex_api = ENV['YANDEX_API_KEY']

cities = { "Железнодорожный" => [55.7471, 38.0224], "Москва" => [55.7532, 37.6252], "Майкоп" => [44.6107, 40.1058] }

Telegram::Bot::Client.run(tg_bot_token) do |bot|
  bot.listen do |message|
    case message.text
    when '/start'
      bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{message.from.first_name}! Погоду для какого города вы хотите узнать? Выберите его из списка или введите название. Если показан одноименный населенный пункт, но не тот, который вам нужен, введите название с областью и/или районом.")
    when '/stop'
      bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{message.from.first_name}!")
    when '/1'
      choise = 1

      city_coordinates = cities.values[choise - 1]

      forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, cities.keys[choise - 1])

      bot.api.send_message(chat_id: message.chat.id, text: forecast.daily_temp)
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
      uri = URI.parse("https://geocode-maps.yandex.ru/1.x/?apikey=#{yandex_api}&format=json&geocode=#{URI.encode(message.text)}&results=3")

      response = Net::HTTP.get_response(uri)

      jsn = JSON.parse(response.body, symbolize_names: true)
      #смотрим, определился ли город
      found_results = jsn[:response][:GeoObjectCollection][:metaDataProperty][:GeocoderResponseMetaData][:found].to_i
      if found_results != 0
        #достаем координаты и меняем их местами для openweathermap
        city_coordinates = jsn[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:Point][:pos]
          .split(/ /)
            .map(&:to_f)
              .reverse!

        city_name = "#{ jsn[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:name] }, #{ jsn[:response][:GeoObjectCollection][:featureMember][0][:GeoObject][:description] }"

        forecast = ForecastOpenweathermap.new(ENV['OPENWEATHERMAP_KEY'], city_coordinates, city_name)

        bot.api.send_message(chat_id: message.chat.id, text: forecast.daily_temp)
      else
        bot.api.send_message(chat_id: message.chat.id, text: "Указанный населенный пункт не найден.")
      end
    end
  end
end
