#!/usr/bin/env bash
# run_experiments.sh
# Executa experimentos de multiplicação de matrizes para UM algoritmo escolhido.
# Uso:
#   ./run_experiments.sh sequencial
#   ./run_experiments.sh threads
#   ./run_experiments.sh processos

set -u
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_ROOT/src"
DATA_DIR="$PROJECT_ROOT/data"
RESULT_DIR="$PROJECT_ROOT/result"

REPEATS=10
START_SIZE=100
TIMEOUT=3600                # limite por execução (s)
SEQ_STOP_MS=$((120 * 1000)) # 2 min

mkdir -p "$DATA_DIR" "$RESULT_DIR"

if [ $# -lt 1 ]; then
  echo "Uso: $0 [sequencial|threads|processos]"
  exit 1
fi
ALG=$1

# Compilação
echo "Compilando..."
g++ -O2 "$SRC_DIR/auxiliar.cpp" -o "$SRC_DIR/auxiliar" || exit 1
case $ALG in
sequencial) g++ -O2 "$SRC_DIR/sequencial.cpp" -o "$SRC_DIR/sequencial" || exit 1 ;;
threads) g++ -O2 "$SRC_DIR/threads.cpp" -lpthread -o "$SRC_DIR/threads" || exit 1 ;;
processos) g++ -O2 "$SRC_DIR/processos.cpp" -o "$SRC_DIR/processos" || exit 1 ;;
*)
  echo "Algoritmo inválido: $ALG"
  exit 1
  ;;
esac

OUT_CSV="$RESULT_DIR/tempos_${ALG}.csv"
echo "Tamanho,TempoMedio_ms" >"$OUT_CSV"

# Funções
run_prog() {
  local bin="$1"
  shift
  local args=("$@")
  pushd "$SRC_DIR" >/dev/null
  local start=$(date +%s%3N)
  timeout "${TIMEOUT}"s ./"$bin" "${args[@]}" >/dev/null 2>&1
  local code=$?
  local end=$(date +%s%3N)
  popd >/dev/null
  if [ "$code" -eq 0 ]; then
    echo $((end - start))
  else
    echo "ERR:$code"
  fi
}

run_and_avg() {
  local bin="$1"
  shift
  local args=("$@")
  local total=0
  local success=0
  for i in $(seq 1 $REPEATS); do
    res=$(run_prog "$bin" "${args[@]}")
    if [[ "$res" != ERR:* ]]; then
      total=$((total + res))
      success=$((success + 1))
    fi
  done
  if [ "$success" -gt 0 ]; then
    echo $((total / success))
  else
    echo -1
  fi
}

# Loop de tamanhos
size=$START_SIZE
while true; do
  echo
  echo "==> [$ALG] Testando tamanho ${size}x${size}"

  # gerar matrizes
  pushd "$SRC_DIR" >/dev/null
  ./auxiliar "$size" "$size" "$size" "$size"
  popd >/dev/null

  if [ ! -s "$DATA_DIR/M1.txt" ] || [ ! -s "$DATA_DIR/M2.txt" ]; then
    echo "Falha ao gerar matrizes"
    exit 1
  fi

  # executa de acordo com o algoritmo
  case $ALG in
  sequencial)
    avg=$(run_and_avg "sequencial" "../data/M1.txt" "../data/M2.txt")
    echo "$size,$avg" >>"$OUT_CSV"
    if [ "$avg" -ge "$SEQ_STOP_MS" ]; then
      echo "Sequencial >= 2 min. Encerrando."
      break
    fi
    ;;
  threads)
    avg=$(run_and_avg "threads" "../data/M1.txt" "../data/M2.txt")
    echo "$size,$avg" >>"$OUT_CSV"
    ;;
  processos)
    avg=$(run_and_avg "processos" "../data/M1.txt" "../data/M2.txt")
    echo "$size,$avg" >>"$OUT_CSV"
    ;;
  esac

  size=$((size * 2))
done

echo
echo "[$ALG] Resultados salvos em: $OUT_CSV"
