#!/usr/bin/env bash
# run_experiments.sh
# Executa experimentos de multiplicação de matrizes:
# - sequencial, threads, processos
# - gera matrizes com auxiliar
# - repete 10 vezes e calcula média
# - para quando o tempo médio do sequencial >= 2 minutos
# - salva resultados em result/tempos.csv (tabela simples)

set -u
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_ROOT/src"
DATA_DIR="$PROJECT_ROOT/data"
RESULT_DIR="$PROJECT_ROOT/result"

REPEATS=10
START_SIZE=100
TIMEOUT=3600                # limite por execução em segundos
SEQ_STOP_MS=$((120 * 1000)) # 2 minutos em ms

mkdir -p "$DATA_DIR" "$RESULT_DIR"

echo "Compilando códigos..."
g++ -O2 "$SRC_DIR/auxiliar.cpp" -o "$SRC_DIR/auxiliar" || exit 1
g++ -O2 "$SRC_DIR/sequencial.cpp" -o "$SRC_DIR/sequencial" || exit 1
g++ -O2 "$SRC_DIR/threads.cpp" -lpthread -o "$SRC_DIR/threads" || exit 1
g++ -O2 "$SRC_DIR/processos.cpp" -o "$SRC_DIR/processos" || exit 1

OUT_CSV="$RESULT_DIR/tempos.csv"
echo "Tamanho,Sequencial,Threads,Processos" >"$OUT_CSV"

# executa um programa e retorna tempo em ms ou ERR
run_prog() {
  local bin="$1"
  shift
  local args=("$@")
  pushd "$SRC_DIR" >/dev/null || return 1
  local start=$(date +%s%3N)
  timeout "${TIMEOUT}"s ./"$bin" "${args[@]}" >/dev/null 2>&1
  local code=$?
  local end=$(date +%s%3N)
  popd >/dev/null || return 1

  if [ "$code" -eq 0 ]; then
    echo $((end - start))
  else
    echo "ERR:$code"
  fi
}

# roda REPEATS vezes e calcula média
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

size=$START_SIZE
while true; do
  echo
  echo "==> Testando tamanho ${size}x${size}"

  # gera matrizes (auxiliar grava ../data/M1.txt e ../data/M2.txt)
  pushd "$SRC_DIR" >/dev/null
  ./auxiliar "$size" "$size" "$size" "$size"
  popd >/dev/null

  if [ ! -s "$DATA_DIR/M1.txt" ] || [ ! -s "$DATA_DIR/M2.txt" ]; then
    echo "Falha ao gerar matrizes"
    exit 1
  fi

  # p = ceil(n1*m2 / 8)
  p_param=$(
    python3 - <<PY
import math
print(math.ceil(($size * $size) / 8))
PY
  )

  # executa experimentos
  seq_avg=$(run_and_avg "sequencial" "../data/M1.txt" "../data/M2.txt")
  thr_avg=$(run_and_avg "threads" "../data/M1.txt" "../data/M2.txt" "$p_param")
  pro_avg=$(run_and_avg "processos" "../data/M1.txt" "../data/M2.txt" "$p_param")

  echo "Sequencial=${seq_avg}ms | Threads=${thr_avg}ms | Processos=${pro_avg}ms"
  echo "$size,$seq_avg,$thr_avg,$pro_avg" >>"$OUT_CSV"

  # critério de parada
  if [ "$seq_avg" -ge "$SEQ_STOP_MS" ]; then
    echo "Tempo médio do sequencial >= 2 minutos. Encerrando."
    break
  fi

  size=$((size * 2))
done

echo
echo "Experimento concluído. Resultados em: $OUT_CSV"
