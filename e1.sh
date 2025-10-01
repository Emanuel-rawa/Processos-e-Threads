#!/bin/bash

# Script para executar experimento E1
# Estrutura esperada:
# trabalho/
#   ├─ src/
#   │   ├─ auxiliar.cpp -> compila para 'gerador'
#   │   ├─ sequencial.cpp -> compila para 'sequencial'
#   │   ├─ threads.cpp -> compila para 'threads'
#   │   └─ Processos.cpp -> compila para 'processos'
#   ├─ data/
#   └─ results/

# Criar pasta para resultados
mkdir -p results

# Arquivo para armazenar resultados
RESULTADO="results/experimento_e1.csv"
echo "Tamanho,Programa,Tempo_Medio,Desvio_Padrao" >$RESULTADO

# Número de execuções por teste
NUM_EXEC=10

# Função para executar e medir tempo
executar_teste() {
  local programa=$1
  local m1_file=$2
  local m2_file=$3
  local p_value=$4
  local tamanho=$5

  echo "  Executando $programa com matrizes ${tamanho}x${tamanho}..."

  # Array para armazenar os tempos
  tempos=()

  for i in $(seq 1 $NUM_EXEC); do
    echo -n "    Execução $i/$NUM_EXEC... "

    # Executar e capturar tempo
    inicio=$(date +%s.%N)
    if [ "$programa" == "sequencial" ]; then
      ./src/$programa $m1_file $m2_file >/dev/null 2>&1
    else
      ./src/$programa $m1_file $m2_file $p_value >/dev/null 2>&1
    fi
    fim=$(date +%s.%N)
    tempo=$(echo "$fim - $inicio" | bc)

    tempos+=($tempo)
    echo "${tempo}s"
  done

  # Calcular média e desvio padrão
  soma=0
  for t in "${tempos[@]}"; do
    soma=$(echo "$soma + $t" | bc)
  done
  media=$(echo "scale=4; $soma / $NUM_EXEC" | bc)

  # Calcular desvio padrão
  soma_quad=0
  for t in "${tempos[@]}"; do
    diff=$(echo "$t - $media" | bc)
    quad=$(echo "$diff * $diff" | bc)
    soma_quad=$(echo "$soma_quad + $quad" | bc)
  done
  desvio=$(echo "scale=4; sqrt($soma_quad / $NUM_EXEC)" | bc)

  # Salvar resultado
  echo "$tamanho,$programa,$media,$desvio" >>$RESULTADO
  echo "  Tempo médio: ${media}s (±${desvio}s)"
}

# Gerar matrizes e executar testes
tamanho=100
max_tempo_sequencial=0

echo "======================================"
echo "Iniciando Experimento E1"
echo "======================================"
echo ""

while [ $(echo "$max_tempo_sequencial < 120" | bc) -eq 1 ]; do
  echo ""
  echo "======================================"
  echo "Testando matrizes ${tamanho}x${tamanho}"
  echo "======================================"

  # Gerar matrizes (gerador cria automaticamente na pasta data/)
  echo "Gerando matrizes ${tamanho}x${tamanho}..."
  ./src/gerador $tamanho $tamanho $tamanho $tamanho

  # Verificar se os arquivos foram criados e copiar com nome específico
  if [ -f "data/M1.txt" ]; then
    cp data/M1.txt data/M1_${tamanho}.txt
    cp data/M2.txt data/M2_${tamanho}.txt
  elif [ -f "data/matrix1.txt" ]; then
    cp data/matrix1.txt data/M1_${tamanho}.txt
    cp data/matrix2.txt data/M2_${tamanho}.txt
  fi

  # Calcular P = ceil((tamanho * tamanho) / 8)
  p_value=$(echo "($tamanho * $tamanho + 7) / 8" | bc)
  echo "Valor de P: $p_value"
  echo ""

  # Executar programa sequencial
  executar_teste "sequencial" "data/M1_${tamanho}.txt" "data/M2_${tamanho}.txt" "" $tamanho

  # Pegar o tempo médio do sequencial para verificar se passou de 2 minutos
  max_tempo_sequencial=$(tail -n 1 $RESULTADO | cut -d',' -f3)

  # Executar programa com threads
  executar_teste "threads" "data/M1_${tamanho}.txt" "data/M2_${tamanho}.txt" $p_value $tamanho

  # Executar programa com processos
  executar_teste "processos" "data/M1_${tamanho}.txt" "data/M2_${tamanho}.txt" $p_value $tamanho

  echo ""
  echo "Tempo sequencial atual: ${max_tempo_sequencial}s"

  # Verificar se já passou de 120 segundos (2 minutos)
  if [ $(echo "$max_tempo_sequencial >= 120" | bc) -eq 1 ]; then
    echo "Tempo sequencial atingiu 2 minutos. Finalizando experimento."
    break
  fi

  # Dobrar o tamanho
  tamanho=$((tamanho * 2))
done

echo ""
echo "======================================"
echo "Experimento concluído!"
echo "======================================"
echo "Resultados salvos em: $RESULTADO"
echo ""
echo "Para gerar o gráfico, execute:"
echo "python3 gerar_grafico.py"
