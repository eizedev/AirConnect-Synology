"""
Give each run in a SARIF file a distinct automationDetails.id.

Codacy's analysis CLI emits one results.sarif containing a separate SARIF
"run" per underlying tool (pylint, shellcheck, ...), none of which set
automationDetails.id. Since 2025-07-22 github/codeql-action/upload-sarif
rejects a file with multiple runs that resolve to the same category
instead of merging them (see
https://github.blog/changelog/2025-07-21-code-scanning-will-stop-combining-multiple-sarif-runs-uploaded-in-the-same-sarif-file/),
so the upload step in codacy-analysis.yml started failing outright.

automationDetails.id, where present, takes precedence over the upload
action's own --category flag, so setting it per run here is enough on its
own - no matching category input needed on the upload-sarif step.
"""

import json
import sys


def main():
    """CLI entry point: sarif_categorize.py <in.sarif> <out.sarif>."""
    if len(sys.argv) != 3:
        print(f"Usage: {sys.argv[0]} <in.sarif> <out.sarif>", file=sys.stderr)
        sys.exit(2)

    path_in, path_out = sys.argv[1], sys.argv[2]
    with open(path_in, encoding="utf-8") as f:
        sarif = json.load(f)

    seen = {}
    for run in sarif.get("runs", []):
        tool_name = run.get("tool", {}).get("driver", {}).get("name", "unknown")
        seen[tool_name] = seen.get(tool_name, 0) + 1
        suffix = "" if seen[tool_name] == 1 else f"-{seen[tool_name]}"
        run["automationDetails"] = {"id": f"codacy/{tool_name}{suffix}"}

    with open(path_out, "w", encoding="utf-8") as f:
        json.dump(sarif, f)


if __name__ == "__main__":
    main()
