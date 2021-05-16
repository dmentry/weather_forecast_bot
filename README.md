# Телеграм-бот "Прогноз погоды"
Телеграм-бот показывает прогноз погоды на следующий день в выбранном из списка городе.

## Скриншот
![Application screenshot](https://github.com/dmentry/what_to_wear_tg_bot/blob/master/screenshot_bot.jpg)

## Потестировать бота
Клонировать или скачать репозиторий

```
bundle install
```

```
main.rb
```
Пройти по ссылке
https://t.me/city_weath_bot

## Требования
* Ruby

* gem "dotenv"

* gem "telegram-bot-ruby"

## Перед запуском

```
bundle install
```

Переименуйте `.env.example` в `.env`

Зарегистрируйтесь на `https://openweathermap.org`, скопируйте оттуда токен и вставьте его в соответствующую строку `.env` вместо `your_token`

Создайте своего бота у `@BotFather`, получите для него токен и вставьте его в соответствующую строку `.env` вместо `your_token`

## Запустить
```
main.rb
```
