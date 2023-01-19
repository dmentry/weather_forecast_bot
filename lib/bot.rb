class Bot
  def initialize(tg_bot_tkn:, yandex_api_tkn:, openweathermap_tkn:, default_cities:)
    @tg_bot_tkn     = tg_bot_tkn

    @yandex_api_tkn = yandex_api_tkn

    @openweathermap_tkn = openweathermap_tkn

    @default_cities    = default_cities
  end

  def main_method
    forecast = ForecastOpenweathermap.new(@openweathermap_tkn)

    Telegram::Bot::Client.run(@tg_bot_tkn) do |bot|
      bot.listen do |message|
        case message.text
        when '/start'
          bot.api.send_Message(chat_id: message.chat.id, text: "Привет, #{ message.from.first_name }! Погоду для какого города вы хотите узнать? Выберите его из списка или введите название.")
        when '/stop'
          bot.api.send_message(chat_id: message.chat.id, text: "Пока, #{ message.from.first_name }!")
        when '/1'
          respond_for_default_city(1, bot, message, forecast)
        when '/2'
          respond_for_default_city(2, bot, message, forecast)
        when '/3'
          respond_for_default_city(3, bot, message, forecast)
        else
          city_name = message.text

          city_info = YandexCoordinates.new(@yandex_api_tkn).city_info(city_name)

          if city_info
            city_coordinates = city_info[1]

            city_name = city_info[0]

            bot.api.send_message(chat_id: message.chat.id, text: forecast.call(city_coordinates, city_name), parse_mode: 'HTML')
          else
            bot.api.send_message(chat_id: message.chat.id, text: "Указанный населенный пункт не найден.")
          end
        end
      end
    end
  end

  private

  def respond_for_default_city(choise, bot, message, forecast)
    city_coordinates = @default_cities.values[choise - 1]

    bot.api.send_message(chat_id: message.chat.id, text: forecast.call(city_coordinates, @default_cities.keys[choise - 1]), parse_mode: 'HTML')
  end  
end
