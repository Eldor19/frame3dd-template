
#define the procedures in a separated namespace named Frame3DD
namespace eval Frame3DD {
}


###################################################################################
#      print data in the .dat calculation file
proc Frame3DD::WriteCalculationFile { filename } {
    customlib::InitWriteFile $filename
    
    # Place your writing script here

    customlib::EndWriteFile
}



# DO NOT TOUCH
proc AfterWriteCalcFileGIDProject { filename errorflag } {   
    if { ![info exists gid_groups_conds::doc] } {
        WarnWin [= "Error: data not OK"]
        return
    }    
    set err [catch { Frame3DD::WriteCalculationFile $filename } ret]
    if { $err } {       
        WarnWin [= "Error when preparing data for analysis (%s)" $::errorInfo]
        set ret -cancel-
    }
    return $ret
}


#GiD-tcl event automatically invoked when the calculation is finished, to convert results - DO NOT TOUCH
proc AfterRunCalculation { basename dir problemtypedir where error errorfilename } {
    if { $error == 0 } {
        set filename [file join [lindex $dir 0] $basename].out        
        if { [catch { Frame3DD::TransformResultsToGiD $filename } err] } {
            WarnWin [= "Error %s" $err]
        }
    }
    return
}

proc InitGIDProject { dir } {
    gid_groups_conds::open_conditions menu
}
  

#auxiliary procedure used by TransformResultsToGiD - DO NOT TOUCH
proc Frame3DD::_FileFind { fp text line } {
    set len [string length $text]
    if { [string range $line 0 $len-1] == $text } {
        return 1
    }
    while { ![eof $fp] } {
        gets $fp line           
        if { [string range $line 0 $len-1] == $text } {
            return 1
        }
    }
    return 0
}

#procedure to convert .out file to .post.res - DO NOT TOUCH
proc Frame3DD::TransformResultsToGiD { filename } {
    package require math::linearalgebra
    package require math::interpolate 

    if { ![file exists $filename] } {
        return
    }
    set fp [open $filename r]
    if { $fp == "" } {
        return
    }    
       
    set read_ifxx_files 1 ;#0 first version that only read forces at end, not the whole graph
    set non_numeric_values 0
    set exe_version ""
    set line ""        
    for {set i 0} {$i<13} {incr i} {
        gets $fp line          
        if { $i == 1 } {
            set exe_version [lindex $line 2]
        }
    }    
    set num_nodes [lindex $line 0]
    set num_constraints [lindex $line 2]
    set num_elements [lindex $line 5]
    set num_load_cases [lindex $line 8]
    for { set load_case 1 } { $load_case <= $num_load_cases } {incr load_case } {
        if { [Frame3DD::_FileFind $fp "L O A D   C A S E" $line] } {
            if { $exe_version == "20100105" } {
                # old version
                set displacements_text "J O I N T   D I S P L A C E M E N T S"
            } else {
                set displacements_text "N O D E   D I S P L A C E M E N T S"
            }           
            if { [Frame3DD::_FileFind $fp $displacements_text $line] } {                    
                gets $fp line  
                while { ![eof $fp] } {
                    gets $fp line  
                    set line [string trim $line]
                    if { ![string is digit [string index $line 0]] } {
                        break
                    }
                    lassign $line id dx dy dz rx ry rz
                    if { [string is double -strict $dx] } {
                        set Displacements($id) [list $dx $dy $dz]              
                        set Rotations($id) [list $rx $ry $rz]
                    } else {
                        incr non_numeric_values
                    }
                }
                #to set to 0 0 0 for nodes without explicit displacement value
                for {set id 1} {$id<=$num_nodes} {incr id} {
                    if { [info exists Displacements($id)] } {
                        append values(Displacements) "$id $Displacements($id)\n"
                    } else {
                        append values(Displacements) "$id 0 0 0\n"
                    }
                    if { [info exists Rotations($id)] } {
                        append values(Rotations) "$id $Rotations($id)\n"
                    } else {
                        append values(Rotations) "$id 0 0 0\n"
                    }
                }
                unset -nocomplain Displacements
                unset -nocomplain Rotations
               
                #set interesting_results {Displacements Rotations}
                set interesting_results {Displacements} ;#Rotations are not very interesting
                foreach item $interesting_results {
                    if { [info exists values($item)] } {
                        set result "Result $item Static $load_case Vector OnNodes"
                        set results($result) $values($item)
                    }
                }         
                unset -nocomplain values                
            } else {
                break
            }
            
            set item LocalAxes
            #calculate and store GiD local axes of each element
            foreach {element_id element_n0 element_n1 element_material} [GiD_Info mesh Elements linear] {                    
                set xyz0 [lrange [GiD_Mesh get node $element_n0] 1 end]
                set xyz1 [lrange [GiD_Mesh get node $element_n1] 1 end]
                set x_axis [math::linearalgebra::unitLengthVector [math::linearalgebra::sub_vect $xyz1 $xyz0]]
                lassign [MathUtils::CalculateLocalAxisFromXAxis $x_axis] y_axis z_axis
                set local_axis($element_id,x) $x_axis
                set local_axis($element_id,y) $y_axis
                set local_axis($element_id,z) $z_axis
                set euler_angles [MathUtils::CalculateEulerAnglesFromLocalAxis $x_axis $y_axis $z_axis]
                append values($item) "$element_id $euler_angles\n"
            }       
            set result "Result LocalAxes Static 1 $item OnGaussPoints GP_LINE_1"
            set results($result) $values($item)
            unset -nocomplain values 
            
            if { !$read_ifxx_files } {       
                if { [Frame3DD::_FileFind $fp "F R A M E   E L E M E N T   E N D   F O R C E S" $line] } {                                           
                    gets $fp line  
                    while { ![eof $fp] } {
                        gets $fp line  
                        set line [string trim $line]
                        if { ![string is digit [string index $line 0]] } {
                            break
                        }
                        lassign $line element_id node_id Nx Vy Vz Tx My Mz
                        foreach item {Nx Vy Vz Tx My Mz} {
                            set v [set $item]
                            if { [string is double -strict $v] } {                        
                                set v [expr {-1.0*$v}]
                                append values($item) "$element_id $v\n"
                            } else {
                                incr non_numeric_values
                            }
                        }
                        gets $fp line  
                        set line [string trim $line]
                        lassign $line element_id node_id Nx Vy Vz Tx My Mz
                        foreach item {Nx Vy Vz Tx My Mz} {                        
                            set v [set $item]
                            if { [string is double -strict $v] } {
                                append values($item) " $v\n"
                            } else {
                                incr non_numeric_values
                            }
                        }               
                    }                                                  
                    foreach item {Nx Vy Vz Tx My Mz} {
                        if { [info exists values($item)] } {
                            set axis [string index $item end]
                            if { $axis == "x" } {
                                #represent it as scalar result
                                set result "Result ${item}' Static $load_case Scalar OnGaussPoints GP_LINE_2"
                                set results($result) $values($item)     
                            } else {
                                #represent it as vector result in its local axis direction
                                set result "Result ${item}' Static $load_case Vector OnGaussPoints GP_LINE_2"
                                set vector_values ""
                                foreach {element_id e0 e1} $values($item) {
                                    set vector_0 [math::linearalgebra::scale_vect [expr {-1.0*$e0}] $local_axis($element_id,$axis)]
                                    set vector_1 [math::linearalgebra::scale_vect [expr {-1.0*$e1}] $local_axis($element_id,$axis)]
                                    append vector_values "$element_id $vector_0 $e0\n $vector_1 $e1\n"
                                }
                                set results($result) $vector_values    
                            }
                        }    
                    }   
                    unset -nocomplain values                  
                } else {
                    break
                }
            }
            if { [Frame3DD::_FileFind $fp "R E A C T I O N S" $line] } {                                
                gets $fp line  
                while { ![eof $fp] } {
                    gets $fp line  
                    set line [string trim $line]
                    if { ![string is digit [string index $line 0]] } {
                        break
                    }
                    lassign $line id fx fy fz mx my mz
                    if { [string is double -strict $fx] } {
                        append values(Reaction_forces) "$id $fx $fy $fz\n"
                        append values(Reaction_moments) "$id $mx $my $mz\n"
                    } else {
                        incr non_numeric_values
                    }
                }   
                foreach item {Reaction_forces Reaction_moments} {
                    if { [info exists values($item)] } {
                        set result "Result $item Static $load_case Vector OnNodes"
                        set results($result) $values($item) 
                    }
                }                
                unset -nocomplain values
            } else {
                break
            }   
        } else {
            break
        }
    }

    if { [Frame3DD::_FileFind $fp "M A S S   N O R M A L I Z E D   M O D E   S H A P E S" $line] } {
        gets $fp line ;#convergence tolerance
        while { ![eof $fp] } {
            gets $fp line
            if { [string range $line 0 34] == "M A T R I X    I T E R A T I O N S:"} {
                break
            }
            set i_mode [string range [lindex $line 1] 0 end-1]
            set frequency [lindex $line 3]
            set period [lindex $line 6]
            gets $fp line ;#X- modal participation factor
            gets $fp line ;#Y- modal participation factor
            gets $fp line ;#Z- modal participation factor
            gets $fp line ;#Joint   X-dsp       Y-dsp       Z-dsp       X-rot       Y-rot       Z-rot
            for { set i 1 } {$i <= $num_nodes } { incr i } {
                gets $fp line
                lassign $line id dx dy dz rx ry rz
                append values(Displacements) "$id $dx $dy $dz\n"
                append values(Rotations) "$id $rx $ry $rz\n"
            }
            #set interesting_results {Displacements Rotations}
            set interesting_results {Displacements} ;#Rotations are not very interesting
            foreach item $interesting_results {
                if { [info exists values($item)] } {
                    set result "Result Modal_${item}_${frequency}_Hz Dynamic 0 Vector OnNodes"
                    set results($result) $values($item) 
                }
            }
            unset -nocomplain values
        }
    }

    close $fp
    
    if { $read_ifxx_files } {  
        # read the *.ifXX files for internal force results along the elements    
        set interesting_results {Nx Vy Vz Tx My Mz}
        set num_spans 10
        set num_gauss_points [expr {$num_spans+1}]
        for { set load_case 1 } { $load_case <= $num_load_cases } {incr load_case } {
            set filename_ifx [file rootname $filename].if[format %02d $load_case]
            if { [file exists $filename_ifx] } {
                set fp [open $filename_ifx r]
                #jump header
                for {set i 0} {$i<8} {incr i} {
                    gets $fp line 
                }
                for {set i_element 0} {$i_element<$num_elements} {incr i_element} {
                    gets $fp line ;##        Elmnt        N1        N2 ...     
                    gets $fp line           
                    lassign $line dummy dummy element_id        n1        n2 x1 y1 z1 x2 y2 z2 nx
                    set element_length [math::linearalgebra::norm_two [math::linearalgebra::sub_vect [list $x1 $y1 $z1] [list $x2 $y2 $z2]]]
                    gets $fp line
                    gets $fp line ;# MAXIMUM ...
                    gets $fp line ;## MINIMUM ...
                    gets $fp line ;##.x ...
                    set xs [list]
                    foreach item $interesting_results {
                        set ${item}s [list]
                    }
                    for {set ix 0} {$ix<$nx} {incr ix} {
                        gets $fp line
                        lassign $line x Nx Vy Vz Tx My Mz dx dy dz rx
                        set relative_x [expr {double($x)/$element_length}]
                        lappend xs $relative_x
                        foreach item $interesting_results {
                            lappend ${item}s [set $item]
                        }
                    }
                    foreach item $interesting_results {
                        append values($item) "$element_id"
                        set coefficients [math::interpolate::prepare-cubic-splines $xs [set ${item}s]]
                        for {set i_pt 0} {$i_pt<=$num_spans} {incr i_pt} {
                            set x [expr {double($i_pt)/$num_spans}]
                            if { $x < [lindex $xs 0] } {
                                set x [lindex $xs 0]
                            } elseif { $x > [lindex $xs end] } {
                                set x [lindex $xs end]
                            }
                            set v [math::interpolate::interp-cubic-splines $coefficients $x]
                            append values($item) " $v\n"
                        }                    
                    }
                    gets $fp line ;##--- ...
                    gets $fp line
                    gets $fp line
                }
                close $fp
                foreach item $interesting_results {
                    set axis [string index $item end]
                    if { $axis == "x" } {
                        #represent it as scalar result
                        set result "Result ${item}' Static $load_case Scalar OnGaussPoints GP_LINE_$num_gauss_points"
                        set results($result) $values($item)
                    } else {
                        #represent it as vector result in its local axis direction
                        #My Mz : momentum vector represents a rotation in the normal plane
                        if { $item == "My" } {
                            #represent it in the plane x'-z'
                            set axis_draw z
                            set sign_draw -1.0
                        } elseif { $item == "Mz" } {
                            #represent it in the plane x'-y'
                            set axis_draw y
                            set sign_draw -1.0
                        } else {
                            #Nx Vy Vz Tx
                            set axis_draw $axis
                            set sign_draw 1.0
                        }
                        set result "Result ${item}' Static $load_case Vector OnGaussPoints GP_LINE_$num_gauss_points"
                        set vector_values ""
                        set pos 0
                        for {set i_element 0} {$i_element<$num_elements} {incr i_element} {
                            set element_id [lindex $values($item) $pos]
                            append vector_values $element_id
                            incr pos
                            set vs [lrange $values($item) $pos [expr {$pos+$num_gauss_points-1}]]
                            incr pos $num_gauss_points
                            foreach v $vs {
                                set vector [math::linearalgebra::scale_vect [expr {$sign_draw*$v}] $local_axis($element_id,$axis_draw)]
                                append vector_values " $vector $v\n" ;#GiD trick last extra value is modulus but with sign
                            }                        
                        }
                        set results($result) $vector_values    
                    }
                }
                unset -nocomplain values
            }
        }
    }
    ####
    
    if { [array size results] } {
        set filename_post [file rootname $filename].post.res
        set fout [open $filename_post w]
        if { $fout == "" } {       
            return
        }
        set units(Displacements) [GidGetUnitStr length]
        set units(Rotations) [GidGetUnitStr angle]
        set units(Nx') [GidGetUnitStr strength]
        set units(Vy') [GidGetUnitStr strength]
        set units(Vz') [GidGetUnitStr strength]
        set units(Tx') [GidGetUnitStr momentum]
        set units(My') [GidGetUnitStr momentum]
        set units(Mz') [GidGetUnitStr momentum]
        set units(Reaction_forces) [GidGetUnitStr strength]
        set units(Reaction_moments) [GidGetUnitStr momentum]

        puts $fout "GiD Post Results File 1.0"
        puts $fout ""
        foreach num [list 2 $num_gauss_points] {
            puts $fout "GaussPoints GP_LINE_$num ElemType Linear"
            puts $fout "Number Of Gauss Points: $num"
            puts $fout "Nodes included"
            puts $fout "Natural Coordinates: Internal"
            puts $fout "End gausspoints"
        }
        
        foreach result [array names results] {
            puts $fout ""
            puts $fout $result
            set name [lindex $result 1]
            if { [string range $name 0 4] == "Modal" } {
                set name [lindex [split $name _] 1]
            }
            if { [info exists units($name)] } {
                puts $fout "Unit $units($name)" 
            }
            puts $fout Values 
            puts -nonewline $fout $results($result)
            puts $fout "End values"  
        }
        close $fout
        unset -nocomplain results
    }
    
    if { $non_numeric_values } {
        WarnWin [= "Error, there are 'not a number' results"]
    }
    return
}

######################################################################
#  auxiliary procs invoked from the tree (see .spd xml description)
proc Frame3DD::GetMaterialsList { domNode args } {    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set image material
    set result [list]
    foreach dom_material [$dom_materials childNodes] {
        set name [$dom_material @name] 
        lappend result [list 0 $name $name $image 1]
    }
    return [join $result ,]
}

proc Frame3DD::EditDatabaseList { domNode dict boundary_conds args } {
    set has_container ""
    set database materials    
    set title [= "User defined"]      
    set list_name [$domNode @n]    
    set x_path {//container[@n="materials"]}
    set dom_materials [$domNode selectNodes $x_path]
    if { $dom_materials == "" } {
        error [= "xpath '%s' not found in the spd file" $x_path]
    }
    set primary_level material
    if { [dict exists $dict $list_name] } {
        set xps $x_path
        append xps [format_xpath {/blockdata[@n=%s and @name=%s]} $primary_level [dict get $dict $list_name]]
    } else { 
        set xps "" 
    }
    set domNodes [gid_groups_conds::edit_tree_parts_window -accepted_n $primary_level -select_only_one 1 $boundary_conds $title $x_path $xps]          
    set dict ""
    if { [llength $domNodes] } {
        set domNode [lindex $domNodes 0]
        if { [$domNode @n] == $primary_level } {      
            dict set dict $list_name [$domNode @name]
        }
    }
    return [list $dict ""]
}
