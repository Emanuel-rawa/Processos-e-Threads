# Experimento E1 - Multiplicação de Matrizes

## 📋 Pré-requisitos

- GCC/G++ (para compilar os programas C++)
- Python 3 com bibliotecas: `pandas`, `matplotlib`, `numpy`
- Bash (Linux/Mac) ou WSL (Windows)
- Comando `bc` (calculadora básica do Linux)

### Instalar dependências Python:
```bash
pip3 install pandas matplotlib numpy
```

## 📁 Estrutura de Diretórios

```
trabalho/
├── src/                    # Código fonte e executáveis
│   ├── auxiliar.cpp        # Código do gerador
│   ├── sequencial.cpp      # Código sequencial
│   ├── threads.cpp         # Código com threads
│   ├── Processos.cpp       # Código com processos
│   ├── gerador             # Executável (compilado de auxiliar.cpp)
│   ├── sequencial          # Executável sequencial
│   ├── threads             # Executável com threads
│   └── processos           # Executável com processos
├── data/                   # Matrizes geradas
├── results/                # Resultados dos experimentos
├── setup.sh                # Script de compilação
├── experimento_e1.sh       # Script principal
├── teste_manual.sh         # Script para testes individuais
└── gerar_grafico.py        # Script Python para gráficos
```

## 🔧 Preparação

### 1. Compilar os programas (dentro de src/)

```bash
cd src/

# Compilar gerador de matrizes (auxiliar.cpp)
g++ -o gerador auxiliar.cpp

# Compilar versão sequencial
g++ -o sequencial sequencial.cpp

# Compilar versão com threads
g++ -o threads threads.cpp -pthread

# Compilar versão com processos
g++ -o processos Processos.cpp

cd ..
```

**OU use o script automático:**
```bash
./setup.sh
```

### 2. Dar permissão de execução aos scripts

```bash
chmod +x experimento_e1.sh
chmod +x teste_manual.sh
chmod +x gerar_grafico.py
```

### 3. Criar diretórios necessários

```bash
mkdir -p data results
```

## 🚀 Execução

### Opção 1: Executar Experimento Completo (Recomendado)

```bash
./experimento_e1.sh
```

Este script irá:
- Começar com matrizes 100×100
- Dobrar o tamanho a cada iteração (200×200, 400×400, etc.)
- Executar cada programa 10 vezes por tamanho
- Calcular P = ⌈(n₁ × m₂) / 8⌉ para programas paralelos
- Parar quando o programa sequencial levar 2+ minutos
- Salvar resultados em `results/experimento_e1.csv`

**Tempo estimado:** Várias horas (depende do hardware)

### Opção 2: Teste Manual Individual

Para testar um tamanho específico:

```bash
# Sintaxe: ./teste_manual.sh <tamanho> <programa> [num_execucoes]

# Exemplos:
./teste_manual.sh 200 sequencial 10
./teste_manual.sh 400 threads 10
./teste_manual.sh 800 processos 5
```

### Opção 3: Execução Manual Completa

```bash
# 1. Gerar matrizes
./src/gerador 100 100 data/M1_100.txt
./src/gerador 100 100 data/M2_100.txt

# 2. Calcular P (exemplo para 100x100)
# P = ceil((100 * 100) / 8) = 1250

# 3. Executar programas
time ./src/sequencial data/M1_100.txt data/M2_100.txt
time ./src/threads data/M1_100.txt data/M2_100.txt 1250
time ./src/processos data/M1_100.txt data/M2_100.txt 1250
```

## 📊 Gerar Gráficos

Após executar o experimento completo:

```bash
python3 gerar_grafico.py
```

Isso irá gerar:
1. `results/grafico_experimento_e1.png` - Gráfico linear
2. `results/grafico_experimento_e1_log.png` - Gráfico em escala logarítmica
3. `results/grafico_speedup.png` - Gráfico de speedup

## 📈 Formato dos Resultados

### Arquivo CSV (`results/experimento_e1.csv`)

```csv
Tamanho,Programa,Tempo_Medio,Desvio_Padrao
100,sequencial,0.0234,0.0012
100,threads,0.0156,0.0008
100,processos,0.0189,0.0010
200,sequencial,0.1567,0.0045
...
```

### Colunas:
- **Tamanho**: Dimensão da matriz (n para matriz n×n)
- **Programa**: sequencial, threads ou processos
- **Tempo_Medio**: Média de 10 execuções (segundos)
- **Desvio_Padrao**: Desvio padrão das 10 execuções

## 🔍 Análise dos Resultados

O script Python também imprime análise de speedup:

```
ANÁLISE DE SPEEDUP
============================================================
Matriz 100x100:
  Sequencial:   0.0234s
  Threads:      0.0156s (Speedup: 1.50x)
  Processos:    0.0189s (Speedup: 1.24x)
...
```

**Speedup** = Tempo Sequencial / Tempo Paralelo
- Speedup > 1: Programa paralelo é mais rápido
- Speedup < 1: Programa paralelo é mais lento (overhead)
- Speedup = 8: Aceleração ideal para 8 threads/processos

## ⚠️ Troubleshooting

### Erro: "command not found: bc"
```bash
# Ubuntu/Debian
sudo apt-get install bc

# Fedora/RHEL
sudo dnf install bc

# macOS
brew install bc
```

### Erro: "time: command not found"
Use `/usr/bin/time` em vez de `time`:
```bash
/usr/bin/time -p ./programa ...
```

### Programas não encontrados
Verifique se compilou corretamente e se os executáveis estão na raiz do projeto.

### Erro ao criar pasta `data/`
```bash
mkdir -p data results
chmod 755 data results
```

### Python não encontra módulos
```bash
pip3 install --user pandas matplotlib numpy
```

## 💡 Dicas

1. **Execute em horário de baixo uso**: Para medições mais precisas
2. **Feche outros programas**: Evite interferência
3. **Use `nice`** para prioridade: `nice -n -20 ./experimento_e1.sh`
4. **Monitore o sistema**: Use `htop` em outro terminal
5. **Faça backup**: Copie `results/` periodicamente

## 📝 Observações sobre o Experimento

### Valor de P
- P = ⌈(n₁ × m₂) / 8⌉
- Para matriz 100×100: P = ⌈10000 / 8⌉ = 1250
- Para matriz 200×200: P = ⌈40000 / 8⌉ = 5000

### Critério de Parada
O experimento para quando o tempo do programa sequencial ≥ 120 segundos (2 minutos)

### Número de Execuções
Cada teste é executado 10 vezes para garantir confiabilidade estatística

## 📧 Suporte

Se encontrar problemas:
1. Verifique os logs em `results/`
2. Execute teste manual para isolar o problema
3. Verifique permissões e caminhos dos arquivos
