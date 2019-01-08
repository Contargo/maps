verkehrsverbot = require("verkehrsverbot")

CustomWayHandlers = {}

function CustomWayHandlers.width_height_weight(profile, way, result, data)
  local maxwidth = CustomWayHandlers.numberFromTagValue(way:get_value_by_key("maxwidth"))
  if 0 < maxwidth then
    if maxwidth <= 2.5 then
      return false
    end
  end
  local maxheight = CustomWayHandlers.numberFromTagValue(way:get_value_by_key("maxheight"))
  if 0 < maxheight then
    if maxheight < 4 then
      return false
    end
  end
  local maxweight = CustomWayHandlers.numberFromTagValue(way:get_value_by_key("maxweight"))
  if 0 < maxweight then
    if maxweight <= 40 then
      return false
    end
  end
end

function CustomWayHandlers.delete_way(profile, way, result, data)
  way_id = way:get_value_by_key("id")
  if profile.ways_to_delete[way_id] then
    return false
  end
end

function CustomWayHandlers.swiss_border(profile, way, result, data)
  if data.crossing == 'border' then
    result.duration = profile.properties.swiss_border_penalty
    result.weight = profile.properties.swiss_border_weight
  end
end

function CustomWayHandlers.verkehrsverbot(profile, way, result, data)
  if verkehrsverbot.durchgangsverkehr(way) then
    result.weight = 100
  end
end

function CustomWayHandlers.numberFromTagValue(value)
  if value == nil then
    return 0
  end
  local n = tonumber(value:match("%d.%d*"))
  if n == nil then
    n = 0
  end
  return math.abs(n)
end

return CustomWayHandlers
