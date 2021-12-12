
###################################################################################
#      print data in the .dat calculation file (instead of a classic .bas template)
proc Cmas2d::WriteCalculationFile { filename } {
    customlib::InitWriteFile $filename
    set elements_conditions [list "Shells"]
    # This instruction is mandatory for using materials
    customlib::InitMaterials $elements_conditions active
    customlib::WriteString "Otto"
    customlib::WriteString "=================================================================="
    customlib::WriteString "                        General Data File"    
    customlib::WriteString "=================================================================="
    customlib::WriteString "Units:"
    customlib::WriteString "length [gid_groups_conds::give_active_unit L] mass [gid_groups_conds::give_active_unit M]"
    customlib::WriteString "Number of elements and nodes:"
    customlib::WriteString "[GiD_Info Mesh NumElements] [GiD_Info Mesh NumNodes]"    
    customlib::WriteString ""
    customlib::WriteString "................................................................."    
    #################### COORDINATES ############################ 
    set units_mesh [gid_groups_conds::give_mesh_unit]
    customlib::WriteString ""
    customlib::WriteString "Coordinates:"
    customlib::WriteString "  Node        X $units_mesh               Y $units_mesh"
    # Write all nodes of the model, and it's coordinates
    # Check documentation to write nodes from an specific condition
    
    # 2D case
    customlib::WriteCoordinates "%5d %14.5e %14.5e%.0s\n"
    # Example for 3D case
    #customlib::WriteCoordinates "%5d %14.5e %14.5e %14.5e\n"
    #################### CONNECTIVITIES ############################    
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    customlib::WriteString "Connectivities:"
    customlib::WriteString "    Element    Node(1)   Node(2)   Node(3)     Material"
    set element_formats [list {"%10d" "element" "id"} {"%10d" "element" "connectivities"} {"%10d" "material" "MID"}]
    customlib::WriteConnectivities $elements_conditions $element_formats active 
    #################### MATERIALS ############################
    set num_materials [customlib::GetNumberOfMaterials used]
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    customlib::WriteString "Materials:"
    customlib::WriteString $num_materials
    customlib::WriteString "Material      Surface density [gid_groups_conds::give_active_unit M/L^2]"
    customlib::WriteMaterials [list {"%4d" "material" "MID"} {"%13.5e" "material" "Density"}] used active
    #################### CONCENTRATE WEIGHTS ############################
    customlib::WriteString ""
    customlib::WriteString "................................................................."
    customlib::WriteString ""
    set condition_list [list "Point_Weight"]
    set condition_formats [list {"%1d" "node" "id"} {"%13.5e" "property" "Weight"}]
    set number_of_conditions [customlib::GetNumberOfNodes $condition_list]
    customlib::WriteString "Concentrate Weights:"
    customlib::WriteString $number_of_conditions
    customlib::WriteString "Node   Mass [gid_groups_conds::give_active_unit M]"
    customlib::WriteNodes $condition_list $condition_formats "" active
    customlib::EndWriteFile ;#finish writting
}
