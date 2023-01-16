# Telegram bot "Weather forecast"
Bot shows weather forecast for present and next day in chosen place. You can enter name of the place by yourself or choose from the list. Specify region/district/etc in case if there are some places with the similar names.

## Screenshot
![Application screenshot](https://github.com/dmentry/WeatherForecastBot/blob/master/Screenshot.jpg)

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
Sign in at `https://openweathermap.org`, copy token and insert it into string `OPENWEATHERMAP_KEY` instead of `your_token`

Sign in at developer's section of Yandex, get the API Geocoder token and insert it into the string `YANDEX_API_KEY` instead of `your_token`

Create your bot at `@BotFather`, get the token for it and insert it into string `TELEGRAM_BOT_API_TOKEN` instead of `your_token`

## Run
```
main.rb
```

## ToDo
Implement weather conditions' icons
