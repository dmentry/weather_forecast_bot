class Forecast
  attr_reader :date, :part_of_day, :min_temp, :max_temp, :max_wind, :clouds

  CLOUDINESS = {-1 => "туман", 0 => "ясно", 1 => "малооблачно", 2 => "облачно", 3 => "пасмурно"}

  PART_OF_DAY = {0 => "ночь", 1 => "утро", 2 => "день", 3 => "вечер"}

  def initialize(params)
    @date = params[:date]
    @part_of_day = params[:part_of_day]
    @min_temp = params[:min_temp]
    @max_temp = params[:max_temp]
    @max_wind = params[:max_wind]
    @clouds = params[:clouds]
  end

  def self.forecast_fetching(xml)
    date= "#{xml.attributes["day"]}.#{xml.attributes["month"]}.#{xml.attributes["year"]}"

    part_of_day_index = xml.attributes["tod"].to_i

    part_of_day = PART_OF_DAY[part_of_day_index]
    min_temp = xml.elements["TEMPERATURE"].attributes["min"].to_i

    if min_temp > 0
      min_temp = "+#{min_temp}"
    elsif min_temp < 0
      min_temp = "#{min_temp}"
    end

    max_temp = xml.elements["TEMPERATURE"].attributes["max"].to_i

    if max_temp > 0
      max_temp = "+#{max_temp}"
    elsif max_temp < 0
      max_temp = "#{max_temp}"
    end

    max_wind = xml.elements["WIND"].attributes["max"]

    clouds_index = xml.elements["PHENOMENA"].attributes["cloudiness"].to_i

    clouds = CLOUDINESS[clouds_index]

    new(
      date: date,
      part_of_day: part_of_day,
      min_temp: min_temp,
      max_temp: max_temp,
      max_wind: max_wind,
      clouds: clouds
    )
  end
end
