#!/bin/bash
# Script      : run_pipeline.sh
# Descripcion : Script maestro que ejecuta el pipeline completo de síntesis,
#               implementación y extracción de métricas para el reporte.
#               Equivalente al pipeline del Proyecto 1 (sin simulaciones).
# Uso         : ./scripts/run_pipeline.sh [--skip-synth] [--skip-all]
#                 --skip-synth  Omite síntesis; lanza solo implementación.
#                 --skip-all    Omite Vivado por completo; parsea reportes existentes.
# Salida      : synth_results/utilizacion.csv
#               synth_results/latencia.csv

PASS_FLAG=""
[[ "$1" == "--skip-synth" ]] && PASS_FLAG="--skip-synth"
[[ "$1" == "--skip-all"   ]] && PASS_FLAG="--skip-all"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo ""
echo "========================================"
echo "Pipeline Síntesis+Implementación — Pong"
echo "========================================"

if [[ ! -x "$SCRIPT_DIR/parse_utilization.sh" ]]; then
    echo "Error: parse_utilization.sh no encontrado o sin permisos."
    echo "  Ejecuta: chmod +x scripts/*.sh"
    exit 1
fi

bash "$SCRIPT_DIR/parse_utilization.sh" $PASS_FLAG
if [[ $? -ne 0 ]]; then
    echo ""
    echo "Error: falló parse_utilization.sh. Pipeline detenido."
    exit 1
fi

echo ""
echo "========================================"
echo "Pipeline completado."
echo "Recursos FPGA : synth_results/utilizacion.csv"
echo "Latencia      : synth_results/latencia.csv"
echo "========================================"
