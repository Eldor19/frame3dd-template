
#define the procedures in a separated namespace named Frame3DD
namespace eval Frame3DD {
}


###################################################################################
#      print data in the .dat calculation file
proc Frame3DD::WriteCalculationFile { filename } {
    customlib::InitWriteFile $filename
    
    # Place your writing script here
    customlib::WriteString "Input Data file for Frame3DD - 3D structural frame analysis\
    ([gid_groups_conds::give_active_unit F], [gid_groups_conds::give_active_unit L],\
    [gid_groups_conds::give_active_unit M], [gid_groups_conds::give_active_unit T],\
    [gid_groups_conds::give_active_unit Temp], [gid_groups_conds::give_active_unit Angle] [gid_groups_conds::give_active_unit P])" 

    #################### COORDINATES ############################ 
    customlib::WriteString ""
    customlib::WriteString "# node data"
    customlib::WriteString "[GiD_Info Mesh NumNodes] # number of nodes"
    customlib::WriteString "#.node\t x\t\ty\t\tz\t\tr\t units: [gid_groups_conds::give_active_unit L]"
    customlib::WriteString ""
    customlib::WriteCoordinates "%5d %14.5e %14.5e %14.5e\t0.0\n"

    #################### Restraints #############################
    customlib::WriteString ""
    customlib::WriteString "# reaction data"
    set restraints_list [list "restraints"]
    set restraints_formats [list {"%5d\t" "node" "id"} {"%1d " "property" "fx"} {"%1d " "property" "fy"
    } {"%1d " "property" "fz"} {"%1d  " "property" "mx"} {"%1d  " "property" "my"} {"%1d " "property" "mz"}]
    set number_of_restraints [customlib::GetNumberOfNodes $restraints_list]
    customlib::WriteString "$number_of_restraints # number of nodes with reactions"
    customlib::WriteString "#.node\t x y z xx yy zz\t 1=fixed, 0=free"
    customlib::WriteString ""
    customlib::WriteNodes $restraints_list $restraints_formats 
    customlib::WriteString ""

    ################### Frame Data ############################## 
    
    # customlib::WriteString ""
    # customlib::WriteString "# frame element data"
    # set frames_list [list "frame_data"]  
    # ###################################################  change later to frame_data (changed .spd!)
    # customlib::InitMaterials $frames_list 
    # set frame_format [list {"%5d" "element" "id"} {"%5d" "element" "connectivities"}  {"%13.5e" "property" "Ax"
    # } {"%13.5e" "property" "Asy"} {"%13.5e" "property" "Asz"} {"%13.5e" "property" "Jxx"} {"%13.5e" "property" "Iyy"
    # } {"%13.5e" "property" "Izz"} {"%13.5e" "material" "E"} {"%13.5e" "material" "G"} {"%13.5e" "property" "roll"
    # } {"%13.5e" "material" "Density"}]
    # #set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats]
    # customlib::WriteString "[GiD_Info Mesh NumElements] # number of frame elements"
    # customlib::WriteString "#   e\t n1    n2   Ax\t\t Asy\t      Asz\t   Jxx\t   \tIyy\t     Izz\t    E\t        G\t     roll\t    density"
    # customlib::WriteString "#   .\t .     .    [gid_groups_conds::give_active_unit L]^2\t [gid_groups_conds::give_active_unit L]^2\t       [gid_groups_conds::give_active_unit L]^2\
    #     \t    [gid_groups_conds::give_active_unit L]^4\t  [    gid_groups_conds::give_active_unit L]^4\t      [gid_groups_conds::give_active_unit L]^4\t    \
    #     [gid_groups_conds::give_active_unit P]\t\t [gid_groups_conds::give_active_unit P]\t     [gid_groups_conds::give_active_unit Angle]\t   [gid_groups_conds::give_active_unit M/L^3]"
    # customlib::WriteString ""
    # customlib::WriteConnectivities $frames_list $frame_format 
    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/condition\[@n='frame_data'\]/group"
    set groups [$document selectNodes $xpath]
    set number_of_elements 0
    set formats_dict [dict create ]
    foreach group $groups {
        set group_name [get_domnode_attribute $group n]
        set Ax_node [$group selectNodes "./value\[@n = 'Ax'\]"]
        set Asy_node [$group selectNodes "./value\[@n = 'Asy'\]"]
        set Asz_node [$group selectNodes "./value\[@n = 'Asz'\]"]
        set Jxx_node [$group selectNodes "./value\[@n = 'Jxx'\]"]
        set Iyy_node [$group selectNodes "./value\[@n = 'Iyy'\]"]
        set Izz_node [$group selectNodes "./value\[@n = 'Izz'\]"]
        set roll_node [$group selectNodes "./value\[@n = 'roll'\]"]

        # material
        set mat_node [$group selectNodes "./value\[@n = 'material'\]"]
        set mat_name [get_domnode_attribute $mat_node v]
        set xpath_density  "/Frame3DD_default/container\[@n='materials'\]/blockdata\[@name='$mat_name'\]/value\[@n='Density'\]"
        set xpath_E  "/Frame3DD_default/container\[@n='materials'\]/blockdata\[@name='$mat_name'\]/value\[@n='E'\]"
        set xpath_G  "/Frame3DD_default/container\[@n='materials'\]/blockdata\[@name='$mat_name'\]/value\[@n='G'\]"

        set density_node [$document selectNodes $xpath_density]
        set E_node [$document selectNodes $xpath_E]
        set G_node [$document selectNodes $xpath_G]


        set format "%5d %5d %5d [gid_groups_conds::convert_value_to_active $Ax_node] [gid_groups_conds::convert_value_to_active $Asy_node] \
        [gid_groups_conds::convert_value_to_active $Asz_node] [gid_groups_conds::convert_value_to_active $Jxx_node] \
        [gid_groups_conds::convert_value_to_active $Iyy_node] [gid_groups_conds::convert_value_to_active $Izz_node] \
        [gid_groups_conds::convert_value_to_active $E_node] [gid_groups_conds::convert_value_to_active $G_node] [gid_groups_conds::convert_value_to_active $roll_node] \
        [gid_groups_conds::convert_value_to_active $density_node]\n"
        set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
    }

    set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats_dict]
    customlib::WriteString "$number_of_elements # number of frame elements"
    customlib::WriteString "#   e\t n1    n2   Ax\t Asy\t Asz\t Jxx\t Iyy\t Izz\t E\t G\t roll\t density"
    customlib::WriteString "#   .\t .     .    [gid_groups_conds::give_active_unit L]^2\t [gid_groups_conds::give_active_unit L]^2\t [gid_groups_conds::give_active_unit L]^2\
        \t [gid_groups_conds::give_active_unit L]^4\t [gid_groups_conds::give_active_unit L]^4\t  [gid_groups_conds::give_active_unit L]^4\t \
    [gid_groups_conds::give_active_unit P]\t [gid_groups_conds::give_active_unit P]\t [gid_groups_conds::give_active_unit Angle]\t [gid_groups_conds::give_active_unit M/L^3]"
    customlib::WriteString ""
    GiD_WriteCalculationFile connectivities -elemtype Linear  $formats_dict
    customlib::WriteString ""
        




    ###################################### Options ###############################################
    #set document [$::gid_groups_conds::doc documentElement]
    #set xpath "/frame3dd_data/container\[@n = 'Options' \]/value\[@n = 'incl_shear_def' \]"
    #set xml_node [$document selectNodes $xpath]
    #set shear_deformation [get_domnode_attribute $xml_node v]

    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/container\[@n = 'Options' \]/value\[@n = 'incl_shear_def' \]"
    set xml_node [$document selectNodes $xpath]
    set shear_deformation [get_domnode_attribute $xml_node v]

    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/container\[@n = 'Options' \]/value\[@n = 'incl_geo_stiff' \]"
    set xml_node [$document selectNodes $xpath]
    set geo_stiff [get_domnode_attribute $xml_node v]

    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/container\[@n = 'Options' \]/value\[@n = 'mesh_def_factor' \]"
    set xml_node [$document selectNodes $xpath]
    set mesh_def_factor [get_domnode_attribute $xml_node v]

    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/container\[@n = 'Options' \]/value\[@n = 'zoom' \]"
    set xml_node [$document selectNodes $xpath]
    set zoom [get_domnode_attribute $xml_node v]

    set document [$::gid_groups_conds::doc documentElement]
    set xpath "/Frame3DD_default/container\[@n = 'Options' \]/value\[@n = 'x increment' \]"
    set xml_node [$document selectNodes $xpath]
    set x_incr [get_domnode_attribute $xml_node v]


    customlib::WriteString ""
    customlib::WriteString "# Options"
    customlib::WriteString "$shear_deformation \t # 1=Do, 0=Don't include shear deformation effects"
    customlib::WriteString "$geo_stiff \t # 1=Do, 0=Don't include geometric stiffness effects"
    customlib::WriteString "$mesh_def_factor \t # Mesh exaggeration factor"
    customlib::WriteString "$zoom \t # zoom scale for 3D plotting"
    customlib::WriteString "$x_incr \t # x-axis increment for internal forces. If dx is -1 then internal force calculations are skipped."
    customlib::WriteString ""

    ######################Load Cases###############
    set xpath "/Frame3DD_default/container\[@n = 'load_cases' \]"  
    # braucht man das /blockdata hinten dran?
    set xml_nodes [$document selectNodes $xpath]
    set num_cases 0 
    foreach load [$xml_nodes childNodes] { incr num_cases }
    customlib::WriteString "$num_cases # number of static load cases"
    set i_case 0

    # mainloop
    set xpath "/Frame3DD_default/container\[@n = 'load_cases' \]/blockdata"  
    set xml_nodes [$document selectNodes $xpath]
    #set xpath "/Frame3DD_default/container\[@n = 'load_cases' \]"  
    # for inside the loop

    foreach load_case $xml_nodes {
        incr i_case
        customlib::WriteString "# Begin load case $i_case of $num_cases"
        customlib::WriteString ""

        # Gravity
        set xpath "./container\[@n = 'gravity' \]/value\[@n = 'g_x' \]"
        set xml_node_x [$load_case selectNodes $xpath]
        # hier ganz wichtig, dass das erste Argument $loadcase ist!!!!!
        set g_x [get_domnode_attribute $xml_node_x v]

        set xpath "./container\[@n = 'gravity' \]/value\[@n = 'g_y' \]"
        set xml_node_y [$load_case selectNodes $xpath]
        # hier ganz wichtig, dass das erste Argument $loadcase ist!!!!!
        set g_y [get_domnode_attribute $xml_node_y v]

        set xpath "./container\[@n = 'gravity' \]/value\[@n = 'g_z' \]"
        set xml_node_z [$load_case selectNodes $xpath]
        # hier ganz wichtig, dass das erste Argument $loadcase ist!!!!!
        set g_z [get_domnode_attribute $xml_node_z v]
        customlib::WriteString "# gravitational acceleration for self-weight loading (global)"
        customlib::WriteString "# g_x\t g_y\t g_z"
        customlib::WriteString "# [gid_groups_conds::give_active_unit L/T^2]\t [gid_groups_conds::give_active_unit L/T^2]\t [gid_groups_conds::give_active_unit L/T^2]"
        customlib::WriteString " [gid_groups_conds::convert_value_to_active $xml_node_x]\t [gid_groups_conds::convert_value_to_active $xml_node_y]\t [gid_groups_conds::convert_value_to_active $xml_node_z]"
        customlib::WriteString ""

        # concentrated loads
        set xpath "./condition\[@n='concentrated load'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
        set group_name [get_domnode_attribute $group n]
        set fx_node [$group selectNodes "./value\[@n = 'fx'\]"]
        set fx_value [get_domnode_attribute $fx_node v]
        set fy_node [$group selectNodes "./value\[@n = 'fy'\]"]
        set fy_value [get_domnode_attribute $fy_node v]
        set fz_node [$group selectNodes "./value\[@n = 'fz'\]"]
        set fz_value [get_domnode_attribute $fz_node v]
        set mx_node [$group selectNodes "./value\[@n = 'mx'\]"]
        set mx_value [get_domnode_attribute $fx_node v]
        set my_node [$group selectNodes "./value\[@n = 'my'\]"]
        set my_value [get_domnode_attribute $my_node v]
        set mz_node [$group selectNodes "./value\[@n = 'mz'\]"]
        set mz_value [get_domnode_attribute $mz_node v]
        set format "%5d [gid_groups_conds::convert_value_to_active $fx_node] [gid_groups_conds::convert_value_to_active $fy_node] \
            [gid_groups_conds::convert_value_to_active $fz_node] [gid_groups_conds::convert_value_to_active $mx_node] \
            [gid_groups_conds::convert_value_to_active $my_node] [gid_groups_conds::convert_value_to_active $mz_node]\n"
        set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_nodes [GiD_WriteCalculationFile nodes -count  $formats_dict]
        customlib::WriteString "$number_of_nodes # number of loaded nodes"
        
        if {$number_of_nodes > 0} {
            customlib::WriteString "# n [gid_groups_conds::give_active_unit F]  [gid_groups_conds::give_active_unit F] [gid_groups_conds::give_active_unit F]\
            [gid_groups_conds::give_active_unit F*L]  [gid_groups_conds::give_active_unit F*L]  [gid_groups_conds::give_active_unit F*L]"
        customlib::WriteString ""
        GiD_WriteCalculationFile nodes  $formats_dict
        customlib::WriteString ""

        }

        # uniform load
        set xpath "./condition\[@n='uniform load'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
            set group_name [get_domnode_attribute $group n]
            set fx_node [$group selectNodes "./value\[@n = 'fx'\]"]
            set fx_value [get_domnode_attribute $fx_node v]
            set fy_node [$group selectNodes "./value\[@n = 'fy'\]"]
            set fy_value [get_domnode_attribute $fy_node v]
            set fz_node [$group selectNodes "./value\[@n = 'fz'\]"]
            set fz_value [get_domnode_attribute $fz_node v]

            set format "%5d [gid_groups_conds::convert_value_to_active $fx_node] [gid_groups_conds::convert_value_to_active $fy_node] \
            [gid_groups_conds::convert_value_to_active $fz_node] \n"
            set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats_dict]
        customlib::WriteString "$number_of_elements # number of uniform loads"
        
        if {$number_of_elements > 0} {
            customlib::WriteString "# e [gid_groups_conds::give_active_unit F/L]  [gid_groups_conds::give_active_unit F/L]\
         [gid_groups_conds::give_active_unit F/L]"
        customlib::WriteString ""
        GiD_WriteCalculationFile elements -elemtype Linear  $formats_dict
        customlib::WriteString ""
        }

        # trapezoidally distributed load
        set xpath "./condition\[@n='trapezoidal load'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
            set group_name [get_domnode_attribute $group n]
            set p1_x_node [$group selectNodes "./value\[@n = 'p1_x'\]"]
            set p1_x_value [get_domnode_attribute $p1_x_node v]
            set p2_x_node [$group selectNodes "./value\[@n = 'p2_x'\]"]
            set p2_x_value [get_domnode_attribute $p2_x_node v]
            set p1_fx_node [$group selectNodes "./value\[@n = 'p1_fx'\]"]
            set p1_fx_value [get_domnode_attribute $p1_fx_node v]
            set p2_fx_node [$group selectNodes "./value\[@n = 'p2_fx'\]"]
            set p2_fx_value [get_domnode_attribute $p2_fx_node v]

            set p1_y_node [$group selectNodes "./value\[@n = 'p1_y'\]"]
            set p1_y_value [get_domnode_attribute $p1_y_node v]
            set p2_y_node [$group selectNodes "./value\[@n = 'p2_y'\]"]
            set p2_y_value [get_domnode_attribute $p2_y_node v]
            set p1_fy_node [$group selectNodes "./value\[@n = 'p1_fy'\]"]
            set p1_fy_value [get_domnode_attribute $p1_fy_node v]
            set p2_fy_node [$group selectNodes "./value\[@n = 'p2_fy'\]"]
            set p2_fy_value [get_domnode_attribute $p2_fy_node v]

            set p1_z_node [$group selectNodes "./value\[@n = 'p1_z'\]"]
            set p1_z_value [get_domnode_attribute $p1_z_node v]
            set p2_z_node [$group selectNodes "./value\[@n = 'p2_z'\]"]
            set p2_z_value [get_domnode_attribute $p2_z_node v]
            set p1_fz_node [$group selectNodes "./value\[@n = 'p1_fz'\]"]
            set p1_fz_value [get_domnode_attribute $p1_fz_node v]
            set p2_fz_node [$group selectNodes "./value\[@n = 'p2_fz'\]"]
            set p2_fz_value [get_domnode_attribute $p2_fz_node v]
            
            set format "%5d   [gid_groups_conds::convert_value_to_active $p1_x_node] [gid_groups_conds::convert_value_to_active $p2_x_node] \
            [gid_groups_conds::convert_value_to_active $p1_fx_node] [gid_groups_conds::convert_value_to_active $p2_fx_node] \t# location and loading - local x-axis\n\
                \t[gid_groups_conds::convert_value_to_active $p1_y_node] [gid_groups_conds::convert_value_to_active $p2_y_node] \
            [gid_groups_conds::convert_value_to_active $p1_fy_node] [gid_groups_conds::convert_value_to_active $p2_fy_node] \t# location and loading - local y-axis\n\
                \t[gid_groups_conds::convert_value_to_active $p1_z_node] [gid_groups_conds::convert_value_to_active $p2_z_node] \
            [gid_groups_conds::convert_value_to_active $p1_fz_node] [gid_groups_conds::convert_value_to_active $p2_fz_node] \t# location and loading - local z-axis\n"
            set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats_dict]
        #customlib::WriteString ""
        customlib::WriteString "$number_of_elements # number of trapezoidal loads"
        
        if {$number_of_elements > 0} {
            customlib::WriteString "# e x1:[gid_groups_conds::give_active_unit L]  x2:[gid_groups_conds::give_active_unit F]\
         w1:[gid_groups_conds::give_active_unit F/L]  w2:[gid_groups_conds::give_active_unit F/L]"
        customlib::WriteString ""
        GiD_WriteCalculationFile elements -elemtype Linear  $formats_dict
        customlib::WriteString ""

        }
        # internal concentrated loads
        set xpath "./condition\[@n='interior load'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
            set group_name [get_domnode_attribute $group n]
            set fx_node [$group selectNodes "./value\[@n = 'fx'\]"]
            set fx_value [get_domnode_attribute $fx_node v]
            set fy_node [$group selectNodes "./value\[@n = 'fy'\]"]
            set fy_value [get_domnode_attribute $fy_node v]
            set fz_node [$group selectNodes "./value\[@n = 'fz'\]"]
            set fz_value [get_domnode_attribute $fz_node v]
            set x_node [$group selectNodes "./value\[@n = 'x'\]"]
            set x_value [get_domnode_attribute $x_node v]
            
            set format "%5d    [gid_groups_conds::convert_value_to_active $fx_node]  [gid_groups_conds::convert_value_to_active $fy_node] \
            [gid_groups_conds::convert_value_to_active $fz_node] [gid_groups_conds::convert_value_to_active $x_node] \n"
            set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats_dict]

        customlib::WriteString "$number_of_elements # number of internal concentrated loads"
        
        if {$number_of_elements > 0} {
            customlib::WriteString "# e Px:[gid_groups_conds::give_active_unit F]  Py:[gid_groups_conds::give_active_unit F]\
         Pz:[gid_groups_conds::give_active_unit F] x:[gid_groups_conds::give_active_unit L]"
        customlib::WriteString ""
        GiD_WriteCalculationFile elements -elemtype Linear  $formats_dict
        customlib::WriteString ""
        }

        #temperature loads
        set xpath "./condition\[@n='temperature load'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
            set group_name [get_domnode_attribute $group n]
            set alpha_node [$group selectNodes "./value\[@n = 'alpha'\]"]
            set alpha_value [get_domnode_attribute $alpha_node v]
            set hy_node [$group selectNodes "./value\[@n = 'hy'\]"]
            set hy_value [get_domnode_attribute $hy_node v]
            set hz_node [$group selectNodes "./value\[@n = 'hz'\]"]
            set hz_value [get_domnode_attribute $hz_node v]
            set typ_node [$group selectNodes "./value\[@n = 'Ty+'\]"]
            set typ_value [get_domnode_attribute $typ_node v]
            set tym_node [$group selectNodes "./value\[@n = 'Ty-'\]"]
            set tym_value [get_domnode_attribute $tym_node v]
            set tzp_node [$group selectNodes "./value\[@n = 'Tz+'\]"]
            set tzp_value [get_domnode_attribute $tzp_node v]
            set tzm_node [$group selectNodes "./value\[@n = 'Tz-'\]"]
            set tzm_value [get_domnode_attribute $tzm_node v]

            set format "%5d    [gid_groups_conds::convert_value_to_active $alpha_node] [gid_groups_conds::convert_value_to_active $hy_node] \
            [gid_groups_conds::convert_value_to_active $hz_node] [gid_groups_conds::convert_value_to_active $typ_node] \
            [gid_groups_conds::convert_value_to_active $tym_node] [gid_groups_conds::convert_value_to_active $tzp_node] \
            [gid_groups_conds::convert_value_to_active $tzm_node] \n"
            set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_elements [GiD_WriteCalculationFile elements -count -elemtype Linear $formats_dict]
        customlib::WriteString "$number_of_elements # number of temperature loads"
        
        if {$number_of_elements > 0} {
            customlib::WriteString "# e alpha:[gid_groups_conds::give_active_unit 1/Temp]  hy:[gid_groups_conds::give_active_unit L]\
         hz:[gid_groups_conds::give_active_unit L] Ty+:[gid_groups_conds::give_active_unit Temp]  Ty-:[gid_groups_conds::give_active_unit Temp]\
         Tz+:[gid_groups_conds::give_active_unit Temp]  Tz-:[gid_groups_conds::give_active_unit Temp]"
        customlib::WriteString ""
        GiD_WriteCalculationFile elements -elemtype Linear  $formats_dict
        customlib::WriteString ""
        }

        #prescribed displacements
        set xpath "./condition\[@n='nodal_disps'\]/group"
        set groups [$load_case selectNodes $xpath]
        set number_of_elements 0
        set formats_dict [dict create ]
        foreach group $groups {
        set group_name [get_domnode_attribute $group n]
        set ux_node [$group selectNodes "./value\[@n = 'ux'\]"]
        set ux_value [get_domnode_attribute $ux_node v]
        set uy_node [$group selectNodes "./value\[@n = 'uy'\]"]
        set uy_value [get_domnode_attribute $uy_node v]
        set uz_node [$group selectNodes "./value\[@n = 'uz'\]"]
        set uz_value [get_domnode_attribute $uz_node v]
        set rot_x_node [$group selectNodes "./value\[@n = 'rot_x'\]"]
        set rot_x_value [get_domnode_attribute $rot_x_node v]
        set rot_y_node [$group selectNodes "./value\[@n = 'rot_y'\]"]
        set rot_y_value [get_domnode_attribute $rot_y_node v]
        set rot_z_node [$group selectNodes "./value\[@n = 'rot_z'\]"]
        set rot_z_value [get_domnode_attribute $rot_z_node v]
        set format "%5d [gid_groups_conds::convert_value_to_active $ux_node] [gid_groups_conds::convert_value_to_active $uy_node] \
        [gid_groups_conds::convert_value_to_active $uz_node] [gid_groups_conds::convert_value_to_active $rot_x_node] \
        [gid_groups_conds::convert_value_to_active $rot_y_node] [gid_groups_conds::convert_value_to_active $rot_z_node]\n"
        set formats_dict [dict merge $formats_dict [dict create $group_name $format]]
        }

        set number_of_nodes [GiD_WriteCalculationFile nodes -count  $formats_dict]
        customlib::WriteString "$number_of_nodes # number of nodes with prescribed displacements"
        
        if {$number_of_nodes > 0} {
            customlib::WriteString "# n   Dx:[gid_groups_conds::give_active_unit L]  Dy:[gid_groups_conds::give_active_unit L]  Dz:[gid_groups_conds::give_active_unit L]\
            Dxx:[gid_groups_conds::give_active_unit Angle]  Dyy:[gid_groups_conds::give_active_unit Angle]  Dzz:[gid_groups_conds::give_active_unit Angle]"
        customlib::WriteString ""
        GiD_WriteCalculationFile nodes  $formats_dict
        customlib::WriteString ""
        }
    
        customlib::WriteString "# End load case $i_case of $num_cases"
        customlib::WriteString ""
    }




    customlib::WriteString "0 # number of dynamic modes"

    customlib::WriteString "# End Input file."
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
