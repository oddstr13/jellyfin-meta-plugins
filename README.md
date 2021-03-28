Plugin tools
============

Dependencies
------------

- [hub](https://hub.github.com/)
- [jprm](https://pypi.org/project/jprm/) (building)
- dotnet (building)
- git
- bash
- python3

Tools
-----

- `build_all.sh`
  Builds (and publishes) all plugins.
- `build_plugin.sh`
  Builds (and publishes) a single plugin.
- `show_drafts.sh`
  Lists draft releases prepared by release-drafter.
- `show_issues.sh`
  Lists all open issues on the plugin repositories.
- `show_pullrequests.sh`
  Lists all open pull-requests on the plugin repositories.
- `update_submodules.py`
  Updates sub-modules, adds new plugins from the org, and removes archived/moved ones.

Out of date tools
-----------------

- `check_tag_meta_version.sh`
  FIXME: Not aware of release drafter or sub-modules!
  WARNING: Do not use! Use the draft release made by release-drafter instead.
- `verify_releases.py`
  FIXME: Not aware of release drafter or sub-modules!
  Checks the plugin repository against `build.yaml` and git tags to see if plugins are actually published.