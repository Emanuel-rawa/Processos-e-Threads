#!/usr/bin/env python3
import pandas as pd
import matplotlib.pyplot as plt
import os

PROJECT_ROOT = os.path.dirname(os.path.abspath(__file__))
RESULT_DIR = os.path.join(PROJECT_ROOT, "result")
IMG_PATH = os.path.join(RESULT_DIR, "grafico.png")

# Carrega CSVs
dfs = []
for alg in ["sequencial", "threads", "processos"]:
    path = os.path.join(RESULT_DIR, f"tempos_{alg}.csv")
    if os.path.exists(path):
        df = pd.read_csv(path)
        df["Algoritmo"] = alg.capitalize()
        dfs.append(df)

if not dfs:
    raise RuntimeError("Nenhum CSV encontrado em result/. Execute os experimentos antes.")

data = pd.concat(dfs)

# Plot
plt.figure(figsize=(10,6))
for alg in data["Algoritmo"].unique():
    sub = data[data["Algoritmo"] == alg]
    plt.plot(sub["Tamanho"], sub["TempoMedio_ms"], marker="o", label=alg)

plt.xlabel("Tamanho da matriz (N x N)")
plt.ylabel("Tempo médio (ms)")
plt.title("Comparação de tempos de execução")
plt.legend()
plt.grid(True)
plt.tight_layout()

plt.savefig(IMG_PATH, dpi=300)
print(f"Gráfico salvo em {IMG_PATH}")
