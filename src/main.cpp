#include <cstdlib>
#include <fstream>
#include <iostream>
#include <limits>
#include <random>
#include <string>

void matrixGen(int line, int col, const std::string &name_file) {
  std::ofstream file(name_file);

  if (!file.is_open()) {
    std::cerr << "Erro ao abrir o arquivo: " << name_file << "\n";
    exit(1);
  }

  std::random_device rd;
  std::mt19937 gen(rd());
  std::uniform_int_distribution<> dist(std::numeric_limits<int>::min(),
                                       std::numeric_limits<int>::max());

  file << line << " " << col << "\n";

  for (int i = 0; i < line; i++) {
    for (int j = 0; j < col; j++) {
      int value{dist(gen)};

      file << value << " ";
    }
    file << "\n";
  }

  file.close();
}

int main(int argc, char *argv[]) {
  if (argc != 5) {
    std::cerr << "Uso: " << argv[0] << " n1 m1 n2 m2\n";
    return 1;
  }
  int n1{std::stoi(argv[1])};
  int m1{std::stoi(argv[2])};
  int n2{std::stoi(argv[3])};
  int m2{std::stoi(argv[4])};

  if (m1 != n2) {
    std::cerr << "O número de colunas da primeira tem que ser igual ao número "
                 "de linhas da segunda\n";
    return 1;
  }

  // gerar matrizes e salvar em .txt
  matrixGen(n1, m1, "../data/M1.txt");
  matrixGen(n2, m2, "../data/M2.txt");

  return 0;
}
