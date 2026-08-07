# turm

A TUI for [Slurm](https://slurm.schedmd.com/), which provides a convenient way to manage your cluster jobs.

> **Fork notice**: this is a personal fork of [karimknaebel/turm](https://github.com/karimknaebel/turm) with extra features for day-to-day cluster work — goto workdir (`Enter`), node monitoring with nvitop/htop (`n`), copy job id (`y`), resizable panels. This fork is **not** intended to be merged back into the upstream project; for the original version, see the upstream repository.

<img alt="turm demo" src="https://github.com/user-attachments/assets/7daade50-def3-4bf8-bf12-df311438094e" width="100%" />

`turm` accepts the same options as `squeue` (see [man squeue](https://slurm.schedmd.com/squeue.html#SECTION_OPTIONS)). Use `turm --help` to get a list of all available options. For example, to show only your own jobs, sorted by descending job ID, including all job states (i.e., including completed and failed jobs):
```shell
turm --me --sort=-id --states=ALL
```

## Installation

This fork is **not** published to PyPI, crates.io, or conda-forge (and it is not available via `uv`, `pip`, `pixi` or `conda`). Install it directly from this repository:

```shell
cargo install --git https://github.com/hn-yu/turm
```

This builds the `main` branch (with all features listed below) and installs the binary to `~/.cargo/bin/turm`.

> **Note**: if you previously installed the upstream `turm` (e.g. via `uv tool install turm`), make sure `~/.cargo/bin` comes before that installation in your `PATH`, or remove the other installation first — otherwise your shell may still resolve to the old upstream binary. If `turm` is already running, exit and restart it to pick up the new version.

No prebuilt binaries are published; without a Rust toolchain, build it yourself with `cargo build --release` and copy `target/release/turm` into your `~/.local/bin`.

### Shell Completion (optional)

#### Bash

In your `.bashrc`, add the following line:
```bash
eval "$(turm completion bash)"
```

#### Zsh

In your `.zshrc`, add the following line:
```zsh
eval "$(turm completion zsh)"
```

#### Fish

In your `config.fish` or in a separate `completions/turm.fish` file, add the following line:
```fish
turm completion fish | source
```

## Keybindings

All bindings are also shown in the help bar at the bottom of the TUI.

| Key | Action |
|---|---|
| `q` | Quit |
| `j`/`k` or `⏷`/`⏶` | Select next / previous job |
| `g` / `G` | Jump to first / last job |
| `Enter` | **Goto workdir** — quit `turm` and open a shell in the selected job's working directory |
| `n` | **Monitor node** — quit `turm`, `ssh` to the selected job's first node and run `nvitop` (GPU jobs) or `htop -u <user>`, falling back to `top -u <user>` (CPU jobs) |
| `y` | **Copy job id** — copy the selected job's id to the terminal clipboard (OSC 52, works over SSH) |
| `c` / `C` | Cancel job / pick a signal to send |
| `t` | Set time limit |
| `o` | Toggle stdout / stderr log view |
| `w` | Toggle log text wrap |
| `pgup` / `pgdown` | Scroll log (hold `shift`/`ctrl`/`alt` for 50 lines) |
| `home` / `end` | Jump to top / bottom of log |
| `ctrl+d` / `ctrl+u` | Scroll job list half a page |
| `esc` / `enter` | Close dialogs / confirm |
| drag `│` | Resize the Jobs/Details split (mouse) |

`nvitop` and `htop` must be on the remote node's `PATH`. On clusters with a shared home directory, install nvitop once (e.g. `pip install --user nvitop`) and it works on every node. Note that clusters often restrict SSH to nodes where you have an active job (e.g. `pam_slurm_adopt`).

## How it works

`turm` obtains information about jobs by parsing the output of `squeue`.
The reason for this is that `squeue` is available on all Slurm clusters, and running it periodically is not too expensive for the Slurm controller ( particularly when [filtering by user](https://slurm.schedmd.com/squeue.html#OPT_user)).
In contrast, Slurm's C API is unstable, and Slurm's REST API is not always available and can be costly for the Slurm controller.
Another advantage is that we get free support for the exact same CLI flags as `squeue`, which users are already familiar with, for filtering and sorting the jobs.

### Resource usage

TL;DR: `turm` ≈ `watch -n2 squeue` + `tail -f slurm-log.out`

Special care has been taken to ensure that `turm` is as lightweight as possible in terms of its impact on the Slurm controller and its file I/O operations.
The job queue is updated every two seconds by running `squeue`.
When there are many jobs in the queue, it is advisable to specify a single user to reduce the load on the Slurm controller (see [squeue --user](https://slurm.schedmd.com/squeue.html#OPT_user)).
`turm` updates the currently displayed log file on every inotify modify notification, and it only reads the newly appended lines after the initial read.
However, since inotify notifications are not supported for remote file systems, such as NFS, `turm` also polls the file for newly appended bytes every two seconds.

## Development without Slurm

For local UI testing, this repository includes mocks for `squeue`, `scancel`, and `scontrol`:

```shell
PATH=scripts/mock-slurm/bin:$PATH cargo run -- --me
```

The mock commands read/write files in `scripts/mock-slurm/logs`, so you can test log rendering and control actions without a Slurm install.

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=karimknaebel/turm&type=Date)](https://www.star-history.com/#karimknaebel/turm&Date)
