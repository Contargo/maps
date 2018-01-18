local verkehrsverbot = {}

function verkehrsverbot.durchgangsverkehr(way)

  local traffic_sign = way:get_value_by_key("traffic_sign")

  if traffic_sign == "DE:253,1053-36" then
    return true
  end

  return false
end

return verkehrsverbot
