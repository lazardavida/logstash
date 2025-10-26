import sys
import re
from collections import defaultdict
from pathlib import Path

class LogstashLinter:
    def __init__(self, config_path):
        self.config_path = Path(config_path)
        self.errors = []
        self.warnings = []
        self.filter_ids = defaultdict(list)
        self.plugin_counts = defaultdict(int)

        self.lint()

    def load_config(self):
        """Load the config file content"""
        try:
            with open(self.config_path, 'r') as f:
                return f.read()
        except Exception as e:
            # Add line number 0 for file-level errors
            self.errors.append((f"Failed to load config file: {e}", 0))
            return None

    def check_duplicate_ids(self, content):
        """Check for duplicate filter IDs"""
        # This should be a sufficient match ...
        id_pattern = r'id\s*=>\s*(["\']?)([^"\'\s}]+)\1'
        matches = re.finditer(id_pattern, content, re.MULTILINE)
        
        for match in matches:
            plugin_id = match.group(2)  # Group 2 contains the ID value
            line_num = content.count('\n', 0, match.start()) + 1
            line_content = content[match.start():content.find('\n', match.start())].strip()
            self.filter_ids[plugin_id].append((line_num, line_content))
        
        for plugin_id, occurrences in self.filter_ids.items():
            if len(occurrences) > 1:
                lines_info = []
                first_line = occurrences[0][0]  # Get the first occurrence's line number
                for line_num, line_content in occurrences:
                    lines_info.append(f"\n    Line {line_num}: {line_content}")
                self.errors.append((f"Duplicate ID '{plugin_id}' found at:{' '.join(lines_info)}", first_line))

    def check_syntax(self, content):
        """Basic syntax checking"""
        # Check for balanced braces
        open_braces = content.count('{')
        close_braces = content.count('}')
        if open_braces != close_braces:
            self.errors.append((f"Unbalanced braces: {open_braces} open, {close_braces} close", 0))

    def lint(self):
        """Run all lint checks"""
        content = self.load_config()
        if not content:
            return False

        self.check_duplicate_ids(content)
        self.check_syntax(content)

    def print_results(self):
        """Print lint results"""
        if self.errors:
            print("\nErrors:")
            for error_msg, line_num in self.errors:
                if line_num > 0:
                    print(f"Line {line_num}: {error_msg}")
                else:
                    print(f"{error_msg}")

        if self.warnings:
            print("\nWarnings:")
            for warning_msg, line_num in self.warnings:
                if line_num > 0:
                    print(f"Line {line_num}: {warning_msg}")
                else:
                    print(f"{warning_msg}")

        if not self.errors and not self.warnings:
            print("No issues found")

def main():
    if len(sys.argv) != 2:
        print("Usage: python3 lint.py <path-to-logstash-config>")
        sys.exit(1)

    linter = LogstashLinter(sys.argv[1])
    linter.print_results()

if __name__ == "__main__":
    main()