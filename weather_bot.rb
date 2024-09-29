require 'cgi'
require 'date'
require 'dotenv/load'
require 'erb'
require 'json'
require 'net/http'
require 'telegram/bot'

include ERB::Util

require_relative 'lib/bot'
require_relative 'lib/weather_forecast'
require_relative 'lib/yandex_coordinates'

TG_BOT_TOKEN     = ENV['TELEGRAM_BOT_API_TOKEN']
YANDEX_API_TOKEN = ENV['YANDEX_API_KEY']
NASA_API_KEY     = ENV['NASA_API_KEY']
WEATHER_API_KEY  = ENV['WEATHER_API_KEY']

CITIES = {
          'Москва' => [55.753, 37.621],
          'Балашиха' => [55.7471, 38.0224],
          'Покров' => [55.9192, 39.1755],
          'Майкоп' => [44.6107, 40.1058],
          'Санкт-Петербург' => [59.939, 30.314],
          'Краснодар' => [45.035, 38.974],
          'Екатеринбург' => [56.838, 60.597],
          'Новосибирск' => [55.030, 82.920],
          'Владивосток' => [43.115, 131.885]
         }

bot = Bot.new(
                tg_bot_tkn: TG_BOT_TOKEN, 
                nasa_api_tkn: NASA_API_KEY, 
                yandex_api_tkn: YANDEX_API_TOKEN,
                weather_tkn: WEATHER_API_KEY,
                default_cities: CITIES
              )

bot.main_method
