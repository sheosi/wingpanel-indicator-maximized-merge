/** Just a wrapper with an Xcb.Connection, mostly makes Xcb play more according
to vala rules (exceptions, enums and some ready made events) */
private class XConn {
    private Xcb.Connection conn;

    private static Xcb.Atom? atom_name;
    private static Xcb.Atom? atom_class;

    public XConn() {
       conn = new Xcb.Connection();

       if (atom_name == null) {
           try {
               atom_name = get_atom("WM_NAME");
           }catch (XcbError e) {
               stderr.printf(@"Failed to get WM_NAME: $(e.message)\n");
           }
       }

       if (atom_class == null) {
           try {
               atom_class = get_atom("WM_CLASS");
           }catch (XcbError e) {
               stderr.printf(@"Failed to get WM_CLASS: $(e.message)\n");
           }
       }
       
    }

    public Xcb.Setup setup{owned get{return conn.get_setup();}}

    private void throw_xcb_error(Xcb.GenericError e) throws XcbError {

        var msg = "";
        
        switch (e.error_code) {
            case 2: msg = "BadValue"; break;
            case 3: msg = "BadWindow"; break;
            case 5: msg = "BadAtom";break;
            default: msg = @"errcode: $(e.error_code)";break;
        }

        switch (e.error_code) {
            case 3: throw new XcbError.BADWINDOW(@"Xcb $msg\n");
            default: throw new XcbError.GENERIC(@"Xcb $msg\n");
        }
    }

    public Xcb.Atom? get_atom(string atom_name)  throws XcbError {
       Xcb.GenericError? e = null;
       var result = conn.intern_atom_reply(conn.intern_atom(true, atom_name), out e);
       if (e != null) {
           throw_xcb_error((!)e);
       }
       var atom = ((!)result).atom;
       if (atom == Xcb.AtomEnum.NONE) {
           return null;
       }
       else {
        return atom;
       }
   }

   public Xcb.Atom[] get_property_atoms(Xcb.Window win, Xcb.Atom atom) throws XcbError {
    Xcb.GenericError? e = null;
    #if XCONN_FAST
        var cookie = conn.get_property_unchecked(false, win, atom, Xcb.AtomEnum.ATOM, 0,1024);
    #else
        var cookie = conn.get_property(false, win, atom, Xcb.AtomEnum.ATOM, 0,1024);
    #endif
    var reply = conn.get_property_reply(cookie, out e);

    if (e!=null) {
        throw_xcb_error((!)e);
    }

    unowned Xcb.Atom[] res = ((Xcb.Atom[])((!)reply).value());
    res.length = (int) ((!)reply).val_len;
    return res;
   }

   public string get_atom_name(Xcb.Atom atom) {
       return ((!)conn.get_atom_name_reply(conn.get_atom_name(atom))).name;
   }

   public string? get_property_string(Xcb.Window win, Xcb.Atom atom) throws XcbError {
        Xcb.GenericError? e = null;
        #if XCONN_FAST
            var cookie = conn.get_property_unchecked(false, win, atom, Xcb.AtomEnum.STRING, 0,255);
        #else
            var cookie = conn.get_property(false, win, atom, Xcb.AtomEnum.STRING, 0,255);
        #endif

        var reply = conn.get_property_reply(cookie, out e);
        if (e!=null) {
            throw_xcb_error((!)e);
            }
        if (reply == null) {
            return null;
        }
        if (((!)reply).type == Xcb.AtomEnum.NONE) {
            return null;
        }
        return ((!)reply).value_as_string();

   }

   public string? get_name(Xcb.Window win) throws XcbError {
       if (atom_name == null) {
           throw new XcbError.CANT_GET_ATOM(@"Couldn't obtain atom name");
       }
       return get_property_string(win, (!)atom_name);
   }

   public string? get_class(Xcb.Window win) throws XcbError {
       if (atom_class == null) {
           throw new XcbError.CANT_GET_ATOM(@"Couldn't obtain atom class");
       }
       return get_property_string(win, (!)atom_class);
   }

   public GLib.List<Xcb.Window> list_all_windows(Xcb.Window parent) throws XcbError {
       var res = new GLib.List<Xcb.Window>();
       foreach (var child in query_tree(parent)) {
           res.append(child);
           res.concat(list_all_windows(child));
       }

       return res;
   }

   public Xcb.Window[]? query_tree(Xcb.Window win)  throws XcbError{
       Xcb.GenericError? e;

       var cookie = conn.query_tree(win);
       var res = conn.query_tree_reply(cookie, out e);

       if (e!= null) {
           throw_xcb_error((!)e);
       }

       if (res == null) {
           return null;
       }
       return ((!)res).children;
       
   }

   public void change_property_cardinal(Xcb.Window win, Xcb.Atom atom, uint32 data)  throws XcbError{
       var val = data;
       var res = conn.change_property_uint32(Xcb.PropMode.REPLACE, win, atom, Xcb.AtomEnum.CARDINAL, 1, &val);
       var e = conn.request_check(res);
       if (e != null) {
           throw_xcb_error((!)e);
       }
   }

   public void change_window_attributes(Xcb.Window win, Xcb.CW value_mask, uint32[]? value_list) throws XcbError {
       var res = conn.change_window_attributes(win, value_mask, value_list);
       var e = conn.request_check(res);
       if (e!= null){
           throw_xcb_error((!)e);
       }
   }

   public Xcb.GenericEvent? poll_for_event() {
       return conn.poll_for_event();
   }
}

public errordomain XcbError {
    GENERIC,
    CANT_GET_ATOM,
    BADWINDOW
}
