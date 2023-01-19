class Bot
  def initialize(tg_bot_tkn:, yandex_api_tkn:, openweathermap_tkn:, default_cities:)
    @tg_bot_tkn = tg_bot_tkn

    @yandex_api_tkn = yandex_api_tkn

    @openweathermap_tkn = openweathermap_tkn

    @default_cities = default_cities
  end

  def main_method
    forecast = ForecastOpenweathermap.new(@openweathermap_tkn)

    Telegram::Bot::Client.run(@tg_bot_tkn) do |bot|
      start_bot_time = Time.now.to_i

      bot.listen do |message|
        next if start_bot_time - message.date > 650

        case message.text
        when '/start'
          bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{ message.from.first_name }! Погоду для какого города вы хотите узнать? Выберите его из списка или введите название.")
        when '/stop'
          bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{ message.from.first_name }!")
        when '/1'
          respond_for_user(bot, message, forecast, 1)
        when '/2'
          respond_for_user(bot, message, forecast, 2)
        when '/3'
          respond_for_user(bot, message, forecast, 3)
        else
          respond_for_user(bot, message, forecast)
        end
      end
    end
  end

  private

  def respond_for_user(bot, message, forecast, choise = nil)
    answer = if choise
               city_coordinates = @default_cities.values[choise - 1]
               city_name = @default_cities.keys[choise - 1]

               forecast.call(city_coordinates, city_name)
             else
               city_name = message.text

               city_info = YandexCoordinates.new(@yandex_api_tkn).city_info(city_name)

               if city_info
                 city_coordinates = city_info[1]
                 city_name = city_info[0]

                 forecast.call(city_coordinates, city_name)
               else
                 "Указанный населенный пункт не найден."
               end
             end

    bot.api.send_message(chat_id: message.chat.id, text: answer, parse_mode: 'HTML')
  end  
end
