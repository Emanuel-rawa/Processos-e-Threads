#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Ler dados do CSV
df = pd.read_csv('results/experimento_e1.csv')

# Separar por programa
sequencial = df[df['Programa'] == 'sequencial']
threads = df[df['Programa'] == 'threads']
processos = df[df['Programa'] == 'processos']

# Criar o gráfico
plt.figure(figsize=(12, 7))

# Plotar cada programa
plt.errorbar(sequencial['Tamanho'], sequencial['Tempo_Medio'], 
             yerr=sequencial['Desvio_Padrao'], 
             marker='o', linestyle='-', linewidth=2, markersize=8,
             label='Sequencial', capsize=5, capthick=2)

plt.errorbar(threads['Tamanho'], threads['Tempo_Medio'], 
             yerr=threads['Desvio_Padrao'], 
             marker='s', linestyle='-', linewidth=2, markersize=8,
             label='Threads', capsize=5, capthick=2)

plt.errorbar(processos['Tamanho'], processos['Tempo_Medio'], 
             yerr=processos['Desvio_Padrao'], 
             marker='^', linestyle='-', linewidth=2, markersize=8,
             label='Processos', capsize=5, capthick=2)

# Configurar o gráfico
plt.xlabel('Tamanho da Matriz (n×n)', fontsize=14, fontweight='bold')
plt.ylabel('Tempo Médio de Execução (segundos)', fontsize=14, fontweight='bold')
plt.title('Comparação de Desempenho: Sequencial vs Threads vs Processos\nMultiplicação de Matrizes', 
          fontsize=16, fontweight='bold', pad=20)
plt.legend(fontsize=12, loc='upper left')
plt.grid(True, alpha=0.3, linestyle='--')
plt.tight_layout()

# Salvar gráfico
plt.savefig('results/grafico_experimento_e1.png', dpi=300, bbox_inches='tight')
print("Gráfico salvo em: results/grafico_experimento_e1.png")

# Criar gráfico com escala logarítmica (útil se houver grandes diferenças)
plt.figure(figsize=(12, 7))

plt.errorbar(sequencial['Tamanho'], sequencial['Tempo_Medio'], 
             yerr=sequencial['Desvio_Padrao'], 
             marker='o', linestyle='-', linewidth=2, markersize=8,
             label='Sequencial', capsize=5, capthick=2)

plt.errorbar(threads['Tamanho'], threads['Tempo_Medio'], 
             yerr=threads['Desvio_Padrao'], 
             marker='s', linestyle='-', linewidth=2, markersize=8,
             label='Threads', capsize=5, capthick=2)

plt.errorbar(processos['Tamanho'], processos['Tempo_Medio'], 
             yerr=processos['Desvio_Padrao'], 
             marker='^', linestyle='-', linewidth=2, markersize=8,
             label='Processos', capsize=5, capthick=2)

plt.xlabel('Tamanho da Matriz (n×n)', fontsize=14, fontweight='bold')
plt.ylabel('Tempo Médio de Execução (segundos) - Escala Log', fontsize=14, fontweight='bold')
plt.title('Comparação de Desempenho (Escala Logarítmica)\nMultiplicação de Matrizes', 
          fontsize=16, fontweight='bold', pad=20)
plt.legend(fontsize=12, loc='upper left')
plt.yscale('log')
plt.grid(True, alpha=0.3, linestyle='--', which='both')
plt.tight_layout()

plt.savefig('results/grafico_experimento_e1_log.png', dpi=300, bbox_inches='tight')
print("Gráfico (escala log) salvo em: results/grafico_experimento_e1_log.png")

# Calcular speedup
print("\n" + "="*60)
print("ANÁLISE DE SPEEDUP")
print("="*60)

for tamanho in sequencial['Tamanho'].unique():
    tempo_seq = sequencial[sequencial['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    tempo_thr = threads[threads['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    tempo_proc = processos[processos['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    
    speedup_thr = tempo_seq / tempo_thr
    speedup_proc = tempo_seq / tempo_proc
    
    print(f"\nMatriz {tamanho}x{tamanho}:")
    print(f"  Sequencial:   {tempo_seq:.4f}s")
    print(f"  Threads:      {tempo_thr:.4f}s (Speedup: {speedup_thr:.2f}x)")
    print(f"  Processos:    {tempo_proc:.4f}s (Speedup: {speedup_proc:.2f}x)")

# Gráfico de speedup
plt.figure(figsize=(12, 7))

tamanhos = sequencial['Tamanho'].values
speedup_threads = []
speedup_processos = []

for tamanho in tamanhos:
    tempo_seq = sequencial[sequencial['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    tempo_thr = threads[threads['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    tempo_proc = processos[processos['Tamanho'] == tamanho]['Tempo_Medio'].values[0]
    
    speedup_threads.append(tempo_seq / tempo_thr)
    speedup_processos.append(tempo_seq / tempo_proc)

plt.plot(tamanhos, speedup_threads, marker='s', linestyle='-', 
         linewidth=2, markersize=8, label='Threads')
plt.plot(tamanhos, speedup_processos, marker='^', linestyle='-', 
         linewidth=2, markersize=8, label='Processos')
plt.axhline(y=1, color='red', linestyle='--', linewidth=2, 
            label='Baseline (Sequencial)', alpha=0.7)

plt.xlabel('Tamanho da Matriz (n×n)', fontsize=14, fontweight='bold')
plt.ylabel('Speedup (relativo ao Sequencial)', fontsize=14, fontweight='bold')
plt.title('Speedup: Programas Paralelos vs Sequencial', 
          fontsize=16, fontweight='bold', pad=20)
plt.legend(fontsize=12, loc='best')
plt.grid(True, alpha=0.3, linestyle='--')
plt.tight_layout()

plt.savefig('results/grafico_speedup.png', dpi=300, bbox_inches='tight')
print("\nGráfico de speedup salvo em: results/grafico_speedup.png")

print("\n" + "="*60)
print("Análise completa! Verifique a pasta 'results/'")
print("="*60)
