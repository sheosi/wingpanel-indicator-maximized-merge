private class BorderRemover {

    private XConn conn;
    private GLib.Array<Xcb.Window> handled;
    private GLib.List<GLib.Regex> passlist;
    private GLib.List<GLib.Regex> blocklist;

    private static Xcb.Atom atom_type;
    private static Xcb.Atom atom_hide;
    private static Xcb.Atom atom_normal;

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

    private static bool contains(ref GLib.Array<Xcb.Window> array, Xcb.Window val) {
        for(var i = 0; i < array.length; i++) {
            if (array.index(i) == val) {
                return true;
            }
        }
        return false;
    }

    private static void remove_val(ref GLib.Array<Xcb.Window> array, Xcb.Window val) {
        var found = false;
        var index = 0;
        for(var i = 0; i < array.length; i++) {
            if (array.index(i) == val) {
                index = i;
                break;
            }
        }

        if (found) {
            array.remove_index(index);
        }
        
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

    private bool match(XConn conn, Xcb.Window win) throws XcbError {
        var type = conn.get_property_atom(win, atom_type);
        var is_normal = type == atom_normal;
        var target = make_class_name(conn, win);
        
        var in_passlist = passlist.length() == 0 || any_matches(ref passlist, target);
        var not_in_blocklist = blocklist.length() == 0 || all_dont_match(ref blocklist, target);
        
        return (is_normal && in_passlist && not_in_blocklist);
    }

    private void hide(XConn conn, Xcb.Window win) throws XcbError {
        if (!contains(ref handled, win) && match(conn, win)) {
            //var hide = conn.get_property_atom(win, atom_hide);
            handled.append_val(win);
            conn.change_property_cardinal(win, atom_hide, 1);
        }
    }

    enum ResponseType {
        CREATE_NOTIFY = 16,
        DESTROY_NOTIFY = 17,
        MAP_NOTIFY = 18
    }

    private void handle(XConn conn, ref Xcb.GenericEvent event) throws XcbError{
        stderr.printf("Handling!\n");
        var type = event.response_type & ~0x80;
        switch (type) {
            case ResponseType.CREATE_NOTIFY:{
                stderr.printf("Created!\n");
                var cr_event = ((Xcb.CreateNotifyEvent*) event);
                var win = cr_event->window;
                conn.change_window_attributes(win, Xcb.CW.EVENT_MASK , new uint32[Xcb.EventMask.STRUCTURE_NOTIFY]);
                break;
            }
            case ResponseType.MAP_NOTIFY: {
                var map_event = ((Xcb.MapNotifyEvent*) event);
                var win = map_event->window;
                hide(conn, win);
                break;
            }
            case ResponseType.DESTROY_NOTIFY:{
                var ds_event = ((Xcb.DestroyNotifyEvent*) event);
                var win = ds_event->window;
                remove_val(ref handled, win);
                break;
            }
        }
    }

    /*private void unhide(XConn conn, Xcb.Window win, prev_value) {
        //conn.dele
    }*/

    private BorderRemover(owned XConn _conn, Xcb.Atom _atom_hide, Xcb.Atom _atom_type, Xcb.Atom _atom_normal) {
        conn = _conn;
        var dpy = conn.setup.roots_iterator().data;
        var root = dpy.root;

        atom_hide = _atom_hide;
        atom_type = _atom_type;
        atom_normal = _atom_normal;

        passlist = parse_env_list("MAXIMIZED_MERGE_PASSLIST");
        blocklist = parse_env_list("MAXIMIZED_MERGE_BLOCKLIST");
        handled = new GLib.Array<Xcb.Window>();

        // Hide everything
        try {
            foreach(var win in conn.list_all_windows(root)) {
                try {
                    hide(conn, win);
                }catch(XcbError e) {
                    stderr.printf(@"$(e.message)");
                }
                var t = new uint32[Xcb.EventMask.SUBSTRUCTURE_NOTIFY];
                conn.change_window_attributes(root, Xcb.CW.EVENT_MASK, t);
                stdout.printf(@"$(t[0])");
            }
        } catch(XcbError e) {
            stderr.printf(@"$(e.message)");
        }
        
     }

     public void poll() {
        var ev = conn.poll_for_event();
        while(ev != null) {
            stdout.printf(@"found event\n");
            try{
                var  ev_ = (!)ev;
                handle(conn,ref ev_);
            }catch(XcbError e) {
                stderr.printf(@"$(e.message)");
            }
            
            ev = conn.poll_for_event();
        }
            
     }
     public static BorderRemover? make_instance() {
        var conn = new XConn();
        try {
            var atom_hide = conn.get_atom( "_GTK_HIDE_TITLEBAR_WHEN_MAXIMIZED");
            var atom_type = conn.get_atom("_NET_WM_WINDOW_TYPE");
            var atom_normal = conn.get_atom( "_NET_WM_WINDOW_TYPE_NORMAL");
        
            return new BorderRemover(conn, atom_hide, atom_type, atom_normal);
        }
        catch (XcbError e) {
            stderr.printf(@"$(e.message)");
        }
        return null;
        
     }
 }

