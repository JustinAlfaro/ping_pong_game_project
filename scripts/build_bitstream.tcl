# build_bitstream.tcl
# Abre el proyecto, re-sintetiza si hay cambios, implementa y escribe bitstream.
# Uso: vivado -mode batch -source scripts/build_bitstream.tcl

# Derivar repo_path desde la ubicación de este script para que funcione
# independientemente del directorio de trabajo del usuario.
set repo_path [file normalize "[file dirname [info script]]/.."]
set proj_file [file normalize "$repo_path/Projects/pong_project/pong_project.xpr"]
set out_dir   [file normalize "$repo_path/bin/build_latest"]

puts "INFO: Abriendo proyecto $proj_file ..."
open_project $proj_file

# Actualizar IPs obsoletas y generar wrapper del BD.
# Necesario en máquinas de compañeros donde las revisiones del catálogo IP
# difieren de las almacenadas en los .xci del repo, bloqueando el BD.
puts "INFO: Actualizando IPs obsoletas ..."
upgrade_ip -quiet [get_ips -all]

puts "INFO: Generando productos del Block Design ..."
set bd_file [get_files */microblaze_v.bd]
generate_target all $bd_file -force

set wrapper_file [get_files -quiet *microblaze_v_wrapper*]
if {[llength $wrapper_file] == 0} {
    set wrapper_path [make_wrapper -files $bd_file -top -force]
    add_files -norecurse $wrapper_path
}

# Fuerza re-síntesis para asegurar que el HDL nuevo se incluye
puts "INFO: Reseteando runs para forzar re-síntesis..."
reset_run synth_1
reset_run impl_1

puts "INFO: Lanzando síntesis (synth_1)..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Síntesis falló."
    exit 1
}
puts "INFO: Síntesis completada."

puts "INFO: Lanzando implementación + write_bitstream (impl_1)..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementación falló."
    exit 1
}
puts "INFO: Implementación completada."

# Copia el bitstream a bin/build_latest
file mkdir $out_dir
set bit_src [get_property DIRECTORY [get_runs impl_1]]/top_pong_project.bit
file copy -force $bit_src $out_dir/top_pong_project.bit
puts "INFO: Bitstream copiado a $out_dir/top_pong_project.bit"

close_project
puts "DONE: Bitstream listo."
