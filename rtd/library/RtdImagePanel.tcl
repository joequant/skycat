# E.S.O. - VLT project 
# "@(#) $Id: RtdImagePanel.tcl,v 1.28 1998/10/28 17:42:29 abrighto Exp $"
#
# RtdImagePanel.tcl - widget for displaying relevant image information
#                     in tabular (blt_table) format
# 
# 
# See man page RtdImagePanel(n) for a complete description.
# 
# who             when       what
# --------------  ---------  ----------------------------------------
# Allan Brighton  12 Oct 95  Created

itk::usual RtdImagePanel {}

# RtdImagePanel is a display and control panel for the RtdImageCtrl(n) widget. 
# It displays the following information:
#
#     the object name, the name of the file or camera being viewed
#
#     the x,y pixel and world coordinates and pixel value under the
#     mouse pointer
#
#     the minimum and maximum image pixel values
#
#     the image data type
#
#     the low and high cut levels
#
#     the scale (magnification), flip(X,Y) and rotate settings
#
# In addition to displaying the current image information, the cut
# levels can be set by editing them and hitting return, the scale factor
# can be selected from a menu and the rotation and flip X/Y settings can
# be toggled with checkbuttons.

itcl::class rtd::RtdImagePanel {
    inherit util::FrameWidget

    # constructor 

    constructor {args} {
	itk_option add hull.borderwidth hull.relief

	# do this first so we can use the option values
	eval itk_initialize $args

	make_layout
    }


    # do the widget layout, aligning the items in rows and colums

    protected method make_layout {} {
	blt::table $w_
	add_short_help $w_ {Image information area}

	# frame at the lower right of the panel that optionally
	# holds the "Auto Set Cut Levels" button, ...
	itk_component add lrframe {
	    frame $w_.lrframe
	}
	
	# auto cut button
	if {$itk_option(-showcut)} {
	    # "Auto Set Cut Levels" button
	    itk_component add autocut {
		button $w_.autocut \
		    -text "Auto Set Cut Levels" \
		    -font $itk_option(-labelfont) \
		    -command [code $this auto_set_cut_levels]	    
	    }
	    pack $itk_component(autocut) \
		-anchor ne -padx 1m -pady 1m -fill x -in $itk_component(lrframe)
	}

	# the RtdImage code sets this array for us to speed up the panel
	# update by using the -textvariable option
	set var $image_
	global ::$var

	# XXX should probably use blt table for labels and values here...

	# display object name
	if {$itk_option(-showobject)} {
	    # LabelValue(n) object displaying object name or file name
	    itk_component add object {
		util::LabelValue $w_.object \
		    -text "Object:" \
		    -valuefont $itk_option(-valuefont) \
		    -orient horizontal \
		    -labelfont $itk_option(-labelfont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -anchor e \
		    -relief groove \
		    -valuewidth 50
	    } 
	    blt::table $w_ \
		$itk_component(object)  0,0 -fill x -anchor e -columnspan 3
	    add_short_help $itk_component(object) \
		{Object name (file or camera name, if object not known)}
	}

	# X and Y
	if {$itk_option(-showxy)} {
	    # LabelValue(n) widget for X image coordinate
	    itk_component add x {
		util::LabelValue $w_.x \
		    -text "X:" \
		    -textvariable ${var}(X) \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    # LabelValue(n) widget for Y image coordinate
	    itk_component add y {
		util::LabelValue $w_.y \
		    -text "Y:" \
		    -textvariable ${var}(Y) \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 

	    # LabelValue(n) widget for pixel value
	    itk_component add value {
		util::LabelValue $w_.value \
		    -text "Value:" \
		    -textvariable ${var}(VALUE) \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    blt::table $w_ \
		$itk_component(x)       1,0 -fill x -anchor w \
		$itk_component(y)       1,1 -fill x -anchor w \
		$itk_component(value)   1,2 -fill x -anchor w
	    
	    # workaround for bug in itcl2.0
	    $itk_component(x) config -textvariable ${var}(X)
	    $itk_component(y) config -textvariable ${var}(Y)
	    $itk_component(value) config -textvariable ${var}(VALUE)

	    add_short_help $itk_component(x) \
		{X image coordinate at mouse pointer (or X detector chip coordinate, if known)}
	    add_short_help $itk_component(y) \
		{Y image coordinate at mouse pointer (or Y detector chip coordinate, if known)}
	    add_short_help $itk_component(value) \
		{Raw image value at X,Y coordinates}
	}
	
	# ra and dec
	if {$itk_option(-showwcs)} {
	    # LabelValue(n) widget for RA coordinate
	    itk_component add ra {
		util::LabelValue $w_.ra \
		    -text "a:" \
		    -textvariable ${var}(RA) \
		    -labelfont $itk_option(-wcsfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    # LabelValue(n) widget for DEC coordinate
	    itk_component add dec {
		util::LabelValue $w_.dec \
		    -text "d:" \
		    -textvariable ${var}(DEC) \
		    -labelfont $itk_option(-wcsfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    itk_component add equinox {
	    # LabelValue(n) widget for the equinox
		util::LabelValue $w_.equinox \
		    -text "Equinox:" \
		    -textvariable ${var}(EQUINOX) \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    blt::table $w_ \
		$itk_component(ra)      2,0 -fill x -anchor w \
		$itk_component(dec)     2,1 -fill x -anchor w \
		$itk_component(equinox) 2,2 -fill x -anchor w

	    # workaround for bug in itcl2.0
	    $itk_component(ra) config -textvariable ${var}(RA)
	    $itk_component(dec) config -textvariable ${var}(DEC)
	    $itk_component(equinox) config -textvariable ${var}(EQUINOX)

	    add_short_help $itk_component(ra)  {World Coordinates RA value}
	    add_short_help $itk_component(dec)  {World Coordinates DEC value}
	    add_short_help $itk_component(equinox) {World Coordinates equinox (default: J2000)}
	}

	# min max values
	if {$itk_option(-showminmax)} {
	    # LabelValue(n) widget for the min pixel value
	    itk_component add min {
		util::LabelValue $w_.min \
		    -text "Min:" \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    # LabelValue(n) widget for the max pixel value
	    itk_component add max {
		util::LabelValue $w_.max \
		    -text "Max:" \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    # LabelValue(n) widget for the FITS bitpix value
	    itk_component add bitpix {
		util::LabelValue $w_.bitpix \
		    -text "Bitpix:" \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -relief groove \
		    -anchor e
	    } 
	    blt::table $w_ \
		$itk_component(min)     3,0 -fill x -anchor w \
		$itk_component(max)     3,1 -fill x -anchor w \
		$itk_component(bitpix)  3,2 -fill x -anchor w

	    add_short_help $itk_component(min) {Estimated minimum raw image value}
	    add_short_help $itk_component(max) {Estimated maximum raw image value}
	    add_short_help $itk_component(bitpix) {Raw image FITS data type code}
	}

	# cut level controls
	if {$itk_option(-showcut)} {
	    # LabelEntry(n) widget for the low cut level
	    itk_component add low {
		LabelEntry $w_.low \
		    -text "Low:" \
		    -command [code $this set_cut_levels] \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -anchor e \
		    -relief sunken \
		    -validate real
	    } {
		keep -state
	    }
	    # LabelEntry(n) widget for the high cut level
	    itk_component add high {
		LabelEntry $w_.high \
		    -text "High:" \
		    -command [code $this set_cut_levels] \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth $itk_option(-labelwidth) \
		    -valuewidth $itk_option(-valuewidth) \
		    -anchor e \
		    -relief sunken \
		    -validate real
	    }  {
		keep -state
	    }
	    blt::table $w_ \
		$itk_component(low)     4,0 -fill x -anchor w \
		$itk_component(high)    4,1 -fill x -anchor w \
		$itk_component(lrframe) 4,2 -fill x -anchor w

	    add_short_help $itk_component(low) \
		{Image low cut value, type return after editing value}
	    add_short_help $itk_component(high) \
		{Image high cut value, type return after editing value}
	    add_short_help $itk_component(autocut) \
		{Set the image cut levels using median filtering}
	}

	# image transformation controls
	if {$itk_option(-showtrans)} {
	    # RtdImageTrans(n) widget displaying the rotate, flip and zoom controls
	    itk_component add trans {
		rtd::RtdImageTrans $w_.trans \
		    -labelfont $itk_option(-labelfont) \
		    -valuefont $itk_option(-valuefont) \
		    -labelwidth [max $itk_option(-labelwidth) 5] \
		    -relief flat \
		    -min_scale $itk_option(-min_scale) \
		    -max_scale $itk_option(-max_scale) \
		    -image $itk_option(-image)
	    } {
		keep -state
	    }
	    blt::table $w_ \
		$itk_component(trans)   5,0 -fill x -anchor w -columnspan 2
	}

	blt::table configure $w_ c2 -padx 1m
    }

    
    # set the cut levels when the user types them in and hits return
    
    protected method set_cut_levels {args} {
	set low [$itk_component(low) get] 
	set high [$itk_component(high) get]
	if {[catch {expr $low} msg] || [catch {expr $high} msg]} {
	    error_dialog $msg
	} else {
	    $image_ cut $low $high
	    updateValues
	}
    }


    
    # set the cut levels

    public method cut_level_dialog {} {
	if {[$image_ isclear]} {
	    warning_dialog "No image is currently loaded" $w_
	    return
	}
	utilReUseWidget rtd::RtdImageCut $w_.cut \
	    -image $itk_option(-image) \
	    -shorthelpwin $itk_option(-shorthelpwin) \
	    -transient 1 \
	    -command [code $this updateValues]
    }

    
    # update the cut level display window, if needed

    public method update_cut_window {} {
	if {[winfo exists $w_.cut] && [winfo viewable $w_.cut]} {
	    $w_.cut update_graph
	}
    }


    # set the cut levels automatically using median filtering...
    
    public method auto_set_cut_levels {} {
	busy {$image_ autocut}
	updateValues
    }


    # update the display with the current image values

    public method updateValues {} {
	if {$itk_option(-showobject)} {
	    set s [$image_ object]
	    if {"$s" == ""} {
		set s [$image_ cget -file]
	    }
	    $itk_component(object) config -value $s
	}

	if {$itk_option(-showminmax)} {
	    $itk_component(min) config -value [$image_ min]
	    $itk_component(max) config -value [$image_ max]
	    $itk_component(bitpix) config -value [$image_ bitpix]
	}

	if {$itk_option(-showcut)} {
	    #  avoid conflict with user typing
	    lassign [$image_ cut] low high
	    set f [focus]
	    if {"$f" != "[$itk_component(low) component entry]"} {
		$itk_component(low) config -value $low
	    } 
	    if {"$f" != "[$itk_component(high) component entry]"} {
		$itk_component(high) config -value $high
	    }
	}
	update_cut_window

	if {$itk_option(-showtrans)} {
	    $itk_component(trans) update_trans
	}
    }
    

    # -- options --

    # main RtdImage widget (set by caller)
    itk_option define -image image Image {} {
	set image_ [$itk_option(-image) get_image]
    }

    # Flag: if true, display the object name
    itk_option define -showobject showObject ShowObject 1

    # Flag: if true, display x,y coordinates
    itk_option define -showxy showXy ShowXy 1

    # Flag: if true, display ra,dec coordinates
    itk_option define -showwcs showWcs ShowWcs 1

    # Flag: if true, display the min and max pixel values
    itk_option define -showminmax showMinMax ShowMinMax 1

    # Flag: if true, display the image cut levels.
    itk_option define -showcut showCut ShowCut 1

    # Flag: if true, display the transformation widgets (zoom factor, etc).
    itk_option define -showtrans showTrans ShowTrans 1
    
    
    # Font to use for labels
    itk_option define -labelfont labelFont LabelFont -Adobe-helvetica-bold-r-normal--12*

    # Font to use for values.
    itk_option define -valuefont valueFont ValueFont -Adobe-helvetica-medium-r-normal--12*

    # Font to use for RA,DEC (a, b) labels (symbol).
    itk_option define -wcsfont wcsFont WcsFont -*-symbol-*-*-*-*-14-*-*-*-*-*-*-*

    # set the width for displaying labels
    itk_option define -labelwidth labelWidth LabelWidth 6

    # set the width for displaying values
    itk_option define -valuewidth valueWidth ValueWidth 10

    # set the state to normal/disabled to enable/disable editing
    itk_option define -state state State {normal}

    # optionally specify TopLevelWidget to display short help messages
    itk_option define -shorthelpwin shortHelpWin ShortHelpWin {}

    # minimum allowed scale value
    itk_option define -min_scale min_scale Min_scale -10

    # maximum allowed scale value
    itk_option define -max_scale max_scale Max_scale 20

    # -- protected vars -- 
    
    # internal rtdimage widget for main image
    protected variable image_

    # saved x coordinate for update after image event
    protected variable x_ 0

    # saved y coordinate for update after image event
    protected variable y_ 0
}
