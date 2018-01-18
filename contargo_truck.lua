api_version = 2

Set = require('lib/set')
Sequence = require('lib/sequence')
Handlers = require("lib/way_handlers")
find_access_tag = require("lib/access").find_access_tag
limit = require("lib/maxspeed").limit
ContargoWayHandlers = require('contargo_way_handlers')

function setup()
  local use_left_hand_driving = false
  return {
    properties = {
      max_speed_for_map_matching     = 180/3.6,       -- 180kmph -> m/s
      left_hand_driving              = use_left_hand_driving,
      weight_name                    = 'routability', -- routing based on duration, but weighted for preferring certain roads
      process_call_tagless_node      = false,
      u_turn_penalty                 = 20,
      continue_straight_at_waypoint  = true,
      use_turn_restrictions          = true,
      traffic_light_penalty          = 2,
      swiss_border_penalty           = 10800,         -- 3 hours
      swiss_border_weight            = 500000,
      access_destination_weight      = 100000
    },

    default_mode              = mode.driving,
    default_speed             = 10,
    oneway_handling           = true,
    side_road_multiplier      = 0.8,
    turn_penalty              = 7.5,
    turn_bias   = use_left_hand_driving and 1/1.075 or 1.075, -- biases right-side driving

    suffix_list = { -- a list of suffixes to suppress in name change instructions
      'N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW', 'North', 'South', 'West', 'East'
    },

    barrier_whitelist = Set {
    },

    access_tag_whitelist = Set {
      'yes',
      'hgv',
      'motor_vehicle',
      'vehicle',
      'permissive',
      'designated',
      'hov'
    },

    access_tag_blacklist = Set {
      'no',
      'private',
      'delivery',
      'destination'
    },

    restricted_access_tag_list = Set {
      'destination',
      'delivery',
      'private'
    },

    access_tags_hierarchy = Sequence {
      'hgv',
      'motor_vehicle',
      'vehicle',
      'access'
    },

    service_tag_forbidden = Set {
      'emergency_access'
    },

    restrictions = Sequence {
      'hgv',
      'motor_vehicle',
      'vehicle'
    },

    avoid = Set {
      'area',
      'reversible',
      'impassable',
      'hov_lanes',
      'steps',
      'construction',
      'proposed'
    },

    speeds = Sequence {
      highway = {
        motorway        = 75,
        motorway_link   = 60,
        trunk           = 60,
        trunk_link      = 45,
        primary         = 45,
        primary_link    = 40,
        secondary       = 30,
        secondary_link  = 15,
        tertiary        = 15,
        tertiary_link   = 10,
        unclassified    = 10,
        residential     = 8,
        living_street   = 3,
        service         = 3
      }
    },

    service_penalties = {},

    restricted_highway_whitelist = Set {
      'motorway',
      'motorway_link',
      'trunk',
      'trunk_link',
      'primary',
      'primary_link',
      'secondary',
      'secondary_link',
      'tertiary',
      'tertiary_link',
      'residential',
      'living_street'
    },

    construction_whitelist = Set {
      'no',
      'widening',
      'minor'
    },

    route_speeds = {
      ferry = 0,
      shuttle_train = 0
    },

    bridge_speeds = {
      movable = 5
    },

    ways_to_delete = Set {
      '255800753',
      '26244638',
      '42920665',
      '26492587',
      '215311114',
      '119053038',
      '210337564',
      '4473096',
      '34692847',
      '34692851',
      '146797257',
      '4471601',
      '4471600',
      '24463383',
      '237897875',
      '47085444'
    }
  }
end

function process_node(profile, node, result)
  -- parse barrier tags
  local barrier = node:get_value_by_key("barrier")
  if barrier then
    result.barrier = true
  end

  -- check if node is a traffic light
  local tag = node:get_value_by_key("highway")
  if "traffic_signals" == tag then
    result.traffic_lights = true
  end

  local maxwidth = ContargoWayHandlers.numberFromTagValue(node:get_value_by_key("maxwidth"))
  if 0 < maxwidth then
    if maxwidth <= 2.5 then
      result.barrier = true
    end
  end

  local maxheight = ContargoWayHandlers.numberFromTagValue(node:get_value_by_key("maxheight"))
  if 0 < maxheight then
    if maxheight < 4 then
      result.barrier = true
    end
  end

  local maxweight = ContargoWayHandlers.numberFromTagValue(node:get_value_by_key("maxweight"))
  if 0 < maxweight then
    if maxweight <= 40 then
      result.barrier = true
    end
  end
end

function process_way(profile, way, result)
  -- data table for storing intermediate values during processing
  local data = {
    highway = way:get_value_by_key('highway'),
    bridge = way:get_value_by_key('bridge'),
    route = way:get_value_by_key('route'),
    crossing = way:get_value_by_key('crossing'),
    access = way:get_value_by_key('access')
  }

  -- perform an quick initial check and abort if the way is obviously not routable
  -- highway or route tags must be in data table, bridge is optional
  if (not data.highway or data.highway == '') and (not data.route or data.route == '') then
    return
  end

  handlers = Sequence {
    WayHandlers.default_mode,
    ContargoWayHandlers.delete_way,
    WayHandlers.blocked_ways,
    ContargoWayHandlers.width_height_weight,
    WayHandlers.access,
    WayHandlers.oneway,
    WayHandlers.destinations,
    WayHandlers.ferries,
    WayHandlers.movables,
    WayHandlers.service,
    WayHandlers.speed,
    WayHandlers.penalties,
    WayHandlers.classes,
    WayHandlers.turn_lanes,
    WayHandlers.classification,
    WayHandlers.roundabouts,
    WayHandlers.startpoint,
    WayHandlers.names,
    WayHandlers.weights,
    ContargoWayHandlers.verkehrsverbot,
    ContargoWayHandlers.access_destination,
    ContargoWayHandlers.swiss_border
  }

  WayHandlers.run(profile,way,result,data,handlers)
end

function process_turn(profile, turn)
  -- Use a sigmoid function to return a penalty that maxes out at turn_penalty
  -- over the space of 0-180 degrees.  Values here were chosen by fitting
  -- the function to some turn penalty samples from real driving.
  local turn_penalty = profile.turn_penalty
  local turn_bias = profile.turn_bias

  if turn.has_traffic_light then
      turn.duration = profile.properties.traffic_light_penalty
  end

  if turn.turn_type ~= turn_type.no_turn then
    if turn.angle >= 0 then
      turn.duration = turn.duration + turn_penalty / (1 + math.exp( -((13 / turn_bias) *  turn.angle/180 - 6.5*turn_bias)))
    else
      turn.duration = turn.duration + turn_penalty / (1 + math.exp( -((13 * turn_bias) * -turn.angle/180 - 6.5/turn_bias)))
    end

    if turn.direction_modifier == direction_modifier.u_turn then
      turn.duration = turn.duration + profile.properties.u_turn_penalty
    end
  end

  -- for distance based routing we don't want to have penalties based on turn angle
  if profile.properties.weight_name == 'distance' then
     turn.weight = 0
  else
     turn.weight = turn.duration
  end

  if profile.properties.weight_name == 'routability' then
      -- penalize turns from non-local access only segments onto local access only tags
      if not turn.source_restricted and turn.target_restricted then
          turn.weight = constants.max_turn_weight
      end
  end
end

return {
  setup = setup,
  process_way = process_way,
  process_node = process_node,
  process_turn = process_turn
}
