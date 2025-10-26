# Logstash Helper Scripts
A directory of scripts that can be beneficial for logstash development, git pre-/post-commits, etc.

## lint.py
Basic linting of a Logstash pipeline config:
    - Ensures matching number of curly braces `{}`
    - Checks for duplicate plugin ids

### Usage
`python lint.py /path/to/config.conf`

```
Line 23: Duplicate ID 'hoist_foo' found at:
    Line 23: id => "hoist_foo"
    Line 50: id => "hoist_foo"
```

## pipeline-too.l.py
A tool that can be used to split a complex pipeline into reusable (`input`, `filter`, and `output`) component for reusability or running pipelines using glob expressions.
Additionally, a folder of split component can be joined together to a single pipeline file.

### Usage
`python pipeline-tool help`

```
Usage:
  pipeline-tool split <pipeline.conf> [output_dir]
  pipeline-tool join [input_dir] [output_file]

Examples:
  pipeline-tool split pipeline.conf parts/
  pipeline-tool join parts/ pipeline.conf
```