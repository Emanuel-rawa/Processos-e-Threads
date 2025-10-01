#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import numpy as np

# Ler CSV
df = pd.read_csv("results/experimento_e2.csv")

# Plot linear
plt.figure(figsize=(8,6))
plt.errorbar(df['P'], df['Tempo_Medio'], yerr=df['Desvio_Padrao'], fmt='o-', capsize=5)
plt.title("Experimento E2 - Tempo Médio x P")
plt.xlabel("P (elementos por processo)")
plt.ylabel("Tempo Médio (s)")
plt.grid(True)
plt.savefig("results/grafico_experimento_e2.png", dpi=300)

# Plot logarítmico
plt.figure(figsize=(8,6))
plt.errorbar(df['P'], df['Tempo_Medio'], yerr=df['Desvio_Padrao'], fmt='o-', capsize=5)
plt.title("Experimento E2 - Tempo Médio x P (Log)")
plt.xlabel("P (elementos por processo)")
plt.ylabel("Tempo Médio (s)")
plt.xscale("log")
plt.yscale("log")
plt.grid(True, which="both", ls="--")
plt.savefig("results/grafico_experimento_e2_log.png", dpi=300)

print("Gráficos gerados em 'results/grafico_experimento_e2.png' e 'results/grafico_experimento_e2_log.png'")
