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
               stderr.printf(@"$(e.message)\n");
           }
       }

       if (atom_class == null) {
           try {
               atom_class = get_atom("WM_CLASS");
           }catch (XcbError e) {
               stderr.printf(@"$(e.message)\n");
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

    public Xcb.Atom get_atom(string atom_name)  throws XcbError {
       Xcb.GenericError? e = null;
       var result = conn.intern_atom_reply(conn.intern_atom(true, atom_name), out e);
       if (e != null) {
           throw_xcb_error((!)e);
       }

       return ((!)result).atom;
   }

   public Xcb.Atom get_property_atom(Xcb.Window win, Xcb.Atom atom) throws XcbError {
       Xcb.GenericError? e = null;
       var cookie = conn.get_property(false, win, atom, Xcb.AtomEnum.ATOM, 0,1024);
       var reply = conn.get_property_reply(cookie, out e);
       if (e!=null) {
           throw_xcb_error((!)e);
       }
       return *((Xcb.Atom*)((!)reply).value());
   }

   public string atom_to_string(Xcb.Atom atom) {
       switch (atom) {
           case Xcb.AtomEnum.ARC: {return "arc";}
            case Xcb.AtomEnum.ATOM: {return "atom";}
            case Xcb.AtomEnum.BITMAP: {return "bitmap";}
            case Xcb.AtomEnum.CAP_HEIGHT: {return "cap_height";}
            case Xcb.AtomEnum.CARDINAL: {return "cardinal";}
            case Xcb.AtomEnum.COLORMAP: {return "colormap";}
            case Xcb.AtomEnum.COPYRIGHT: {return "copyright";}
            case Xcb.AtomEnum.CURSOR: {return "cursor";}
            case Xcb.AtomEnum.CUT_BUFFER0: {return "cutBuffer0";}
            case Xcb.AtomEnum.CUT_BUFFER1: {return "cutBuffer1";}
            case Xcb.AtomEnum.CUT_BUFFER2: {return "cutBuffer2";}
            case Xcb.AtomEnum.CUT_BUFFER3: {return "cutBuffer3";}
            case Xcb.AtomEnum.CUT_BUFFER4: {return "cutBuffer4";}
            case Xcb.AtomEnum.CUT_BUFFER5: {return "cutBuffer5";}
            case Xcb.AtomEnum.CUT_BUFFER6: {return "cutBuffer6";}
            case Xcb.AtomEnum.CUT_BUFFER7: {return "cutBuffer7";}
            case Xcb.AtomEnum.DRAWABLE: {return "drawable";}
            case Xcb.AtomEnum.END_SPACE: {return "endSpace";}
            case Xcb.AtomEnum.FAMILY_NAME: {return "familyName";}
            case Xcb.AtomEnum.FONT: {return "font";}
            case Xcb.AtomEnum.FONT_NAME: {return "fontName";}
            case Xcb.AtomEnum.FULL_NAME: {return "fullName";}
            case Xcb.AtomEnum.INTEGER: {return "integer";}
            case Xcb.AtomEnum.ITALIC_ANGLE:{return "italicAngle";}
            case Xcb.AtomEnum.MAX_SPACE: {return "maxSpace";}
            case Xcb.AtomEnum.MIN_SPACE: {return "minSpace";}
            case Xcb.AtomEnum.NONE: {return "none";}
            case Xcb.AtomEnum.NORM_SPACE: {return "normSpace";}
            case Xcb.AtomEnum.NOTICE: {return "notice";}
            case Xcb.AtomEnum.PIXMAP: {return "pixmap";}
            case Xcb.AtomEnum.POINT: {return "point";}
            case Xcb.AtomEnum.POINT_SIZE: {return "pointSize";}
            case Xcb.AtomEnum.PRIMARY: {return "primary";}
            case Xcb.AtomEnum.QUAD_WIDTH: {return "quadWidth";}
            case Xcb.AtomEnum.RECTANGLE: {return "rectangle";}
            case Xcb.AtomEnum.RESOLUTION: {return "resolution";}
            case Xcb.AtomEnum.RESOURCE_MANAGER: {return "resourceManager";}
            case Xcb.AtomEnum.RGB_BEST_MAP: {return "rgbBestMap";}
            case Xcb.AtomEnum.RGB_BLUE_MAP: {return "rgbBlueMap";}
            case Xcb.AtomEnum.RGB_COLOR_MAP: {return "rgbColorMap";}
            case Xcb.AtomEnum.RGB_DEFAULT_MAP: {return "rgbDefaultMap";}
            case Xcb.AtomEnum.RGB_GRAY_MAP: {return "rgbGrayMap";}
            case Xcb.AtomEnum.RGB_GREEN_MAP: {return "rgbGreenMap";}
            case Xcb.AtomEnum.RGB_RED_MAP: {return "rgbRedMap";}
            case Xcb.AtomEnum.SECONDARY: {return "secondary";}
            case Xcb.AtomEnum.STRIKEOUT_ASCENT: {return "strikeoutAscent";}
            case Xcb.AtomEnum.STRIKEOUT_DESCENT: {return "strikeoutDescent";}
            case Xcb.AtomEnum.STRING: {return "string";}
            case Xcb.AtomEnum.SUBSCRIPT_X: {return "subscriptX";}
            case Xcb.AtomEnum.SUBSCRIPT_Y: {return "subscriptY";}
            case Xcb.AtomEnum.SUPERSCRIPT_X: {return "superscriptX";}
            case Xcb.AtomEnum.SUPERSCRIPT_Y: {return "superscriptY";}
            case Xcb.AtomEnum.UNDERLINE_POSITION: {return "underlinePosition";}
            case Xcb.AtomEnum.UNDERLINE_THICKNESS: {return "underlineThickness";}
            case Xcb.AtomEnum.VISUALID: {return "visualid";}
            case Xcb.AtomEnum.WEIGHT: {return "weight";}
            case Xcb.AtomEnum.WINDOW: {return "window";}
            case Xcb.AtomEnum.WM_CLASS: {return "wmClass";}
            case Xcb.AtomEnum.WM_CLIENT_MACHINE: {return "wmClientMachine";}
            case Xcb.AtomEnum.WM_COMMAND: {return "wmCommand";}
            case Xcb.AtomEnum.WM_HINTS: {return "wmHints";}
            case Xcb.AtomEnum.WM_ICON_NAME: {return "wmIconName";}
            case Xcb.AtomEnum.WM_ICON_SIZE: {return "wmIconSize";}
            case Xcb.AtomEnum.WM_NAME: {return "wmName";}
            case Xcb.AtomEnum.WM_NORMAL_HINTS: {return "wmNormalHints";}
            case Xcb.AtomEnum.WM_SIZE_HINTS: {return "wmSizeHints";}
            case Xcb.AtomEnum.WM_TRANSIENT_FOR: {return "wmTransientFor";}
            case Xcb.AtomEnum.WM_ZOOM_HINTS: {return "wmZoomHints";}
            case Xcb.AtomEnum.X_HEIGHT: {return "xHeight";}
       }
       return "";
   }

   public string? get_property_string(Xcb.Window win, Xcb.Atom atom) throws XcbError {
       Xcb.GenericError? e = null;
       var cookie = conn.get_property(false, win, atom, Xcb.AtomEnum.STRING, 0,255);
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
