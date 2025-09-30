#include <chrono>
#include <cmath>
#include <cstdlib>
#include <fstream>
#include <functional>
#include <iostream>
#include <string>
#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <vector>

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

void parsing(const Matrix &A, const Matrix &B, int first, int last, int id_proc) {
    auto start = chrono::high_resolution_clock::now();

    int n1 = A.line, m2 = B.col;

    string filename = "result_" + to_string(id_proc) + ".txt";
    ofstream file(filename);

    if (not file.is_open()) {
        cerr << "Erro ao abrir " << filename << '\n';
        exit(1);
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

    file << "Tempo de execução: " << duration.count() << " segundos\n";
    file.close();
}

int main(int argc, char *argv[]) {
    if (argc != 4) {
        cerr << "Use: " << argv[0] << " M1.txt M2.txt P\n";
        return 1;
    }

    string file1{argv[1]};
    string file2{argv[2]};
    int P{stoi(argv[3])};

    Matrix M1 = matrixLoad(file1);
    Matrix M2 = matrixLoad(file2);

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
