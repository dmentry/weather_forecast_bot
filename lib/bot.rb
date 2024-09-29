class Bot
  def initialize(tg_bot_tkn:, nasa_api_tkn:, yandex_api_tkn:, weather_tkn:, default_cities:)
    @tg_bot_tkn     = tg_bot_tkn
    @yandex_api_tkn = yandex_api_tkn
    @nasa_api_tkn   = nasa_api_tkn
    @weather_tkn    = weather_tkn
    @default_cities = default_cities
    @out            = []

    clear_values
  end

  def main_method
    forecast = WeatherForecast.new(@weather_tkn)

    loop do
      begin
        Telegram::Bot::Client.run(@tg_bot_tkn) do |bot|
          start_bot_time = Time.now.to_i

          bot.listen do |message|
            case message

            when Telegram::Bot::Types::Message
              next if message.text.nil?
              next if start_bot_time - message.date > 650

              if message.respond_to?(:text)

                File.open('users_id.txt', "a:UTF-8") do |file| 
                  file.puts("#{ Time.now.strftime("%d.%m.%Y %T") }, id: #{ message.chat.id }, username: #{ message.chat.username }.")
                end

                if message.text == '/start'
                  clear_values

                  add_menu_buttons(bot: bot, message: message)

                elsif message.text == '/help'
                  bot.api.send_Message(
                                       chat_id: message.chat.id, 
                                       text: "&#8505;\nВыберите населенный пункт из списка или введите его название.\nМожно "\
                                             "вводить по-русски, по-английски или по-русски латиницей. Если название распространенное, то конкретизируйте его, "\
                                             "добавив область и/или район."\
                                             "\nТакже, можно просто ввести координаты в десятичном формате через запятую: широта, долгота.\nНапример: 55.753215, 37.990546"\
                                             "\nПрогноз на 15 дней.\nВ качестве бонуса по команде /photo будет показана фотка дня NASA.",
                                       parse_mode: 'HTML'
                                      )
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
                    log_writing(e: e, error_position: 'пасхалка')
                  end
                else
                  if @out.size > 0
                    yes = Telegram::Bot::Types::InlineKeyboardButton.new(text: '✔️ Да', callback_data: 'yes')
                    no  = Telegram::Bot::Types::InlineKeyboardButton.new(text: '❌ Нет', callback_data: 'no')
                    kb  = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[yes, no]])

                    bot.api.send_message(chat_id: message.from.id, text: "Дальше? Выберите 'Да' или 'Нет'.", reply_markup: kb, parse_mode: 'HTML')
                  else
                    respond_for_user(bot, message, forecast)
                  end
                end
              else
                clear_values

                bye_message(bot: bot, message: message, additional_text: 'Неизвестная команда. Попробуйте начать заново, нажав /start. ')
              end

            when Telegram::Bot::Types::CallbackQuery
              show_text = if message.data == '1'
                            'Вы выбрали прогноз для Москвы'
                          elsif message.data == '2'
                            'Вы выбрали прогноз для Балашихи'
                          elsif message.data == '3'
                            'Вы выбрали прогноз для Покрова'
                          elsif message.data == '4'
                            'Вы выбрали прогноз для Майкопа'
                          elsif message.data == '5'
                            'Вы выбрали прогноз для Санкт-Петербурга'
                          elsif message.data == '6'
                            'Вы выбрали прогноз для Краснодара'
                          elsif message.data == '7'
                            'Вы выбрали прогноз для Екатеринбурга'
                          elsif message.data == '8'
                            'Вы выбрали прогноз для Новосибирска'
                          elsif message.data == '9'
                            'Вы выбрали прогноз для Владивостока'
                          elsif message.data == 'yes'
                            'Вы выбрали продолжить'
                          elsif message.data == 'no'
                            'На этом останавливаемся'
                          end

              bot.api.answerCallbackQuery(callback_query_id: message.id, text: show_text)

              if message.data =~ /\A\d\z/
                city_variant = message.data&.to_i

                respond_for_user(bot, message, forecast, city_variant)

              elsif message.data == 'yes' && @out.size > 0
                begin
                  a=bot.api.send_message(chat_id: message.from.id, text: @out[@forecast_day_index], parse_mode: 'HTML')
                rescue => e
                  log_writing(e: e, error_position: 'elsif-Да')
                end

                @forecast_day_index += 1

                if @forecast_day_index <= @quantity_of_days 
                  send_variants(bot: bot, message: message)
                else
                  clear_values

                  bye_message(bot: bot, message: message, additional_text: 'Готово')
                end

              elsif message.data == 'no'
                clear_values

                bye_message(bot: bot, message: message, additional_text: 'Ок, на этом останавливаемся')
              end

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
      city_data = message&.text

      return @out << "Указанный населенный пункт не найден." if !city_data

      if city_data =~ /\A-?\d{,2}\.\d+,\s?-?\d{,3}\.\d+\z/
        coordinates_dec = city_data.scan(/(\A-?\d{,2})\.\d+,\s?(-?\d{,3})\.\d+\z/).flatten

        if coordinates_dec.size == 2 && (coordinates_dec.first.to_i >= -90) && (coordinates_dec.first.to_i <= 90) && (coordinates_dec.last.to_i >= -180) && (coordinates_dec.last.to_i <= 180)
          @out = forecast.call(city_name: "Прогноз для точки с координатами: #{ city_data }", city_coordinates: city_data)
        else
          return @out << "Координаты некорректные. Введите сначала широту, потом долготу в формате: ШШ.ШШШШ,ДД.ДДДД"
        end
      else
        city_info = YandexCoordinates.new(@yandex_api_tkn).city_info(city_data)

        if city_info
          city_coordinates = city_info[1]
          city_name = city_info[0]

          @out = forecast.call(city_name: city_name, city_coordinates: city_coordinates)
        else
          @out << "Указанный населенный пункт не найден."
        end
      end
    end

    @quantity_of_days = @out.size - 1

    if @quantity_of_days > 1
      begin
        bot.api.send_message(chat_id: message.from.id, text: @out[@forecast_day_index], parse_mode: 'HTML')
      rescue => e
        log_writing(e: e, error_position: 'respond_for_user-if')
      end

      @forecast_day_index += 1

      if @forecast_day_index <= @quantity_of_days 
        send_variants(bot: bot, message: message)
      else
        clear_values

        bye_message(bot: bot, message: message, additional_text: 'На этом все. ')
      end
    else
      begin
        bot.api.send_message(chat_id: message.from.id, text: @out&.first, parse_mode: 'HTML')
      rescue => e
        log_writing(e: e, error_position: 'respond_for_user-else')
      end

      clear_values
    end
  end

  def send_variants(bot:, message:)
    yes = Telegram::Bot::Types::InlineKeyboardButton.new(text: '✔️ Да', callback_data: 'yes')
    no  = Telegram::Bot::Types::InlineKeyboardButton.new(text: '❌ Нет', callback_data: 'no')

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[no, yes]])

    bot.api.send_message(chat_id: message.from.id, text: 'Дальше?', reply_markup: kb, parse_mode: 'HTML')
  end

  def bye_message(bot:, message:, additional_text: '')
    bye_text = additional_text
    kb = Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)

    begin
      bot.api.send_message(chat_id: message.from.id, text: bye_text, reply_markup: kb)
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

  def add_menu_buttons(bot:, message:)
    moscow      = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Москва', callback_data: '1')
    balashikha  = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Балашиха', callback_data: '2')
    pokrov      = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Покров', callback_data: '3')
    maykop      = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Майкоп', callback_data: '4')
    spb         = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Санкт-Петербург', callback_data: '5')
    krasnodar   = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Краснодар', callback_data: '6')
    ekat        = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Екатеринбург', callback_data: '7')
    novosib     = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Новосибирск', callback_data: '8')
    vladivostok = Telegram::Bot::Types::InlineKeyboardButton.new(text: 'Владивосток', callback_data: '9')

    kb = Telegram::Bot::Types::InlineKeyboardMarkup.new(inline_keyboard: [[moscow, balashikha, pokrov], [krasnodar, maykop], [spb, ekat], [novosib, vladivostok]])

    bot.api.send_message(chat_id: message.from.id, text: "Привет!\nПогоду для какого населенного пункта хотите узнать? Выберите или введите название населенного пункта или его координаты:", reply_markup: kb, parse_mode: 'HTML')
  end
end
