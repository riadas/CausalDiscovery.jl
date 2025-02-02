function find_state_update_events(event_vector_dict, augmented_positive_times, time_ranges, start_value, end_value, global_var_dict, global_var_id, global_var_value) 
  co_occurring_events = find_state_update_events_false_positives(event_vector_dict, augmented_positive_times, time_ranges, start_value, end_value, global_var_dict, global_var_id, global_var_value)
  matches = map(x -> (x[1], x[3]), filter(tuple -> tuple[2] == 0, co_occurring_events))
  sort(matches, by=x -> length(x))
end

function find_state_update_events_false_positives(orig_event_vector_dict, augmented_positive_times, time_ranges, start_value, end_value, global_var_dict, global_var_id, global_var_value, object_specific=false)
  @show global_var_dict

  if object_specific
    event_vector_dict = orig_event_vector_dict
  else
    event_vector_dict = Dict()

    for event in filter(e -> (orig_event_vector_dict[e] isa Array) && !occursin("globalVar", e), collect(keys(orig_event_vector_dict)))
      event_vector_dict[event] = orig_event_vector_dict[event]
    end
  
    for event in filter(e -> !(orig_event_vector_dict[e] isa Array) && !occursin("globalVar", e) && occursin("id) x", e), collect(keys(orig_event_vector_dict)))
      for i in keys(orig_event_vector_dict[event])  
        event_vector_dict[replace(event, "id) x" => "id) $(i)")] = orig_event_vector_dict[event][i]
      end
    end
  end

  co_occurring_events = []
  @show collect(keys(event_vector_dict))
  for event in sort(collect(keys(event_vector_dict)), by=length) 
    event_vector = event_vector_dict[event]
    event_times = findall(x -> x == 1, event_vector)
    if time_ranges == []
      if event_times == [] || augmented_positive_times == [] || (end_value == augmented_positive_times[1][2])
        push!(co_occurring_events, (event, 0, [], []))
        push!(co_occurring_events, ("(& $(event) (== globalVar$(global_var_id) $(start_value)))", 0, [], []))
      elseif start_value != augmented_positive_times[1][2]
        push!(co_occurring_events, ("(& $(event) (== globalVar$(global_var_id) $(start_value)))", 0, [], []))
      end
    else
      if !(0 in map(time_range -> length(findall(time -> ((time >= time_range[1]) && (time <= time_range[2])), event_times)) > 0, time_ranges))
        @show event
        # co-occurring event found      
        # compute number of false positives 
        co_occurring_times = [event_times[i] for i in vcat(map(time_range -> findall(time -> ((time >= time_range[1]) && (time <= time_range[2])), event_times), time_ranges)...)]
        false_positive_times = [time for time in event_times if !(time in co_occurring_times)]
  
        # find closest event in the future; if value matches end_value, not a false_positive event!
        desired_end_values = []
        desired_start_values = []
        for time in false_positive_times 
          # handle end value
        
          if ((time == length(global_var_dict[global_var_id])) && (global_var_dict[global_var_id][time] < global_var_value)) || ((time < length(global_var_dict[global_var_id])) && (global_var_dict[global_var_id][time + 1] < global_var_value))
            desired_end_value = ((time + 1) > length(global_var_dict[global_var_id])) ? global_var_dict[global_var_id][time] : global_var_dict[global_var_id][time + 1]
            push!(desired_end_values, desired_end_value)
          elseif (time >= maximum(map(tuple -> tuple[1], augmented_positive_times)))
            desired_end_value = -1 # augmented_positive_times[end][2]
            push!(desired_end_values, desired_end_value)
          else
            future_augmented_positive_times = filter(tuple -> tuple[1] > time, augmented_positive_times)
            closest_future_augmented_time = future_augmented_positive_times[1]
            push!(desired_end_values, closest_future_augmented_time[2])
          end
  
          # handle start value 
          if (time < minimum(map(tuple -> tuple[1], augmented_positive_times))) || global_var_dict[global_var_id][time] < global_var_value 
            desired_start_value = global_var_dict[global_var_id][time]
            push!(desired_start_values, desired_start_value)
          elseif (time < minimum(map(tuple -> tuple[1], augmented_positive_times)))
            desired_start_value = augmented_positive_times[1][2] # -1
            push!(desired_start_values, desired_start_value)
          else
            earlier_augmented_positive_times = filter(tuple -> tuple[1] <= time, augmented_positive_times)
            closest_earlier_augmented_time = earlier_augmented_positive_times[end]
            push!(desired_start_values, closest_earlier_augmented_time[2])
          end
  
        end
        num_false_positives_with_effects = count(x -> x != end_value && x != -1, desired_end_values)
        false_positive_with_effects_times = [false_positive_times[i] for i in findall(v -> v != end_value && v != -1, desired_end_values)]
        no_effect_times = [false_positive_times[i] for i in findall(v -> v == end_value || v == -1, desired_end_values)]
        push!(co_occurring_events, (event, 
                                    num_false_positives_with_effects, 
                                    [co_occurring_times..., no_effect_times...], 
                                    false_positive_with_effects_times))
        # (tuple structure: (event, # of false positives, list of correct event times, list of false positive event times ))
        
        zipped_values = [(desired_start_values[i], desired_end_values[i]) for i in 1:length(desired_end_values)]
        num_false_positives_with_effects_state = count(x -> !(x[2] in [end_value, -1]) && (x[1] == start_value), zipped_values)
        false_positives_with_effects_state_times = [false_positive_times[i] for i in findall(x -> !(x[2] in [end_value, -1]) && (x[1] == start_value), zipped_values)]
        push!(co_occurring_events, ("(& $(event) (== (prev globalVar$(global_var_id)) $(start_value)))", 
                                    num_false_positives_with_effects_state, 
                                    [co_occurring_times..., [false_positive_times[i] for i in findall(x -> (x[2] in [end_value, -1]) && (x[1] == start_value), zipped_values)]...], 
                                    false_positives_with_effects_state_times))
      end  
    end
  end
  @show co_occurring_events
  co_occurring_events = sort(co_occurring_events, by=x->x[2])

  # among events with minimum # of false positives, sort by length of event (i.e. so "left" appears before "& left (== globalVar1 1)")
  if co_occurring_events == [] 
    []
  else
    min_false_positives = co_occurring_events[1][2]
    min_false_positive_events = sort(filter(e -> e[2] == min_false_positives, co_occurring_events), by=x->length(x[1]))
    other_events = filter(e -> e[2] != min_false_positives, co_occurring_events)
    co_occurring_events = vcat(min_false_positive_events, other_events)
  end
end

function group_ranges(ranges)
  dict = Dict()

  for range in ranges
    start_time = range[1][1]
    start_value = range[1][2]

    end_time = range[2][1] - 1
    end_value = range[2][2]

    if !((start_value, end_value) in keys(dict))
      dict[(start_value, end_value)] = [range] 
    else
      push!(dict[(start_value, end_value)], range)
    end
  end

  grouped_ranges = sort(map(k -> dict[k], collect(keys(dict))), by=group->group[1][1][1]) # sort by first start time in each group
  grouped_ranges 
end

function group_ranges(ranges_dict::Dict)
  ranges = vcat(filter(x -> length(x) > 0, vcat(map(id -> map(range -> ((range[1][1], range[1][2], id), (range[2][1], range[2][2], id)), ranges_dict[id]), collect(keys(ranges_dict)))))...)
  group_ranges(ranges)
end

function find_state_update_events_object_specific(event_vector_dict, augmented_positive_times_dict, grouped_range, object_ids, object_mapping, max_state_value)
  # extract object-specific events 
  events = filter(e -> !(event_vector_dict[e] isa AbstractArray) && sort(collect(keys(event_vector_dict[e]))) == sort(object_ids), collect(keys(event_vector_dict))) 
  global_events = filter(e -> event_vector_dict[e] isa Array, collect(keys(event_vector_dict)))

  update_events_dict = Dict()
  for object_id in object_ids 
    object_event_vector_dict = Dict()
    for event in events 
      object_event_vector_dict[event] = event_vector_dict[event][object_id]
    end

    augmented_positive_times = augmented_positive_times_dict[object_id]

    time_ranges = map(range -> (range[1][1], range[2][1]), filter(r -> r[1][3] == object_id, grouped_range))

    start_value = grouped_range[1][1][2]
    end_value = grouped_range[1][2][2]

    if "field1" in map(x -> x[1], filter(obj -> !isnothing(obj), object_mapping[object_id])[1].type.custom_fields)
      custom_field_index = findall(field_tuple -> field_tuple[1] == "field1", filter(obj -> !isnothing(obj), object_mapping[object_ids[1]])[1].type.custom_fields)[1]
      object_var_dict = Dict(1 => map(obj -> isnothing(obj) ? -1 : obj.custom_field_values[custom_field_index], object_mapping[object_id])[1:end-1])
    else
      object_var_dict = Dict(1 => ones(Int, length(event_vector_dict[global_events[1]])))
    end
    object_var_value = max_state_value
    
    # @show object_id
    # @show object_event_vector_dict
    # @show augmented_positive_times 
    # @show time_ranges 
    # @show start_value 
    # @show end_value 
    update_events = find_state_update_events(object_event_vector_dict, augmented_positive_times, time_ranges, start_value, end_value, object_var_dict, 1, object_var_value)
    
    update_events_dict[object_id] = update_events
  end
  @show update_events_dict
  common_events = intersect(map(id -> map(x -> x[1], update_events_dict[id]), object_ids)...)
  if common_events == [] 
    # FAILURE CASE
    []
  else
    common_event = common_events[1]
    event_times = []
    for object_id in object_ids 
      object_event_times = filter(event_tuple -> event_tuple[1] == common_event, update_events_dict[object_id])[1][2]
      augmented_times = map(time -> (time, object_id), object_event_times)
      event_times = vcat(event_times..., augmented_times...)
    end
    [(common_event, event_times)]  
  end

end

function is_co_occurring(event, event_vector, update_function_times)  
  event_times = findall(x -> x == 1, event_vector)
  if repr(sort(intersect(event_times, update_function_times))) == repr(sort(update_function_times))
    true
  else
    false
  end
end

function num_false_positives(event_vector, update_function_times)
  event_times = findall(x -> x == 1, event_vector)
  length([ time for time in event_times if !(time in update_function_times) ])
end