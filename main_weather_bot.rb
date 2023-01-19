require 'telegram/bot'
require 'dotenv/load'
require 'net/http'
require 'json'
require 'date'
require "erb"

include ERB::Util

require_relative 'lib/bot'
require_relative 'lib/forecast_openweathermap'
require_relative 'lib/yandex_coordinates'

TG_BOT_TOKEN         = ENV['TELEGRAM_BOT_API_TOKEN']
YANDEX_API_TOKEN     = ENV['YANDEX_API_KEY']
OPENWEATHERMAP_TOKEN = ENV['OPENWEATHERMAP_KEY']
cities               = { "Балашиха" => [55.7471, 38.0224], "Майкоп" => [44.6107, 40.1058], "Геленджик" => [44.5641, 38.08606] }
cities.freeze

bot=Bot.new(tg_bot_tkn: TG_BOT_TOKEN, yandex_api_tkn: YANDEX_API_TOKEN, openweathermap_tkn: OPENWEATHERMAP_TOKEN, default_cities: cities)

bot.main_method
