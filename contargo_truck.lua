--[[
      !!!!! Don't touch me, I'm Puppet-managed !!!!!
     please contact admin@synyx.de if you need changes
--]]


--
-- Contargo Truck Profile
--

ignore_in_grid = { ["ferry"] = true }
service_tag_restricted = { ["parking_aisle"] = true }

access_tag_blacklist = { ["no"] = true }
access_tag_restricted = { ["destination"] = true, ["private"] = true, ["delivery"] = true }
access_tags_hierachy = { "hgv", "motor_vehicle", "vehicle", "access" }

--
-- Following ways will be deleted
--

ways_to_delete = { ["255800753"] = true, ["26244638"] = true, ["42920665"] = true, ["26492587"] = true, ["215311114"] = true, ["119053038"] = true, ["210337564"] = true, ["4473096"] = true, ["34692847"] = true, ["34692851"] = true, ["146797257"] = true, ["4471601"] = true, ["4471600"] = true, ["24463383"] = true, ["237897875"] = true, ["47085444"] = true }

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


properties.traffic_signal_penalty  = 2
properties.use_turn_restrictions   = true
properties.weight_name             = 'duration'
properties.u_turn_penalty          = 20

local access_destination_weight = 100000
local swiss_border_penalty      = 10800 -- 3 hours

-- these settings are read directly by osrm
local obey_oneway             = true
local ignore_areas            = true
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
  local crossing = way:get_value_by_key("crossing")

  result.forward_mode = mode.driving
  result.backward_mode = mode.driving

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
  local way_id = way:get_value_by_key("id")
  if 0 < maxweight then
    -- Do not set restriction for Schmickbruecke
    if maxweight <= 40 and way_id ~= "371493267" then
      return
    end
  end

  if access ~= "" and access_tag_restricted[access] then
    result.weight = access_destination_weight
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

  if crossing == "border" then
    result.duration = swiss_border_penalty
  else
    -- define the speed for the given way
    local speed = speed_profile[highway] or speed_profile['default']
    result.forward_speed = speed
    result.backward_speed = speed
  end

  -- Set the name that will be used for instructions
  local name = way:get_value_by_key("name")
  result.name = name

  -- Override general direction settings of there is a specific one for our mode of travel
  if ignore_in_grid[highway] ~= nil and ignore_in_grid[highway] then
    result.ignore_in_grid = true
  end

  return
end
