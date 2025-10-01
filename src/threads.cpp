#include <iostream>
#include <fstream>
#include <vector>
#include <thread>
#include <cmath>

// Função para multiplicar um bloco de linhas
void multiplyBlock(const std::vector<std::vector<int>> &A,
                   const std::vector<std::vector<int>> &B,
                   std::vector<std::vector<int>> &C,
                   int startRow, int endRow) {
    int n1 = A.size();
    int m1 = A[0].size();
    int m2 = B[0].size();

    for (int i = startRow; i < endRow; i++) {
        for (int j = 0; j < m2; j++) {
            int sum = 0;
            for (int k = 0; k < m1; k++) {
                sum += A[i][k] * B[k][j];
            }
            C[i][j] = sum;
        }
    }
}

// Lê matriz de arquivo
std::vector<std::vector<int>> readMatrix(const std::string &filename) {
    std::ifstream in(filename);
    if (!in.is_open()) {
        throw std::runtime_error("Erro ao abrir arquivo " + filename);
    }

    int n, m;
    in >> n >> m;
    std::vector<std::vector<int>> M(n, std::vector<int>(m));

    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            in >> M[i][j];
        }
    }
    return M;
}

// Salva matriz em arquivo
void writeMatrix(const std::string &filename, const std::vector<std::vector<int>> &M) {
    std::ofstream out(filename);
    if (!out.is_open()) {
        throw std::runtime_error("Erro ao abrir arquivo de saída " + filename);
    }

    int n = M.size();
    int m = M[0].size();
    out << n << " " << m << "\n";
    for (int i = 0; i < n; i++) {
        for (int j = 0; j < m; j++) {
            out << M[i][j] << " ";
        }
        out << "\n";
    }
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        std::cerr << "Uso: " << argv[0] << " matriz1.txt matriz2.txt [p]\n";
        return 1;
    }

    try {
        std::string fileA = argv[1];
        std::string fileB = argv[2];
        std::string fileOut = "resultado_threads.txt";

        // Lê matrizes
        auto A = readMatrix(fileA);
        auto B = readMatrix(fileB);

        int n1 = A.size();
        int m1 = A[0].size();
        int n2 = B.size();
        int m2 = B[0].size();

        if (m1 != n2) {
            throw std::runtime_error("Dimensões incompatíveis para multiplicação");
        }

        std::vector<std::vector<int>> C(n1, std::vector<int>(m2, 0));

        // Número de threads
        unsigned int hwThreads = std::thread::hardware_concurrency();
        int p = (argc >= 4) ? std::stoi(argv[3]) : (hwThreads > 0 ? hwThreads : 4);

        if (p > n1) p = n1; // não faz sentido mais threads do que linhas

        std::vector<std::thread> threads;
        int blockSize = std::ceil(n1 / static_cast<double>(p));

        for (int t = 0; t < p; t++) {
            int startRow = t * blockSize;
            int endRow = std::min(startRow + blockSize, n1);
            if (startRow >= n1) break;
            threads.emplace_back(multiplyBlock, std::cref(A), std::cref(B), std::ref(C), startRow, endRow);
        }

        for (auto &th : threads) {
            th.join();
        }

        writeMatrix(fileOut, C);

    } catch (const std::exception &e) {
        std::cerr << "Erro: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
