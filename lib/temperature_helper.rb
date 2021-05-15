def temperature_human(ambient_temp)
  if ambient_temp > 0
    return "+#{ambient_temp}"
  else
    return ambient_temp
  end
end