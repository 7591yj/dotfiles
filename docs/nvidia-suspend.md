# nvidia-suspend

Fix for issues with suspend while using an nvidia card.

## Files needed

- [gnome-shell-resume.service](../etc/systemd/system/gnome-shell-resume.service)
- [gnome-shell-suspend.service](../etc/systemd/system/gnome-shell-suspend.service)
- [suspend-gnome-shell.sh](../usr/local/bin/suspend-gnome-shell.sh)

## Command

```bash
sudo chmod +x /usr/local/bin/suspend-gnome-shell.sh
```

```bash
systemctl daemon-reload
systemctl enable gnome-shell-suspend
systemctl enable gnome-shell-resume
```
