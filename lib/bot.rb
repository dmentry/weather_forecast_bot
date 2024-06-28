class Bot
  def initialize(tg_bot_tkn:, openweathermap_tkn:, nasa_api_tkn:, default_cities:)
    @tg_bot_tkn         = tg_bot_tkn
    @openweathermap_tkn = openweathermap_tkn
    @nasa_api_tkn       = nasa_api_tkn
    @default_cities     = default_cities
    @out                = []

    clear_values
  end

  def main_method
    forecast = ForecastOpenweathermap.new(@openweathermap_tkn)

    loop do
      begin
        Telegram::Bot::Client.run(@tg_bot_tkn) do |bot|
          start_bot_time = Time.now.to_i

          bot.listen do |message|
            next if start_bot_time - message.date > 650

            if message.respond_to?(:text)

              File.open('users_id.txt', "a:UTF-8") do |file| 
                file.puts("#{ Time.now.strftime("%d.%m.%Y %T") }, id: #{ message.chat.id }, username: #{ message.chat.username }.")
              end

              if message.text == '/start'
                clear_values

                bot.api.send_Message(
                                     chat_id: message.chat.id, 
                                     text: "Привет!\nПогоду для какого населенного пункта хотите узнать?\n",
                                     parse_mode: 'HTML'
                                    )
              elsif message.text == '/help'
                bot.api.send_Message(
                                     chat_id: message.chat.id, 
                                     text: "\n&#8505; Выберите населенный пункт из списка или введите название.\nНазвание населенного пункта можно вводить "\
                                           "на русском или на английском (не просто латиницей, а именно по-английски). "\
                                           "Если населенных пунктов с указанным названием несколько, то выбирается наиболее крупный."\
                                           "\nПрогноз на восемь дней.\nВ качестве бонуса по команде /photo будет показана фотка дня NASA.",
                                     parse_mode: 'HTML'
                                    )
              elsif message.text == '/stop'
                clear_values

                bye_message(bot: bot, message: message)
              elsif message.text.match?(/\A\/\d\z/)
                city_variant = message.text.gsub(/\A\//, '').to_i

                respond_for_user(bot, message, forecast, city_variant)
              elsif message.text.match?(/\sДа\z/) && @out.size > 0
                begin
                  bot.api.send_message(chat_id: message.chat.id, text: @out[@forecast_day_index], parse_mode: 'HTML')
                rescue => e
                  log_writing(e: e, error_position: 'elsif-Да')
                end

                @forecast_day_index += 1

                if @forecast_day_index <= @quantity_of_days 
                  send_msg_with_keabord(bot: bot, message: message, question: 'Дальше?', keyboard_values: [[text: '✔️ Да'], [text: '❌ Нет']])
                else
                  clear_values

                  bye_message(bot: bot, message: message, additional_text: 'На этом все. ')
                end
              elsif message.text.match?(/\sНет\z/)
                clear_values

                bye_message(bot: bot, message: message)

              #Пасхалка
              elsif message.text == '/photo'
                uri = URI.parse("https://api.nasa.gov/planetary/apod?api_key=#{ @nasa_api_tkn }")

                response = Net::HTTP.get_response(uri)

                nasa_jsn = JSON.parse(response.body, symbolize_names: true)

                dt = Date&.parse(nasa_jsn[:date])&.strftime("%d.%m.%Y")

                msg = if nasa_jsn[:media_type] == "image"
                        "<b>Фото дня NASA на #{ dt }</b>:\n#{ nasa_jsn[:url] }\n#{ nasa_jsn[:explanation] }"
                      else
                        'Сегодня картинки нет 😦'
                      end

                begin
                  bot.api.send_message(chat_id: message.chat.id, text: msg, parse_mode: 'HTML')
                rescue => e
                  log_writing(e: e, error_position: 'пасхалке')
                end
              else
                if !message&.text.nil? && message&.text.match?(/\A[А-Яёа-яё\-A-Za-z\s1-9]{2,}\z/)
                  respond_for_user(bot, message, forecast)
                else
                  clear_values

                  bye_message(bot: bot, message: message, additional_text: 'Неизвестная команда. Попробуйте начать заново, нажав /start. ')
                end
              end
            else
              clear_values

              bye_message(bot: bot, message: message, additional_text: 'Неизвестная команда. Попробуйте начать заново, нажав /start. ')
            end
          end
        end
      rescue => e
        File.open('tg_bot_log.txt', "a:UTF-8") do |file| 
          file.puts("#{ Time.now.strftime("%d.%m.%Y %T") }:")
          file.puts('Ошибка в главном цикле:')
          file.puts("Класс ошибки: #{ e.class }")
          file.puts("Сообщение ошибки: #{ e.message }")
        end
      end
    end
  end

  private

  def respond_for_user(bot, message, forecast, choise = nil)
    if choise
      city_coordinates = @default_cities.values[choise - 1]
      city_name = @default_cities.keys[choise - 1]

      @out = forecast.call(city_coordinates: city_coordinates, city_name: city_name)
    else
      city_name = message&.text

      parser = URI::Parser.new

      message_encoded = parser.escape(city_name)

      uri_parsed = URI.parse("http://api.openweathermap.org/geo/1.0/direct?q=#{ message_encoded }&limit=1&appid=#{ @openweathermap_tkn }")

      feedback = Net::HTTP.get_response(uri_parsed)

      server_response = JSON.parse(feedback.body, symbolize_names: true)

      if server_response.size > 0
        server_response.each do |city|
          city_ru_name = city[:local_names][:ru] || city[:name]
          city_lat     = city[:lat]
          city_lon     = city[:lon]
          city_state   = city[:state]

          @out = forecast.call(city_name: city_ru_name, city_coordinates: [city_lat, city_lon], city_state: city_state)
        end
      else
        @out << "Указанный населенный пункт не найден."
      end
    end

    @quantity_of_days = @out.size - 1

    if @quantity_of_days > 1
      begin
        bot.api.send_message(chat_id: message.chat.id, text: @out[@forecast_day_index], parse_mode: 'HTML')
      rescue => e
        log_writing(e: e, error_position: 'respond_for_user-if')
      end

      @forecast_day_index += 1

      if @forecast_day_index <= @quantity_of_days 
        send_msg_with_keabord(bot: bot, message: message, question: 'Дальше?', keyboard_values: [[text: '✔️ Да'], [text: '❌ Нет']])
      else
        clear_values

        bye_message(bot: bot, message: message, additional_text: 'На этом все. ')
      end
    else
      begin
        bot.api.send_message(chat_id: message.chat.id, text: @out&.first, parse_mode: 'HTML')
      rescue => e
        log_writing(e: e, error_position: 'respond_for_user-else')
      end

      clear_values

      bye_message(bot: bot, message: message)
    end
  end

  def send_msg_with_keabord(bot:, message:, question:, keyboard_values:)
    answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard_values, one_time_keyboard: true, resize_keyboard: true)

    begin
      bot.api.send_message(chat_id: message.chat.id, text: question, reply_markup: answers)
    rescue => e
      log_writing(e: e, error_position: 'send_msg_with_keabord')
    end
  end

  def bye_message(bot:, message:, additional_text: '')
    bye_text = additional_text + "Пока!"
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    begin
      bot.api.send_message(chat_id: message.chat.id, text: bye_text, reply_markup: kb)
    rescue => e
      log_writing(e: e, error_position: 'bye_message')
    end
  end

  def clear_values
    @forecast_day_index = 0
    @quantity_of_days   = 0
    @out                = []
  end

  def log_writing(e:, error_position:)
    File.open('log.txt', "a:UTF-8") do |file| 
      file.puts("#{ Time.now.strftime("%d.%m.%Y %T") } | Ошибка в #{ error_position }")
      file.puts("Класс ошибки: #{ e.class }")
      file.puts("Сообщение ошибки: #{ e.message }")
      file.puts
    end
  end
end
