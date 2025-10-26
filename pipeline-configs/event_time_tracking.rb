def register(params)
    @tracking_field   = params["tracking_field"]      # e.g., "timestamps"
    @step_field       = params["step_field"]          # e.g., "event_processed"
    @timestamp_value  = params["timestamp_value"]     # optional static default
    @timestamp_field  = params["timestamp_field"]     # e.g., "[@metadata][custom_time]"
  end
  
  def parse_time(val)
    case val
    when nil
      nil
    when LogStash::Timestamp
      val.time.utc
    when Numeric
      # treat large numbers as ms, otherwise seconds
      val > 2_000_000_000 ? Time.at(val / 1000.0).utc : Time.at(val.to_f).utc
    when String
      require "time"
      begin
        Time.iso8601(val).utc
      rescue
        begin
          Time.parse(val).utc
        rescue
          nil
        end
      end
    else
      nil
    end
  end
  
  def filter(event)
    # ensure tracking object exists
    unless event.get("[#{@tracking_field}]")
      event.set("[#{@tracking_field}]", {})
    end
  
    # resolve timestamp value (dynamic field → static value → now)
    ts_value =
      if @timestamp_field
        event.get(@timestamp_field) || @timestamp_value || Time.now.utc.iso8601
      else
        @timestamp_value || Time.now.utc.iso8601
      end
  
    # pull existing order BEFORE appending the new step
    order_path  = "[#{@tracking_field}][order]"
    prior_order = event.get(order_path) || []
    prior_order = prior_order.is_a?(Array) ? prior_order : [prior_order]
  
    # set/update the timestamp for the current step
    event.set("[#{@tracking_field}][#{@step_field}]", ts_value)
  
    # calc deltas: current step vs each prior step in order (ms)
    now_t = parse_time(ts_value)
    if now_t
      prior_order.each do |prev_step|
        prev_ts_val = event.get("[#{@tracking_field}][#{prev_step}]")
        prev_t = parse_time(prev_ts_val)
        next unless prev_t
  
        delta_ms = ((now_t - prev_t) * 1000.0).round
        delta_field_path = "[#{@tracking_field}][#{@step_field}-since_#{prev_step}]"
        event.set(delta_field_path, delta_ms)
      end
    else
      event.tag("_ts_delta_unparseable_current_time")
    end
  
    # append current step to order
    new_order = prior_order + [@step_field]
    event.set(order_path, new_order)
  
    [event]
  end
  