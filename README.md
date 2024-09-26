# Telegram bot "Weather forecast"
Bot shows weather forecast for present and next days in chosen place. You can enter name of the place by yourself or choose from the list. Specify region/district/etc in case if there are some places with the similar names. Names could be entered in Russian, in Russian with Latinic letters or in English. Also coordinates in decimal format could be entered. Latitude, longitude separated with comma (e.g. 55.1234, 48.78912).

## Screenshot
![Application screenshot](https://github.com/dmentry/WeatherForecastBot/blob/master/Screenshot.png)

## Requirements
* Ruby
* gem "dotenv"
* gem "telegram-bot-ruby"

## Before start
Clone or download repository

```
bundle install
```

Rename `.env.example` into `.env`
Sign in at `https://www.visualcrossing.com`, copy token and insert it into string `WEATHER_API_KEY` instead of `your_token`

Sign in at developer's section of Yandex, get the API Geocoder token and insert it into the string `YANDEX_API_KEY` instead of `your_token`

Create your bot at `@BotFather`, get the token for it and insert it into string `TELEGRAM_BOT_API_TOKEN` instead of `your_token`

If you want to have NASA photo of the day, generate token at `https://api.nasa.gov`, copy and insert it into string `NASA_API_KEY` instead of `your_token`

## Run
```
weather_bot.rb
```
* TODO:
add localization
