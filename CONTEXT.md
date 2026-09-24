# CONTEXT

Two opencode generations live here side by side. `hmModules/default.nix` drives
v1 (1.x, `programs.opencode` from home-manager upstream);
`hmModules/opencode2.nix` drives v2 (2.x, `@opencode/cli` via
`pkgs.inputs.llm-agents.opencode2`). v2 is where this is going — the v1 module
and its package stay until parity is reached.

## Why v2 could not be a flag on the v1 module

The config keys were renamed between generations, so the same attrset produces
a silently wrong file:

| v1 | v2 |
| --- | --- |
| `plugin` | `plugins` |
| `agent` | `agents` |
| an agent's `prompt` | `system` |

`autoshare` is gone entirely — v2 drops it from the parsed config without
complaining. `instructions`, `mcp`, `model`, `small_model`, `watcher` and `lsp`
carry over unchanged, and the MCP server shape is identical, which is why
`toOpencodeShape` is duplicated rather than generalised. `small_model`
normalises into `agents.title.model` on read, so it round-trips differently
than it is written.

Option *names* on `programs.opencode2` deliberately match home-manager's
`programs.opencode` even where the file keys differ. Retiring v1 should be a
rename, not a rewrite.

## The two option layers

`programs.opencode2` is the plumbing — there is no upstream home-manager module
to sit on top of, so this one declares its own. `modules.programs.opencode2` is
the opinionated layer (enable, model, the LSP block, the shared agents and
skills), matching how `modules.programs.opencode` sits on top of upstream's.
`modules.programs.ai` targets the plumbing layer, so a host gets the shared
commands, agents, skills and MCP gateway for free.

## Per file, never the directory

opencode writes `service.json` into its config dir at runtime — it holds a
generated server password, and the managed service port if one is set. A
`xdg.configFile."opencode2"` directory symlink would make that unwritable, so
every entry is declared per file.

That is also why there is no `port` option: the port lives in that same
runtime-owned `service.json`, so home-manager cannot own it without owning the
password too. Set it with `opencode2 service set port <n>` if it ever matters.

## Directory names

v2 scans both the singular and the plural form of `agent`/`agents`,
`command`/`commands` and `skill`/`skills`, and loads all of them. The module
writes the plural, matching the v1 layout.

## The XDG wrapper

Both generations derive their dirs from the XDG roots plus a literal
`opencode`, so an unwrapped v2 would share `~/.config/opencode` and
`~/.local/share/opencode` with v1. The module's `home.packages` wrapper gives
v2 its own roots — hence the nested `opencode2/opencode` paths, since v2
appends its own name.

`XDG_CONFIG_HOME` is deliberately *not* among them. Config comes from
`OPENCODE_CONFIG_DIR` instead, because opencode spawns `gh`, `git` and the
user's shell as tool subprocesses, and moving `XDG_CONFIG_HOME` would send all
of them to an empty config dir.

## The port is shared even when the dirs are not

The managed background service binds `127.0.0.1:49374` by default, and that
default does not move with the config dir. Two v2 installs — say a stale daemon
from an older wrapper and the current one — fight over it, and the loser retries
every five seconds forever while the TUI sits on `Starting background server…`
with no error. The real message is only in
`$XDG_DATA_HOME/opencode/log/opencode.log`:
`Managed service port 49374 on 127.0.0.1 is already in use`. Check
`ss -tlnp | grep 49374` before assuming the config is at fault.
