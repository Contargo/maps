--[[
      !!!!! Don't touch me, I'm Puppet-managed !!!!!
     please contact admin@synyx.de if you need changes
--]]


--
-- Contargo Truck Profile
--

ignore_in_grid = { ["ferry"] = true }
service_tag_restricted = { ["parking_aisle"] = true }
access_tag_restricted = { ["destination"] = true, ["private"] = true, ["delivery"] = true }
access_tags = { "motorcar" }

--
-- Following ways will be deleted to change routing for 2015
-- Remove this for map update 2016 (or if access:destination is respected again in osrm)
--

ways_to_delete = { ["210337564"] = true, ["4473096"] = true, ["34692847"] = true, ["34692851"] = true, ["84632578"] = true, ["146797257"] = true, ["4471601"] = true, ["4471600"] = true, ["24463383"] = true, ["237897875"] = true }

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
function node_function (node)
  
  -- flag node if it carries a traffic light
  if node.tags:Holds("highway") then
    if node.tags:Find("highway") == "traffic_signals" then
      node.traffic_light = true;
    end
  end

  -- barrier tags
  if node.tags:Holds("barrier") then
    node.bollard = true
  end

end


--[[ preparing ways --]]
function way_function (way)



  -- 1. use fast fail if it is not possible to route on this way 
  local is_highway = way.tags:Holds("highway")
  local is_route = way.tags:Holds("route")

  local delete_way = ways_to_delete[way.tags:Find("id")]


  -- if it is not a route or a highway, then stop here
  if not (is_highway or is_route) or delete_way then
    return
  end

  -- do not route over areas
  local is_area = way.tags:Holds("area")
  if ignore_areas and is_area then
    local area = way.tags:Find("area")
    if "yes" == area then
      return
    end
  end

  -- 2. when its possible to route in this way, add further information for osrm 
  local highway = way.tags:Find("highway")
  local oneway = way.tags:Find("oneway")
  local junction = way.tags:Find("junction")
  local service = way.tags:Find("service")
  local access = way.tags:Find("access")

  -- fail fast if highway has no value
  if "" == highway then
    return
  end

  -- Set access restriction flag if access is allowed under certain restrictions only
  if access ~= "" and access_tag_restricted[access] then
    way.is_access_restricted = true
  end

  -- Set access restriction flag if service is allowed under certain restrictions only
  if service ~= "" and service_tag_restricted[service] then
    way.is_access_restricted = true
  end

  -- Set direction according to tags on way
  if obey_oneway then
    if oneway == "-1" then
      way.forward_mode = 0
    elseif (oneway == "yes" or oneway == "1" or oneway == "true") or junction == "roundabout" or (highway == "motorway_link" and oneway ~="no") or (highway == "motorway" and oneway ~= "no") then
      way.backward_mode = 0
    end
  end

  -- define the speed for the given way
  local speed = speed_profile[highway] or speed_profile['default']
  way.forward_speed = speed
  way.backward_speed = speed

  -- Set the name that will be used for instructions
  local name = way.tags:Find("name")
  way.name = name

  -- Override general direction settings of there is a specific one for our mode of travel
  if ignore_in_grid[highway] ~= nil and ignore_in_grid[highway] then
    way.ignore_in_grid = true
  end

  return
end

-- These are wrappers to parse vectors of nodes and ways and thus to speed up any tracing JIT
function node_vector_function(vector)
  for v in vector.nodes do
    node_function(v)
  end
end
