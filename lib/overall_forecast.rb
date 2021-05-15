class OverallForecast
  attr_reader :forecasts

  def initialize(forecasts)
    @forecasts = forecasts
  end

  def self.forecasts_collecting(doc)
    forecasts = doc.root.get_elements("REPORT/TOWN/FORECAST").map { |xml| Forecast.forecast_fetching(xml)}

    new(forecasts)
  end
end
