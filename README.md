# Телеграм-бот "Прогноз погоды"
Телеграм-бот показывает прогноз погоды на текущий и следующий день в выбранном городе. Можно ввести название самому или выбрать из списка. Если показывается одноименный населенный пункт, введите название с областью и/или районом.

## Скриншот
![Application screenshot](https://github.com/dmentry/WeatherForecastBot/blob/master/Screenshot.jpg)

## Потестировать бота
Пройти по ссылке
https://t.me/city_weath_bot

## Требования
* Ruby

* gem "dotenv"

* gem "telegram-bot-ruby"

## Перед запуском
Клонировать или скачать репозиторий

```
bundle install
```

```
main.rb
```

```
bundle install
```

Переименуйте `.env.example` в `.env`

Зарегистрируйтесь на `https://openweathermap.org`, скопируйте оттуда токен и вставьте его в строку `OPENWEATHERMAP_KEY` вместо `your_token`

Зарегистрируйтесь в кабинете разрабюотчика Яндекс, получите ключ API Геокодер и вставьте его в строку `YANDEX_API_KEY` вместо `your_token`

Создайте своего бота у `@BotFather`, получите для него токен и вставьте его в строку `TELEGRAM_BOT_API_TOKEN` вместо `your_token`

## Запустить
```
main.rb
```
