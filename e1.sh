#!/usr/bin/env bash
set -u
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$PROJECT_ROOT/src"
DATA_DIR="$PROJECT_ROOT/data"
RESULT_DIR="$PROJECT_ROOT/result"

REPEATS=10
START_SIZE=100
TIMEOUT=3600                # timeout por execução em segundos
SEQ_STOP_MS=$((120 * 1000)) # 2 minutos em ms

mkdir -p "$DATA_DIR" "$RESULT_DIR"

echo "Compilando códigos..."
g++ -O2 "$SRC_DIR/auxiliar.cpp" -o "$SRC_DIR/auxiliar" || {
  echo "Erro ao compilar auxiliar"
  exit 1
}
g++ -O2 "$SRC_DIR/sequencial.cpp" -o "$SRC_DIR/sequencial" || {
  echo "Erro ao compilar sequencial"
  exit 1
}
g++ -O2 "$SRC_DIR/threads.cpp" -lpthread -o "$SRC_DIR/threads" || {
  echo "Erro ao compilar threads"
  exit 1
}
g++ -O2 "$SRC_DIR/Processos.cpp" -o "$SRC_DIR/processos" || {
  echo "Erro ao compilar Processos"
  exit 1
}

OUT_CSV="$RESULT_DIR/tempos.csv"
echo "Programa,Tamanho,TempoMedio_ms,Sucessos,TotalRuns" >"$OUT_CSV"

# Função que executa um binário e retorna tempo em ms ou ERR
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

# Função que roda REPEATS vezes e calcula média
run_and_avg() {
  local bin="$1"
  shift
  local args=("$@")
  local total=0
  local success=0
  for i in $(seq 1 $REPEATS); do
    echo -n "  [$bin] run $i/$REPEATS ... "
    res=$(run_prog "$bin" "${args[@]}")
    if [[ "$res" == ERR:* ]]; then
      echo "falhou ($res)"
    else
      echo "${res} ms"
      total=$((total + res))
      success=$((success + 1))
    fi
  done

  if [ "$success" -gt 0 ]; then
    avg=$((total / success))
  else
    avg=-1
  fi
  echo "$avg,$success"
}

size=$START_SIZE
while true; do
  echo
  echo "==> Testando tamanho ${size}x${size}"

  # Gera matrizes (auxiliar sempre grava em ../data)
  pushd "$SRC_DIR" >/dev/null
  ./auxiliar "$size" "$size" "$size" "$size"
  aux_code=$?
  popd >/dev/null
  if [ $aux_code -ne 0 ]; then
    echo "Falha ao gerar matrizes com auxiliar. Abortando."
    exit 1
  fi

  # Checa se arquivos foram gerados
  if [ ! -s "$DATA_DIR/M1.txt" ] || [ ! -s "$DATA_DIR/M2.txt" ]; then
    echo "Arquivos de matrizes não foram gerados corretamente. Abortando."
    exit 1
  fi

  # Calcula P = ceil(n1*m2 / 8)
  p_param=$(
    python3 - <<PY
import math
n = $size
print(math.ceil((n * n) / 8))
PY
  )
  echo "Usando p = $p_param para threads/processos."

  # Sequencial
  echo "Executando sequencial..."
  seq_info=$(run_and_avg "sequencial" "../data/M1.txt" "../data/M2.txt")
  seq_avg=$(echo "$seq_info" | cut -d',' -f1)
  seq_success=$(echo "$seq_info" | cut -d',' -f2)
  echo "Sequencial: avg=${seq_avg} ms (success=${seq_success}/${REPEATS})"
  echo "sequencial,$size,$seq_avg,$seq_success,$REPEATS" >>"$OUT_CSV"

  # Critério de parada: tempo médio do sequencial >= 2 min
  if [ "$seq_avg" -ge "$SEQ_STOP_MS" ]; then
    echo "Tempo médio do sequencial >= 2 minutos. Encerrando experimentos."
    break
  fi

  # Threads
  echo "Executando threads..."
  threads_info=$(run_and_avg "threads" "../data/M1.txt" "../data/M2.txt" "$p_param")
  threads_avg=$(echo "$threads_info" | cut -d',' -f1)
  threads_success=$(echo "$threads_info" | cut -d',' -f2)
  echo "Threads: avg=${threads_avg} ms (success=${threads_success}/${REPEATS})"
  echo "threads,$size,$threads_avg,$threads_success,$REPEATS" >>"$OUT_CSV"

  # Processos
  echo "Executando processos..."
  procs_info=$(run_and_avg "processos" "../data/M1.txt" "../data/M2.txt" "$p_param")
  procs_avg=$(echo "$procs_info" | cut -d',' -f1)
  procs_success=$(echo "$procs_info" | cut -d',' -f2)
  echo "Processos: avg=${procs_avg} ms (success=${procs_success}/${REPEATS})"
  echo "processos,$size,$procs_avg,$procs_success,$REPEATS" >>"$OUT_CSV"

  # Dobra tamanho
  size=$((size * 2))
done

echo
echo "Experimento concluído. Resultados em: $OUT_CSV"
