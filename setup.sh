#!/bin/bash

# Script para compilar e preparar o ambiente do experimento

echo "======================================"
echo "Setup do Experimento E1"
echo "======================================"
echo ""

# Verificar se está no diretório correto
if [ ! -d "src" ]; then
  echo "❌ Erro: pasta 'src/' não encontrada!"
  echo "Execute este script da raiz do projeto 'trabalho/'"
  exit 1
fi

# Criar diretórios necessários
echo "📁 Criando diretórios..."
mkdir -p data
mkdir -p results
echo "✅ Diretórios criados"
echo ""

# Verificar se g++ está instalado
if ! command -v g++ &>/dev/null; then
  echo "❌ Erro: g++ não encontrado!"
  echo "Instale com: sudo apt-get install g++ (Ubuntu/Debian)"
  exit 1
fi

echo "🔨 Compilando programas em src/..."
echo ""

cd src/

# Compilar gerador de matrizes (auxiliar.cpp)
if [ -f "auxiliar.cpp" ]; then
  echo -n "  Compilando auxiliar (gerador)... "
  g++ -o gerador auxiliar.cpp -O3
  if [ $? -eq 0 ]; then
    echo "✅"
  else
    echo "❌ Falhou!"
    cd ..
    exit 1
  fi
else
  echo "⚠️  Arquivo auxiliar.cpp não encontrado"
fi

# Compilar versão sequencial
if [ -f "sequencial.cpp" ]; then
  echo -n "  Compilando sequencial... "
  g++ -o sequencial sequencial.cpp -O3
  if [ $? -eq 0 ]; then
    echo "✅"
  else
    echo "❌ Falhou!"
    cd ..
    exit 1
  fi
else
  echo "⚠️  Arquivo sequencial.cpp não encontrado"
fi

# Compilar versão com threads
if [ -f "threads.cpp" ]; then
  echo -n "  Compilando threads... "
  g++ -o threads threads.cpp -pthread -O3
  if [ $? -eq 0 ]; then
    echo "✅"
  else
    echo "❌ Falhou!"
    cd ..
    exit 1
  fi
else
  echo "⚠️  Arquivo threads.cpp não encontrado"
fi

# Compilar versão com processos
if [ -f "Processos.cpp" ]; then
  echo -n "  Compilando Processos... "
  g++ -o processos Processos.cpp -O3
  if [ $? -eq 0 ]; then
    echo "✅"
  else
    echo "❌ Falhou!"
    cd ..
    exit 1
  fi
else
  echo "⚠️  Arquivo Processos.cpp não encontrado"
fi

cd ..

echo ""
echo "======================================"
echo "✅ Setup concluído com sucesso!"
echo "======================================"
echo ""
echo "Executáveis criados em src/:"
ls -lh src/gerador src/sequencial src/threads src/processos 2>/dev/null
echo ""
echo "Próximos passos:"
echo "1. Execute teste rápido: ./teste_manual.sh 100 sequencial 3"
echo "2. Execute experimento completo: ./experimento_e1.sh"
echo "3. Gere gráficos: python3 gerar_grafico.py"
echo ""

# Verificar dependências Python
echo "Verificando dependências Python..."
python3 -c "import pandas, matplotlib, numpy" 2>/dev/null
if [ $? -eq 0 ]; then
  echo "✅ Bibliotecas Python instaladas"
else
  echo "⚠️  Instale as bibliotecas Python:"
  echo "   pip3 install pandas matplotlib numpy"
fi

# Verificar bc
if command -v bc &>/dev/null; then
  echo "✅ Comando 'bc' disponível"
else
  echo "⚠️  Instale 'bc': sudo apt-get install bc"
fi

echo ""
echo "Tudo pronto para o experimento! 🚀"
