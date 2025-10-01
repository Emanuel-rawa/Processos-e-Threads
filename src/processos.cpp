#include <iostream>
#include <fstream>
#include <vector>
#include <unistd.h>
#include <sys/wait.h>
#include <cmath>
#include <string>

// Função para ler matriz de arquivo
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

// Função para salvar matriz
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

// Multiplicação de um bloco de linhas
void multiplyBlock(const std::vector<std::vector<int>> &A,
                   const std::vector<std::vector<int>> &B,
                   int startRow, int endRow,
                   const std::string &tempFile) {
    int n1 = A.size();
    int m1 = A[0].size();
    int m2 = B[0].size();

    std::ofstream out(tempFile);
    if (!out.is_open()) {
        throw std::runtime_error("Erro ao abrir arquivo temporário " + tempFile);
    }

    // Escreve apenas as linhas processadas
    out << (endRow - startRow) << " " << m2 << "\n";

    for (int i = startRow; i < endRow; i++) {
        for (int j = 0; j < m2; j++) {
            int sum = 0;
            for (int k = 0; k < m1; k++) {
                sum += A[i][k] * B[k][j];
            }
            out << sum << " ";
        }
        out << "\n";
    }
    out.close();
}

int main(int argc, char *argv[]) {
    if (argc < 3) {
        std::cerr << "Uso: " << argv[0] << " matriz1.txt matriz2.txt [p]\n";
        return 1;
    }

    try {
        std::string fileA = argv[1];
        std::string fileB = argv[2];
        std::string fileOut = "resultado_processos.txt";

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

        // Número de processos
        int hw = sysconf(_SC_NPROCESSORS_ONLN);
        int p = (argc >= 4) ? std::stoi(argv[3]) : (hw > 0 ? hw : 4);
        if (p > n1) p = n1; // no máximo uma linha por processo

        int blockSize = std::ceil(n1 / static_cast<double>(p));
        std::vector<pid_t> children;

        // Cria processos
        for (int t = 0; t < p; t++) {
            int startRow = t * blockSize;
            int endRow = std::min(startRow + blockSize, n1);
            if (startRow >= n1) break;

            std::string tempFile = "temp_block_" + std::to_string(t) + ".txt";

            pid_t pid = fork();
            if (pid == 0) {
                // processo filho
                multiplyBlock(A, B, startRow, endRow, tempFile);
                _exit(0);
            } else if (pid > 0) {
                // processo pai
                children.push_back(pid);
            } else {
                throw std::runtime_error("Erro no fork()");
            }
        }

        // Espera todos terminarem
        for (pid_t pid : children) {
            int status;
            waitpid(pid, &status, 0);
        }

        // Monta resultado final
        std::vector<std::vector<int>> C(n1, std::vector<int>(m2, 0));

        int currentRow = 0;
        for (int t = 0; t < (int)children.size(); t++) {
            std::string tempFile = "temp_block_" + std::to_string(t) + ".txt";
            std::ifstream in(tempFile);
            int rows, cols;
            in >> rows >> cols;

            for (int i = 0; i < rows; i++) {
                for (int j = 0; j < cols; j++) {
                    in >> C[currentRow][j];
                }
                currentRow++;
            }
            in.close();
            remove(tempFile.c_str());
        }

        // Salva matriz final
        writeMatrix(fileOut, C);

    } catch (const std::exception &e) {
        std::cerr << "Erro: " << e.what() << "\n";
        return 1;
    }

    return 0;
}
