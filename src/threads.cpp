#include <chrono>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <string>
#include <thread>
#include <vector>
#include <sys/stat.h>  // Para criar diretório

using namespace std;

struct Matrix {
  int line, col;
  vector<vector<long long>> data;
};

Matrix matrixLoad(const string &filename) {
  ifstream file(filename);
  if (not file.is_open()) {
    cerr << "Erro ao acessar a matriz: " << filename << '\n';
    exit(1);
  }
  Matrix M;
  file >> M.line >> M.col;
  M.data.resize(M.line, vector<long long>(M.col));
  for (int i = 0; i < M.line; i++) {
    for (int j = 0; j < M.col; j++) {
      file >> M.data[i][j];
    }
  }
  file.close();
  return M;
}

// Função auxiliar para criar diretório
void createDirectory(const string& path) {
  #ifdef _WIN32
    _mkdir(path.c_str());
  #else
    mkdir(path.c_str(), 0777);
  #endif
}

// Calcular P elementos da matriz resultado
void parsing(const Matrix &A, const Matrix &B, int first, int last,
             int id_thread) {
  auto start = chrono::high_resolution_clock::now();
  int n1 = A.line, m2 = B.col;
  
  string filename = "../data/result_" + to_string(id_thread) + ".txt";
  ofstream file(filename);
  
  if (not file.is_open()) {
    cerr << "Erro ao abrir " << filename << '\n';
    cerr << "Tentando criar a pasta ../data/\n";
    return;
  }
  
  file << n1 << " " << m2 << '\n';
  for (int idx = first; idx < last; idx++) {
    int i = idx / m2;
    int j = idx % m2;
    long long sum = 0;
    for (int k = 0; k < A.col; k++) {
      sum += A.data[i][k] * B.data[k][j];
    }
    file << i << " " << j << " " << sum << '\n';
  }
  
  auto end = chrono::high_resolution_clock::now();
  chrono::duration<double> duration = end - start;
  file << "Tempo de execução: " << duration.count() << " segundos \n";
  file.close();
}

int main(int argc, char *argv[]) {
  if (argc != 4) {
    cerr << "Use: " << argv[0] << " M1.txt M2.txt p\n";
    return 1;
  }
  
  string file1{argv[1]};
  string file2{argv[2]};
  int p{stoi(argv[3])};
  
  // Criar a pasta data se não existir
  createDirectory("../data");
  
  // Carregar as matrizes
  Matrix M1 = matrixLoad(file1);
  Matrix M2 = matrixLoad(file2);
  
  int len{M1.line * M2.col};
  int num_threads = ceil((double)len / p);
  vector<thread> threads;
  
  for (int t = 0; t < len; t++) {
    int start = t * p;
    int end = min(start + p, len);
    threads.emplace_back(parsing, cref(M1), cref(M2), start, end, t + 1);
  }
  
  for (auto &th : threads) {
    th.join();
  }
  
  cout << "Multiplicação concluída em " << len << " arquivos.\n";
  return 0;
}
