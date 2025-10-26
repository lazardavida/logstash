# Logstash Hoist Filter Plugin

This is a filter plugin for [Logstash](https://github.com/elastic/logstash) that hoists nested properties to the root level of events.

## Description

The hoist filter takes properties from a nested object and copies them to the root level of the event.

### Example

Input event:
```json
{
    "nested": {
        "field1": "value1",
        "field2": "value2"
    }
}
```

Output event:
```json
{
    "nested": {
        "field1": "value1",
        "field2": "value2"
    },
    "field1": "value1",
    "field2": "value2"
}
```

## Configuration Options

| Setting | Input type | Required | Default |
|---------|------------|----------|---------|
| source | string | Yes | - |
| remove_source | boolean | No | false |
| overwrite | boolean | No | false |

### source
* Value type is string
* Required
* Specifies the field containing the object to hoist from

### remove_source
* Value type is boolean
* Default value is false
* When true, removes the source field after hoisting its properties

### overwrite
* Value type is boolean
* Default value is false
* When true, allows overwriting of existing fields

## Usage Examples

Basic usage:
```ruby
filter {
  hoist {
    source => "nested"
  }
}
```

Remove source field after hoisting:
```ruby
filter {
  hoist {
    source => "nested"
    remove_source => true
  }
}
```

Allow overwriting existing fields:
```ruby
filter {
  hoist {
    source => "nested"
    overwrite => true
  }
}
```

## Error Handling

The plugin will tag events with `_hoisterror` in these cases:
- Source field exists but is not a Hash/Object
- Source field contains properties that would overwrite existing fields (when `overwrite` is false)

## Development


### Setup

2. Install dependencies:
```sh
bundle install
```

### Building
Build the gem:
```sh
gem build logstash-filter-hoist.gemspec
```

### Installing into Logstash
```sh
# From Logstash home directory
bin/logstash-plugin install --no-verify /path/to/logstash-filter-hoist-0.1.0.gem
```