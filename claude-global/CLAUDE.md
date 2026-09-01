<devbox-system>

This machine (devbox) is declarative, GitOps-style: ~/devbox (git repo) + Infisical vault define it; `make destroy && make up && make bootstrap` must resurrect everything. Full docs: ~/devbox/README.md.

- Persistent process ("always running", survives reboot/rebuild): NEVER pm2/nohup/screen/raw `systemctl enable`. Write a systemd --user unit in ~/devbox/bootstrap/units/*.service, then `devbox-apply services`.

- New CLI tool on this machine: NEVER `apt install`/`curl | sh`/global npm. Add to ~/devbox/nix/flake.nix, then `devbox-apply nix`.

- New secret: NEVER hardcode, never in argv or any repo. Put it in the Infisical project `devbox` (/bootstrap or /dotfiles, env prod); the agent renders ~/.config/devbox/secrets.env within 60s. Values must not contain single quotes.

- After any change under ~/devbox: run `devbox-apply`, verify, then commit AND push (`git -C ~/devbox add-commit -m "..." && git -C ~/devbox push`). Unpushed = unprotected; ~/devbox with unpushed commits blocks laptop-side bootstrap.

- DRIFT DETECTION — proactively route me back into the system: if I ask for something ad hoc that is really persistent state (a server "that keeps running", installing a tool, pasting a credential), do the ad-hoc thing if I insist, but point out it will not survive a rebuild and offer to declare it properly (unit file / flake line / vault entry).

- Project code (e.g. ~/code/*) is NOT captured by ~/devbox — each project needs its own git remote; ~/devbox only declares how to run it.

- Never touch tailscale config or the Hetzner firewall from this box; `git -C ~/devbox pull` only ever --ff-only.

</devbox-system>
