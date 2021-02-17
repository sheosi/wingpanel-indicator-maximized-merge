/*
 * Copyright (c) 2011-2019 elementary, Inc. (https://elementary.io)
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public
 * License along with this program; if not, write to the
 * Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301 USA
 */


 // Note: This denotes a dbus interface
 [DBus (name = "org.pantheon.gala")]
 interface GalaInterface : Object {
     public abstract void perform_action (int32 type) throws GLib.Error;

     // Note: This only works for the current window so we can't show menus
     public enum Action {
         TOGGLE_MAXIMIZE = 2, 
         MINIMIZE = 3,
         CLOSE = 15
     }
 }

 public class MaximizedMerge.Indicator : Wingpanel.Indicator {
    private const string ICON_NAME = "window-close-symbolic";
    //ICON_NAME_RESTORE = "window-restore-symbolic"
    private const string WM_SCHEMA = "org.gnome.desktop.wm.keybindings";

    private Wingpanel.Widgets.OverlayIcon? indicator_icon;

    private static GLib.Settings? wm_settings;
    private static GalaInterface? wm_conn;


    public Indicator () {
        Object (code_name: "MaximizedMerge");
        this.visible = true;
    }

    static construct {
        var def_schema = SettingsSchemaSource.get_default ();
        if (def_schema != null) {
            if (((!)def_schema).lookup (WM_SCHEMA, true) != null) {
                wm_settings = new GLib.Settings (WM_SCHEMA);
            }
        }
        try {
            wm_conn = Bus.get_proxy_sync(BusType.SESSION,
                "org.pantheon.gala"/*dbus object name */,
                "/org/pantheon/gala"/*key inside of it*/
            );
        } catch (GLib.Error e) {
            stderr.printf ("Meh: %s\n", e.message);
        }

        BorderRemover? border_remover = BorderRemover.make_instance();
        if (border_remover != null) {
            GLib.Timeout.add_full(GLib.Priority.LOW, 2000, () => {
                ((!)border_remover).poll();
                return GLib.Source.CONTINUE;
            });
        }
        else {
            stderr.printf ("Couldn't init border_remover, titlebars wont be changed\n");
        }
    }


    public override Gtk.Widget get_display_widget () {
        if (indicator_icon == null) {
            indicator_icon = new Wingpanel.Widgets.OverlayIcon (ICON_NAME);
            ((!)indicator_icon).button_press_event.connect ((e) => {
                if (e.button == Gdk.BUTTON_MIDDLE) {
                    this.wm_action(GalaInterface.Action.CLOSE);

                    return Gdk.EVENT_STOP;
                }

                return Gdk.EVENT_PROPAGATE;
            });
        }


        return (!)indicator_icon;
    }

    public override Gtk.Widget? get_widget () {
        return null;
    }

    private void wm_action(GalaInterface.Action action) {
        
        try {
            if (wm_conn != null) {
                ((!)wm_conn).perform_action(action);
            }
        } catch (GLib.Error e) {
            stderr.printf ("%s\n", e.message);
        }
    }
    
    
    public override void closed() {
        
    }

    public override void opened () {
    }

}

public Wingpanel.Indicator? get_indicator (Module module, Wingpanel.IndicatorManager.ServerType server_type) {

    if (server_type != Wingpanel.IndicatorManager.ServerType.SESSION) {
        return null;
    }

    var indicator = new MaximizedMerge.Indicator();
    return indicator;
}