#!/bin/bash
# Experimento E2 - Variação de P na multiplicação de matrizes

mkdir -p results

RESULTADO="results/experimento_e2.csv"
echo "P,Tempo_Medio,Desvio_Padrao" >$RESULTADO

NUM_EXEC=10

# Função para executar e medir tempo
executar_teste() {
  local p_value=$1
  local tempos=()
  
  echo "Executando processos com P=$p_value..."

  for i in $(seq 1 $NUM_EXEC); do
    inicio=$(date +%s.%N)
    ./src/processos src/data/M1.txt src/data/M2.txt $p_value >/dev/null 2>&1
    fim=$(date +%s.%N)
    tempo=$(echo "$fim - $inicio" | bc)
    tempos+=($tempo)
    echo "  Execução $i/$NUM_EXEC: ${tempo}s"
  done

  # Média
  soma=0
  for t in "${tempos[@]}"; do
    soma=$(echo "$soma + $t" | bc)
  done
  media=$(echo "scale=4; $soma / $NUM_EXEC" | bc)

  # Desvio padrão
  soma_quad=0
  for t in "${tempos[@]}"; do
    diff=$(echo "$t - $media" | bc)
    quad=$(echo "$diff * $diff" | bc)
    soma_quad=$(echo "$soma_quad + $quad" | bc)
  done
  desvio=$(echo "scale=4; sqrt($soma_quad / $NUM_EXEC)" | bc)

  echo "$p_value,$media,$desvio" >>$RESULTADO
  echo "  Tempo médio: ${media}s (±${desvio}s)"
}

# Obter número total de elementos da matriz
n1=$(head -n1 src/data/M1.txt | awk '{print $1}')
m2=$(head -n1 src/data/M2.txt | awk '{print $2}')
total=$((n1 * m2))

# Valores de P: de ceil(total/8) até ceil(total/2)
p_inicial=$(( (total + 7) / 8 ))
p_min=$(( p_inicial / 4 ))
p_max=$(( (total + 1) / 2 ))
passo=$(( (p_max - p_min) / 5 ))
[ $passo -eq 0 ] && passo=1

# Primeiro teste descendente (reduzir P)
for ((P=p_inicial; P>=p_min; P-=passo)); do
  executar_teste $P
done

# Depois teste ascendente (aumentar P)
for ((P=p_inicial+passo; P<=p_max; P+=passo)); do
  executar_teste $P
done

echo ""
echo "======================================"
echo "Experimento E2 concluído!"
echo "Resultados salvos em: $RESULTADO"
echo "Para gerar o gráfico, execute: python3 gerar_grafico_e2.py"
