require "logstash/filters/base"
require "logstash/namespace"

# This filter hoists nested properties to the root level of the event.
# { "parent": { "child": "value" } }
# becomes:
# { "parent": { "child": "value" }, "child": "value" }
class LogStash::Filters::Hoist < LogStash::Filters::Base

  config_name "hoist"
  
  # Specify the field containing the object to hoist from
  config :source, :validate => :string, :required => true
  
  # Specify whether to remove the source field after hoisting
  config :remove_source, :validate => :boolean, :default => false
  
  # Specify whether to overwrite existing fields
  config :overwrite, :validate => :boolean, :default => false

  public
  def register
    # Nothing to do
  end

  public
  def filter(event)
    return unless event.include?(@source)
    
    source_data = event.get(@source)
    
    unless source_data.is_a?(Hash)
      event.tag("_hoisterror")
      return
    end
    
    would_overwrite = []
    
    # First pass - check which fields would be overwritten
    source_data.each do |key, value|
      would_overwrite << key if event.include?(key)
    end
    
    # Tag event if we would overwrite and overwrite is false
    if !would_overwrite.empty? && !@overwrite
      event.tag("_hoisterror")
    end
    
    # Second pass - set fields and build new source data
    if @remove_source && !@overwrite && !would_overwrite.empty?
      # Create new source with only the fields that would overwrite
      new_source = {}
      would_overwrite.each do |key|
        new_source[key] = source_data[key]
      end
      event.set(@source, new_source)
      
      # Only copy fields that won't overwrite
      source_data.each do |key, value|
        event.set(key, value) unless would_overwrite.include?(key)
      end
    else
      # Original behavior
      source_data.each do |key, value|
        if !event.include?(key) || @overwrite
          event.set(key, value)
        end
      end
      
      event.remove(@source) if @remove_source
    end
    
    # filter_matched should go in the last line of our successful code
    filter_matched(event)
  end
end