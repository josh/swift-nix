import urllib.request
import json
import subprocess


def fetch_update_checkout_config():
    url = "https://raw.githubusercontent.com/swiftlang/swift/main/utils/update_checkout/update-checkout-config.json"
    with urllib.request.urlopen(url) as response:
        content = response.read()
    return json.loads(content)


def update_sources_json(version, repo, obj):
    sources = json.load(open("sources.json"))
    if version not in sources:
        sources[version] = {}
    sources[version][repo] = obj
    with open("sources.json", "w") as f:
        json.dump(sources, f, indent=2)
        f.write("\n")


checkouts = fetch_update_checkout_config()
repo_ids = {name: repo["remote"]["id"] for name, repo in checkouts["repos"].items()}
sources = json.load(open("sources.json"))

for schema, value in checkouts["branch-schemes"].items():
    if not schema.startswith("release/"):
        print(f"skipping {schema}")
        continue
    schema = schema.removeprefix("release/")

    for repo, ref in value["repos"].items():
        nwo = repo_ids[repo]
        flake_uri = f"github:{nwo}?ref={ref}"
        if repo in sources.get(schema, {}):
            continue
        print(f"fetch {flake_uri}")
        command = ["nix", "flake", "prefetch", "--json", flake_uri]
        result = subprocess.check_output(command)
        flake = json.loads(result)
        update_sources_json(schema, repo, flake)
