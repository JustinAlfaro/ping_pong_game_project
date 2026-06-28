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

# Actualizar IPs y regenerar wrapper del BD.
# En máquinas de compañeros los .xci commitados tienen checksums diferentes,
# lo que bloquea el BD. Se requieren dos pasos:
#   1. upgrade_ip  → IPs normales (bram_ctrl, quad_spi, clk_wiz, proc_reset)
#   2. upgrade_bd_cells dentro del BD abierto → IPs de infraestructura
#      autogenerados (auto_cc, auto_pc) que upgrade_ip no toca.
puts "INFO: Actualizando IPs obsoletas ..."
upgrade_ip -quiet [get_ips -all]

puts "INFO: Actualizando celdas de infraestructura del Block Design ..."
set bd_file   [get_files */microblaze_v.bd]
set bd_path   [file normalize $bd_file]
set bd_backup "${bd_path}.bak"

# Backup del BD antes de cualquier modificación: save_bd_design escribe de
# vuelta al archivo fuente del repo, lo que produce bitstreams distintos
# entre máquinas. El backup permite restaurarlo después de la síntesis.
file copy -force $bd_path $bd_backup

open_bd_design $bd_file
set stale_cells [get_bd_cells -hier -filter {STATUS != "OK"}]
if {[llength $stale_cells] > 0} {
    puts "INFO: Celdas BD obsoletas encontradas: $stale_cells"
    upgrade_bd_cells $stale_cells
}
validate_bd_design -quiet
save_bd_design
close_bd_design [get_bd_designs microblaze_v]

puts "INFO: Generando productos del Block Design ..."
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

# Esperar explícitamente todos los runs OOC antes de lanzar implementación.
# Si no, xbar_0 (u otros IPs grandes) pueden seguir corriendo cuando opt_design
# empieza y Vivado los trata como blackbox → DRC INBB-3.
puts "INFO: Esperando runs OOC pendientes..."
foreach r [get_runs -filter {IS_SYNTHESIS == 1 && NAME != "synth_1"}] {
    if {[get_property PROGRESS $r] != "100%"} {
        puts "INFO:   waiting on $r ..."
        wait_on_run $r
    }
}
puts "INFO: Todos los runs OOC completos."

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

# Restaurar el BD al estado original del repo para que futuros builds
# partan del mismo BD sin acumular cambios de upgrade_bd_cells.
puts "INFO: Restaurando BD al estado original del repo ..."
file copy -force $bd_backup $bd_path
file delete $bd_backup

puts "DONE: Bitstream listo."
