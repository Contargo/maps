--
-- Contargo Truck Profile
--

ignore_in_grid = { ["ferry"] = true }
service_tag_restricted = { ["parking_aisle"] = true }

access_tag_blacklist = { ["no"] = true }
access_tag_restricted = { ["destination"] = true, ["private"] = true, ["delivery"] = true }
access_tags_hierachy = { "hgv", "motor_vehicle", "vehicle", "access" }

--
-- Following ways will be deleted to change routing for 2015
-- Remove this for map update 2016 (or if access:destination is respected again in osrm)
--

ways_to_delete = { ["210337564"] = true, ["4473096"] = true, ["34692847"] = true, ["34692851"] = true, ["84632578"] = true, ["146797257"] = true, ["4471601"] = true, ["4471600"] = true, ["24463383"] = true, ["237897875"] = true, ["184874847"] = true, ["47085444"] = true, ["155432775"] = true, ["377733305"] = true, ["40871380"] = true, ["56475656"] = true, ["69990733"] = true, ["255800753"] = true, ["150301316"] = true, ["77056714"] = true, ["42920665"] = true, ["26244638"] = true, ["40794043"] = true, ["215311114"] = true, ["26492587"] = true, ["256055076"] = true, ["119053038"] = true, ["366552544"] = true }

speed_profile = {
  ["motorway"] = 75,
  ["motorway_link"] = 60,
  ["trunk"] = 60,
  ["trunk_link"] = 45,
  ["primary"] = 45,
  ["secondary"] = 30,
  ["secondary_link"] = 15,
  ["tertiary"] = 15,
  ["tertiary_link"] = 10,
  ["unclassified"] = 10,
  ["residential"] = 8,
  ["living_street"] = 3,
  ["service"] = 3,
  ["default"] = 10
}


traffic_signal_penalty  = 10800


-- these settings are read directly by osrm
obey_oneway             = true
obey_bollards           = true
take_minimum_of_speeds  = false
use_turn_restrictions   = true
u_turn_penalty          = 20
ignore_areas            = true


--[[ preparing nodes --]]
function node_function (node, result)
  
  -- flag node if it carries a traffic light
  local tag = node:get_value_by_key("highway")
  if tag and "traffic_signals" == tag then
    result.traffic_lights = true;
  end

  local maxwidth = numberFromTagValue(node:get_value_by_key("maxwidth"))
  if 0 < maxwidth then
    if maxwidth <= 2.5 then
      result.barrier = true
    end
  end

  local maxheight = numberFromTagValue(node:get_value_by_key("maxheight"))
  if 0 < maxheight then
    if maxheight < 4 then
      result.barrier = true
    end
  end

  local maxweight = numberFromTagValue(node:get_value_by_key("maxweight"))
  if 0 < maxweight then
    if maxweight <= 40 then
      result.barrier = true
    end
  end

  local isBarrier = not isNilOrEmpty(node:get_value_by_key("barrier"))
  if isBarrier then
    result.barrier = true
  end

end

function getAccessFromTagHierarchy(source, hierarchy)
  for i,v in ipairs(hierarchy) do
    local tag = source:get_value_by_key(v)
    if tag and tag ~= '' then
      return tag
    end
  end

  return ""
end

function numberFromTagValue(value)
  if value == nil then
    return 0
  end

  local n = tonumber(value:match("%d.%d*"))
  if n == nil then
    n = 0
  end

  return math.abs(n)
end

function isNilOrEmpty(arg)
  return arg == nil or arg == ""
end

--[[ preparing ways --]]
function way_function (way, result)

  -- 1. use fast fail if it is not possible to route on this way 
  local is_highway = not isNilOrEmpty(way:get_value_by_key("highway"))
  local is_route =   not isNilOrEmpty(way:get_value_by_key("route"))

  local delete_way = ways_to_delete[way:get_value_by_key("id")]


  -- if it is not a route or a highway, then stop here
  if not (is_highway or is_route) or delete_way then
    return
  end

  -- do not route over areas
  local is_area = not isNilOrEmpty(way:get_value_by_key("area"))
  if ignore_areas and is_area then
    local area = way:get_value_by_key("area")
    if "yes" == area then
      return
    end
  end

  -- 2. when its possible to route in this way, add further information for osrm 
  local highway = way:get_value_by_key("highway")
  local oneway = way:get_value_by_key("oneway")
  local junction = way:get_value_by_key("junction")
  local service = way:get_value_by_key("service")

  -- fail fast if highway has no value
  if "" == highway then
    return
  end

  local access = getAccessFromTagHierarchy(way, access_tags_hierachy)
  if access_tag_blacklist[access] then
    return
  end

  local maxwidth = numberFromTagValue(way:get_value_by_key("maxwidth"))
  if 0 < maxwidth then
    if maxwidth <= 2.5 then
      return
    end
  end

  local maxheight = numberFromTagValue(way:get_value_by_key("maxheight"))
  if 0 < maxheight then
    if maxheight < 4 then
      return
    end
  end

  local maxweight = numberFromTagValue(way:get_value_by_key("maxweight"))
  if 0 < maxweight then
    if maxweight <= 40 then
      return
    end
  end

  -- Set access restriction flag if access is allowed under certain restrictions only
  if access ~= "" and access_tag_restricted[access] then
    result.is_access_restricted = true
  end

  -- Set access restriction flag if service is allowed under certain restrictions only
  if service ~= "" and service_tag_restricted[service] then
    result.is_access_restricted = true
  end

  -- Set direction according to tags on way
  if obey_oneway then
    if oneway == "-1" then
      result.forward_mode = 0
    elseif (oneway == "yes" or oneway == "1" or oneway == "true") or junction == "roundabout" or (highway == "motorway_link" and oneway ~="no") or (highway == "motorway" and oneway ~= "no") then
      result.backward_mode = 0
    end
  end

  -- define the speed for the given way
  local speed = speed_profile[highway] or speed_profile['default']
  result.forward_speed = speed
  result.backward_speed = speed

  -- Set the name that will be used for instructions
  local name = way:get_value_by_key("name")
  result.name = name

  -- Override general direction settings of there is a specific one for our mode of travel
  if ignore_in_grid[highway] ~= nil and ignore_in_grid[highway] then
    result.ignore_in_grid = true
  end

  return
end
