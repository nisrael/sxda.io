+++
title = "Lofree Lite 84 web config tool permission problem"
date = 2026-10-09T21:02:00+01:00

[taxonomies]
tags = ["linux", "keyboard", "lofree", "fedora", "systemd"]
+++

In order to configure the Lofree Lite 84, you can download a Windows installer in a rar file from Dropbox (why??) or visit <https://www.lofree.tech/keyboard/>.

Since the website uses the [WebHID API](https://developer.mozilla.org/en-US/docs/Web/API/HID) we have to use a Chromium-based browser.

Still, it is possible that you get an error in the browser console:

> `Uncaught (in promise) NotAllowedError: Failed to open the device.`

This means that you don't have access to the `/dev/hidraw*` device that represents the keyboard.

With this `udev` rule, you allow the user that is physically logged into the computer access to the `/dev/hidraw*` device.

```text,name=/etc/udev/rules.d/50-lofree.rules
SUBSYSTEM=="hidraw", ATTRS{idVendor}=="388d", ATTRS{idProduct}=="0008", TAG+="uaccess"
```

```bash
sudo udevadm control --reload
sudo udevadm trigger
```

> [!NOTE]
> The `TAG+="uaccess"` tag should work on all `systemd`-based distributions. I have tested it only on Fedora.
