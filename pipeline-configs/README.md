# Logstash Example Configs
A place to store some example configs for interesting Logstash uses

## event_time_tracking.conf
To monitor how long it takes for an event to be received by Logstash and tracking potentially inefficient pipeline Logic, call the provided [ruby script](event_time_tracking.rb) which will keep track of the order of when the ruby script was called (named `step_field`) in the root-level `tracking_field` and store the timestamp at the time ruby script was ran. A time delta against all other `step_fields` is then calculated to understand slowdowns in the pipeline. Further, a `timestamp_field` can be provided to override the current date/time for the step (useful for when first receiving an event and tracking when the event occured vs when Logstash received it).


## filter-hoist.conf
A test script for using the [logstash-filter-hoist](../plugins/logstash-filter-hoist/) custom plugin

## ruby-hoist.conf
A ruby-based example of hoisting objects from their parents