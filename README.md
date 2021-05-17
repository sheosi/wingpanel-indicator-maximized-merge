# Maximized merge wingpanel indicator

This indicator integrates your titlebar into wingpanel, by adding a close button
(and a maximize button in the future) and making the titlebar to dissappear with
a maximized non-CSD window.

It's still very early and a lot of things don't work yet.

What works:
* Remove titlebars from windows that already exist when this launches (you might want to use [maximal](https://github.com/crazygolem/maximal))
* Close current window

I want to thank the [maximal](https://github.com/crazygolem/maximal) script, since my implementation is one written in Vala and Xcb of that script. This means that this works by exploiting `_GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED` just like `maximal`.

Note: Right now you need to middle click on the indicator for it to close the window.

## Install, build and run
On *elementaryOS*:
```bash
# install elementary-sdk, meson and libwingpanel
sudo apt install elementary-sdk meson libwingpanel-2.0-dev
````
On *Fedora*:
```bash
sudo dnf install meson granite-devel vala cmake wingpanel-devel
```
```
# clone repository
git clone https://github.com/sheosi/wingpanel-indicator-maximized-merge wingpanel-indicator-maximized-merge
# cd to dir
cd wingpanel-indicator-maximized-merge
# run meson
meson build --prefix=/usr
# cd to build, build and test
cd build
sudo ninja install
# restart switchboard to load your indicator
pkill wingpanel -9
```


## Generating pot file

```bash
# after setting up meson build
cd build

# generates pot file
sudo ninja wingpanel-maximized-merge-pot

# to regenerate and propagate changes to every po file
sudo ninja wingpanel-maximized-merge-update-po
```

## Known bugs
As said earlier there's a lot that doesn't work:

* No button for unmaximizing
* The close button needs to be middle clicked and shows and empty menu with left click.
* You still to use something like `maximal` since we are not receiving events form new windows.S
