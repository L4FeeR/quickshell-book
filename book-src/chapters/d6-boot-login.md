# Desktop Ricing 6: Boot and Login

The first thing your computer shows isn't your bar, it's the boot menu, a splash screen and a login screen. Theming them finishes the rice from power button to desktop. This chapter covers a **GRUB** theme, a **Plymouth** splash and an **SDDM** login theme, which is written in QML, so everything from this book applies.

> [!WARNING] These need root and can stop your system booting
> Keep a live USB at hand, change one thing at a time, and reboot to test before moving on. All three can be undone by switching back to the default theme.

## GRUB

GRUB (the boot menu many Arch installs use; systemd-boot has no themes) loads a theme from a folder with a `theme.txt`, a background and fonts:

@include desktop/grub/theme.txt

`desktop-image` and `desktop-color` set the background; `+ boot_menu` is the list of entries, placed in percentages of the screen, with its font and colours; `+ label` with `id = "__timeout__"` shows the countdown. To install it:

```bash
sudo mkdir -p /boot/grub/themes/tokyo
sudo cp theme.txt background.png /boot/grub/themes/tokyo/
# a GRUB font from any TTF:
sudo grub-mkfont -s 18 -o /boot/grub/themes/tokyo/terminus18.pf2 /usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf
# in /etc/default/grub:  GRUB_THEME="/boot/grub/themes/tokyo/theme.txt"
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Ready-made themes (catppuccin/grub, vinceliuice/grub2-themes) follow the same layout.

## Plymouth

Plymouth shows a graphical splash while the disk is unlocked and the system starts.

```bash
sudo pacman -S plymouth
# add "plymouth" to HOOKS in /etc/mkinitcpio.conf (after "udev", before "encrypt" if you use it)
# add "quiet splash" to the kernel parameters (GRUB_CMDLINE_LINUX_DEFAULT in /etc/default/grub)
plymouth-set-default-theme -l                 # installed themes
sudo plymouth-set-default-theme -R spinner    # set one and rebuild the initramfs
```

Themes like `catppuccin-plymouth` or the many animated ones in `plymouth-themes` (AUR) install into `/usr/share/plymouth/themes/`. Test without rebooting: `sudo plymouthd; sudo plymouth --show-splash; sleep 5; sudo plymouth quit`.

## SDDM: a login screen in QML

SDDM is the login manager most rices use, and its themes are **QML files**. Here's a complete theme matching the rest of the rice: blurred wallpaper, a big clock, the user, a password field that shakes on a wrong password, session switching and power buttons.

@include desktop/sddm/tokyo-login/Main.qml

::: walk
@ 4-10 | What SDDM provides
SDDM loads `Main.qml` and gives it four objects by name. `sddm` logs in and powers off; `userModel` and `sessionModel` list users and sessions; `config` holds the values from `theme.conf`. There's no Quickshell here: plain Qt Quick.
@ 11-22 | The root
A full-screen rectangle (SDDM stretches it to each screen). Colours, the selected session (the last one used) and the user (the last one who logged in).
@ 24-39 | Background
The image named in `theme.conf`, blurred and darkened with [[MultiEffect]], so the text reads well whatever the picture.
@ 41-68 | Clock
Time and date, updated by a timer every second.
@ 70-107 | The user
A circle with the user's initial and their name. Clicking the name cycles through users: `userModel` is a list model, so `rowCount()` gives the number of users and `data(index, role)` reads a field. Role 257 (`Qt.UserRole + 1`) is the name.
@ 109-147 | The password field
A pill with a hidden-text input. Enter calls `sddm.login(user, password, session)`. The border turns accent-coloured when focused; a shake animation is ready for failures.
@ 149-166 | Feedback
SDDM emits `loginFailed` after a wrong password: show a message, clear the field, shake. On success, SDDM starts your session.
@ 168-183 | Session
The current session's name (role 260 of `sessionModel`); clicking cycles through Hyprland, Plasma and any others installed.
@ 185-201 | Power
Suspend, restart and shut down, each calling `sddm`. A list of `[label, function]` pairs keeps the buttons short.
:::

@include desktop/sddm/tokyo-login/theme.conf

@include desktop/sddm/tokyo-login/metadata.desktop

`metadata.desktop` names the theme and its main file; `QtVersion=6` tells SDDM to use Qt 6. Install and select it:

```bash
sudo cp -r tokyo-login /usr/share/sddm/themes/
sudo cp ~/Pictures/wall.jpg /usr/share/sddm/themes/tokyo-login/background.jpg
printf '[Theme]\nCurrent=tokyo-login\n' | sudo tee /etc/sddm.conf.d/theme.conf
sddm-greeter-qt6 --test-mode --theme /usr/share/sddm/themes/tokyo-login   # preview in a window
```

> [!TIP] Testing a theme without SDDM
> The theme was tested for this book by loading it from a small QML file that defines stand-in `sddm`, `userModel`, `sessionModel` and `config` objects, then running it with `qml`. You can do the same to work on a theme quickly.

## greetd instead of SDDM

greetd is a tiny login daemon; its "greeters" can be anything, including a Quickshell config (`Quickshell.Services.Greetd` talks to it). A Quickshell greeter can share your shell's components and theme exactly.

::: exercise warm | Preview it
Install the SDDM theme, preview it with `--test-mode`, and swap in your own wallpaper.
:::

::: exercise practice | Avatars
Show the user's avatar (role 260 of `userModel` is the icon path, `Qt.UserRole + 4`) instead of the initial, in a round clip.
:::
