#!/usr/bin/env python3
import sys
import os
from lint import LogstashLinter

def split_pipeline(pipeline_path, output_dir="."):
    """
    Splits a Logstash pipeline configuration file into separate files for each section (input, filter, output).

    Args:
        pipeline_path (str): Path to the pipeline configuration file to split.
        output_dir (str): Directory where the split configuration files will be saved. Defaults to the current directory.

    The function creates separate files for each section, naming them as <section>_<index>.conf.
    """
    with open(pipeline_path, "r", encoding="utf-8") as f:
        os.makedirs(output_dir, exist_ok=True)
        current_config = ""
        counters = {"input": 0, "filter": 0, "output": 0}
        current_section = None

        def save_section():
            """ Helper function to save the current section to a file """
            if current_section:
                fname = f"{current_section}_{counters[current_section]}.conf"
                with open(os.path.join(output_dir, fname), "w", encoding="utf-8") as out:
                    out.write(current_config.rstrip())  # Remove trailing newlines before saving
                    print(f"Wrote {fname}")
                counters[current_section] += 1

        for line in f:
            line_stripped = line.strip()
            if line_stripped.startswith(("input", "filter", "output")):
                save_section()
                current_section = line_stripped.split()[0]
                current_config = line
            else:
                if current_section:
                    current_config += line

        save_section()


def join_pipeline(input_dir=".", output_file="pipeline.conf"):
    """ Joins separate Logstash configuration files from a directory into a single pipeline configuration file """
    files = sorted(
        [f for f in os.listdir(input_dir) if f.endswith(".conf")],
        key=lambda x: (x.split("_")[0], x)
    )

    sections = {"input": [], "filter": [], "output": []}

    for fname in files:
        ftype = fname.split("_")[0]
        if ftype in sections:
            with open(os.path.join(input_dir, fname), "r", encoding="utf-8") as f:
                sections[ftype].append(f.read().strip())

    output = []
    for section in ["input", "filter", "output"]:
        if sections[section]:
            body = "\n\n".join(sections[section])
            output.append(body)

    with open(output_file, "w", encoding="utf-8") as out:
        out.write("\n\n".join(output))
    print(f"Wrote {output_file}")
    print("Running linter on the joined configuration...")
    LogstashLinter(output_file).print_results()


def usage():
    """ Prints usage information for the pipeline-tool script """
    print("Usage:")
    print("  pipeline-tool split <pipeline.conf> [output_dir]")
    print("  pipeline-tool join [input_dir] [output_file]")
    print("")
    print("Examples:")
    print("  pipeline-tool split pipeline.conf parts/")
    print("  pipeline-tool join parts/ pipeline.conf")

def main():
    if len(sys.argv) < 2:
        usage()
        return

    cmd = sys.argv[1]

    if cmd == "split" and len(sys.argv) >= 3:
        pipeline_path = sys.argv[2]
        output_dir = sys.argv[3] if len(sys.argv) >= 4 else "."
        split_pipeline(pipeline_path, output_dir)
    elif cmd == "join":
        input_dir = sys.argv[2] if len(sys.argv) >= 3 else "."
        output_file = sys.argv[3] if len(sys.argv) >= 4 else "pipeline.conf"
        join_pipeline(input_dir, output_file="pipeline.conf")
    else:
        usage()

if __name__ == "__main__":
    main()