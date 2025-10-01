#!/bin/bash

# Script para executar um único teste manualmente
# Uso: ./teste_manual.sh <tamanho> <programa> <num_execucoes>
# Exemplo: ./teste_manual.sh 200 threads 10

if [ $# -lt 2 ]; then
  echo "Uso: $0 <tamanho> <programa> [num_execucoes]"
  echo "Programas disponíveis: sequencial, threads, processos"
  echo "Exemplo: $0 200 threads 10"
  exit 1
fi

TAMANHO=$1
PROGRAMA=$2
NUM_EXEC=${3:-10}

# Criar pastas necessárias
mkdir -p data
mkdir -p results

echo "======================================"
echo "Teste Individual"
echo "======================================"
echo "Tamanho: ${TAMANHO}x${TAMANHO}"
echo "Programa: $PROGRAMA"
echo "Número de execuções: $NUM_EXEC"
echo "======================================"
echo ""

# Gerar matrizes
echo "Gerando matrizes..."
./src/gerador $TAMANHO $TAMANHO data/M1_${TAMANHO}.txt
./src/gerador $TAMANHO $TAMANHO data/M2_${TAMANHO}.txt

# Calcular P
P=$(echo "($TAMANHO * $TAMANHO + 7) / 8" | bc)
echo "Valor de P: $P"
echo ""

# Array para armazenar tempos
declare -a tempos

echo "Executando testes..."
for i in $(seq 1 $NUM_EXEC); do
  echo -n "Execução $i/$NUM_EXEC... "

  # Medir tempo
  if [ "$PROGRAMA" == "sequencial" ]; then
    tempo=$({ time -p ./src/$PROGRAMA data/M1_${TAMANHO}.txt data/M2_${TAMANHO}.txt 2>&1 >/dev/null; } 2>&1 | grep real | awk '{print $2}')
  else
    tempo=$({ time -p ./src/$PROGRAMA data/M1_${TAMANHO}.txt data/M2_${TAMANHO}.txt $P 2>&1 >/dev/null; } 2>&1 | grep real | awk '{print $2}')
  fi

  tempos[$i]=$tempo
  echo "${tempo}s"
done

echo ""
echo "======================================"
echo "Resultados"
echo "======================================"

# Calcular estatísticas
soma=0
for t in "${tempos[@]}"; do
  soma=$(echo "$soma + $t" | bc)
done
media=$(echo "scale=4; $soma / $NUM_EXEC" | bc)

# Encontrar mínimo e máximo
minimo=${tempos[1]}
maximo=${tempos[1]}
for t in "${tempos[@]}"; do
  if [ $(echo "$t < $minimo" | bc) -eq 1 ]; then
    minimo=$t
  fi
  if [ $(echo "$t > $maximo" | bc) -eq 1 ]; then
    maximo=$t
  fi
done

# Calcular desvio padrão
soma_quad=0
for t in "${tempos[@]}"; do
  diff=$(echo "$t - $media" | bc)
  quad=$(echo "$diff * $diff" | bc)
  soma_quad=$(echo "$soma_quad + $quad" | bc)
done
desvio=$(echo "scale=4; sqrt($soma_quad / $NUM_EXEC)" | bc)

echo "Tempo médio:     ${media}s"
echo "Desvio padrão:   ${desvio}s"
echo "Tempo mínimo:    ${minimo}s"
echo "Tempo máximo:    ${maximo}s"
echo "======================================"

# Salvar em arquivo
RESULTADO="results/teste_individual_${PROGRAMA}_${TAMANHO}.txt"
{
  echo "======================================"
  echo "Teste Individual"
  echo "======================================"
  echo "Data: $(date)"
  echo "Tamanho: ${TAMANHO}x${TAMANHO}"
  echo "Programa: $PROGRAMA"
  echo "Valor de P: $P"
  echo "Número de execuções: $NUM_EXEC"
  echo ""
  echo "Tempos individuais:"
  for i in $(seq 1 $NUM_EXEC); do
    echo "  Execução $i: ${tempos[$i]}s"
  done
  echo ""
  echo "Estatísticas:"
  echo "  Tempo médio:     ${media}s"
  echo "  Desvio padrão:   ${desvio}s"
  echo "  Tempo mínimo:    ${minimo}s"
  echo "  Tempo máximo:    ${maximo}s"
  echo "======================================"
} >$RESULTADO

echo ""
echo "Resultados salvos em: $RESULTADO"
