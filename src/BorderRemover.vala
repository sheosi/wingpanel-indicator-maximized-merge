private class BorderRemover {

    private class Empty{} // Just a stub for hash tables

    private XConn conn;
    private GLib.HashTable<Xcb.Window, Empty> handled; // Windows that have been treated
    private GLib.List<GLib.Regex> passlist; // Force removal of titlebar
    private GLib.List<GLib.Regex> blocklist; // Don't remove titlebar

    // Variables representing X.Org's atoms
    private static Xcb.Atom atom_hide;
    private static Xcb.Atom atom_max_vert;
    private static Xcb.Atom atom_actions;

    private BorderRemover(owned XConn _conn, 
        Xcb.Atom _atom_hide,
        Xcb.Atom _atom_max_vert,
        Xcb.Atom _atom_actions) {
        conn = _conn;
        var dpy = conn.setup.roots_iterator().data;
        var root = dpy.root;

        atom_hide = _atom_hide;
        atom_max_vert = _atom_max_vert;
        atom_actions = _atom_actions;

        passlist = parse_env_list("MAXIMIZED_MERGE_PASSLIST");
        blocklist = parse_env_list("MAXIMIZED_MERGE_BLOCKLIST");
        handled = new GLib.HashTable<Xcb.Window, Empty>(win_hash, win_equal);
        handled.insert(0, new Empty());

        // Hide everything
        try {
            foreach(var win in conn.list_all_windows(root)) {
                try {
                    hide(conn, win);
                }catch(XcbError e) {
                    stderr.printf(@"Error on hide: $(e.message)\n");
                }
                const uint32[] t = {Xcb.EventMask.SUBSTRUCTURE_NOTIFY};
                conn.change_window_attributes(root, Xcb.CW.EVENT_MASK, t);
            }
        } catch(XcbError e) {
            stderr.printf(@"Error on hide: $(e.message)\n");
        }
        
    }

    public static GLib.List<Regex> parse_env_list(string env_name) {
        var env_str = GLib.Environment.get_variable(env_name);
        var res = new GLib.List<Regex>();
        if (env_str != null) {
            try {
                foreach (var str in ((!)env_str).split(","))  {
                    var name = str.strip();
                    if (name.length > 0) {
                        res.append(new Regex(@".*$name.*"));
                    }
                }
            } catch (GLib.Error e) {
                stderr.printf("List '%s' couldn't be parsed", (!)env_str);
            }
        }

        return res;
    }
    private bool any_matches(ref GLib.List<GLib.Regex> list, string target) {
        foreach(var reg in list) {
            if (reg.match(target)) {
                return true;
            }
        }
        return false;
    }

    private bool all_dont_match(ref GLib.List<GLib.Regex> list, string target) {
        foreach(var reg in list) {
            if (reg.match(target)) {
                return false;
            }
        }
        return true;
    }
    
    private string value_or(string? val, string def) {
        if (val != null) {
            return (!) val;
        }
        return def;
    }

    private string make_class_name(XConn conn ,Xcb.Window win) throws XcbError{
        var cls = value_or(conn.get_class(win), "");
        var name = value_or(conn.get_name(win), "");
        return @"$(cls)::$(name)";
    }
    
    private bool array_contains(Xcb.Atom[] array, Xcb.Atom target) {
        foreach(var a in array) {
            if (a == target) {
                return true;
            }
        }
        return false;
    }

    private bool match(XConn conn, Xcb.Window win) throws XcbError {
        try {
            var actions = conn.get_property_atoms(win, atom_actions);
            var contains = array_contains(actions, atom_max_vert);

            var target = make_class_name(conn, win);
            
            var in_passlist = passlist.length() == 0 || any_matches(ref passlist, target);
            var not_in_blocklist = blocklist.length() == 0 || all_dont_match(ref blocklist, target);
            return ( contains && in_passlist && not_in_blocklist);
        }
        catch (XcbError e) {
            // This just means that the window doesn't exist, happens when
            // a window is destroyed because it is being unmapped
            if (e.code == XcbError.BADWINDOW) {
                return false;
            }
            else {
                throw e;
            }
        }
    }

    private void hide(XConn conn, Xcb.Window win) throws XcbError {
        if (!handled.contains(win) && match(conn, win)) {
            handled.insert(win, new Empty());
            conn.change_property_cardinal(win, atom_hide, 1);
        }
    }

    enum ResponseType {
        CREATE_NOTIFY = 16,
        DESTROY_NOTIFY = 17,
        MAP_NOTIFY = 18
    }

    private void handle(XConn conn, ref Xcb.GenericEvent event) throws XcbError{
        var type = event.response_type & ~0x80;
        switch (type) {
            case ResponseType.CREATE_NOTIFY: {
                var cr_event = ((Xcb.CreateNotifyEvent*) event);
                var win = cr_event->window;
                hide(conn, win);
                break;
            }
            case ResponseType.DESTROY_NOTIFY: {
                var ds_event = ((Xcb.DestroyNotifyEvent*) event);
                var win = ds_event->window;
                handled.remove(win);
                break;
            }
        }
    }

    public void poll() {
        var ev = conn.poll_for_event();
        while(ev != null) {
            try{
                var  ev_ = (!)ev;
                handle(conn,ref ev_);
            } catch(XcbError e) {
                stderr.printf(@"Error while handling: $(e.message)\n");
            }
            
            ev = conn.poll_for_event();
        }
            
    }
    public static BorderRemover? make_instance() {
        var conn = new XConn();
        try {
            var atom_hide = conn.get_atom( "_GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED");
            var atom_max_vert = conn.get_atom("_NET_WM_ACTION_MAXIMIZE_VERT");
            var atom_actions = conn.get_atom("_NET_WM_ALLOWED_ACTIONS");
        
            return new BorderRemover(conn, (!)atom_hide, 
            (!)atom_max_vert, (!)atom_actions);
        }
        catch (XcbError e) {
            stderr.printf(@"Error while make_instance: $(e.message)\n");
        }
        return null;
        
    }
     
}

public uint win_hash(Xcb.Window win) {
    return int_hash((int)win);
}

public bool win_equal(Xcb.Window a, Xcb.Window b) {
    return a == b;
}
