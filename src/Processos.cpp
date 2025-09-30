#include <chrono>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

using namespace std;

// Estrutura para armazenar a matriz
struct Matrix {
    int line, col;
    vector<vector<long long>> data;
};

// Função para carregar a matriz de um arquivo
Matrix matrixLoad(const string &filename) {
    ifstream file(filename);
    if (!file.is_open()) {
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

// Função que cada processo menor executa
void parsing(const Matrix &A, const Matrix &B, int first, int last, int id_proc) {
    auto start = chrono::high_resolution_clock::now();

    int n1 = A.line, m2 = B.col;
    string filename = "result_" + to_string(id_proc) + ".txt";
    ofstream file(filename);

    if (!file.is_open()) {
        cerr << "Erro ao abrir " << filename << '\n';
        exit(1);
    }

    // Cada arquivo inicia com o tamanho total da matriz
    file << n1 << " " << m2 << '\n';

    // Calcula só os elementos do intervalo
    for (int idx = first; idx < last; idx++) {
        //Linha da matriz
        int i = idx / m2; 
        //Coluna da matriz
        int j = idx % m2; 

        long long sum = 0;
        for (int k = 0; k < A.col; k++) {
            sum += A.data[i][k] * B.data[k][j];
        }

        file << i << " " << j << " " << sum << '\n';
    }

    auto end = chrono::high_resolution_clock::now();
    chrono::duration<double> duration = end - start;

    file << "Tempo de execução: " << duration.count() << " segundos\n";
    file.close();
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        cerr << "Uso: " << argv[0] << " M1.txt M2.txt P\n";
        return 1;
    }

    string file1{argv[1]};
    string file2{argv[2]};
    int P{stoi(argv[3])};

    if (P <= 0) {
        cerr << "P deve ser maior que 0\n";
        return 1;
    }

    // Carrega matrizes antes de criar os processos
    Matrix M1 = matrixLoad(file1);
    Matrix M2 = matrixLoad(file2);

    // Verifica se da certo a multiplicação
    if (M1.col != M2.line) {
        cerr << "Erro: Matrizes incompatíveis para multiplicação!\n";
        return 1;
    }

    int len = M1.line * M2.col;                 
    int num_procs = ceil((double)len / P);      

    cout << "Criando " << num_procs << " processos...\n";

    auto global_start = chrono::high_resolution_clock::now();

    for (int p = 0; p < num_procs; p++) {
        int start = p * P;
        int end = min(start + P, len);

        pid_t pid = fork();
        if (pid < 0) {
            cerr << "Erro ao criar processo\n";
            return 1;
        }

        if (pid == 0) {
            parsing(M1, M2, start, end, p + 1);
            exit(0); 
        }
    }

    for (int p = 0; p < num_procs; p++) {
        wait(nullptr);
    }

    auto global_end = chrono::high_resolution_clock::now();
    chrono::duration<double> total_time = global_end - global_start;

    cout << "Multiplicação concluída em " << num_procs << " arquivos.\n";
    cout << "Tempo total (todos processos): " << total_time.count() << " segundos\n";

    return 0;
}
