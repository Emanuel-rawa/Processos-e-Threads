#include <iostream>
#include <fstream>
#include <vector>
#include <chrono>

using namespace std;

// Estrutura para representar matriz
struct Matrix_ {
    int line_, col_;                       
    vector<vector<long long>> data_;       
};

// Função para carregar matriz de arquivo
Matrix_ matrixLoad_(const string &filename_) {
    ifstream file_(filename_);
    if (!file_.is_open()) {
        cerr << "Erro ao acessar a matriz: " << filename_ << ";" << endl;
        exit(1);
    }

    Matrix_ M_;
    file_ >> M_.line_ >> M_.col_;
    M_.data_.resize(M_.line_, vector<long long>(M_.col_));

    for (int i_ = 0; i_ < M_.line_; i_++) {
        for (int j_ = 0; j_ < M_.col_; j_++) {
            file_ >> M_.data_[i_][j_]; // Preenchendo os elementos
        }
    }

    file_.close();
    return M_;
}

// Funçao para multiplicar duas matrizes sequencialmente
Matrix_ multiply_(const Matrix_ &A_, const Matrix_ &B_) {
    if (A_.col_ != B_.line_) {
        cerr << "Matrizes não compatíveis para multiplicação;" << endl;
        exit(1);
    }

    Matrix_ result_;
    result_.line_ = A_.line_;
    result_.col_ = B_.col_;
    result_.data_.resize(result_.line_, vector<long long>(result_.col_, 0));

    for (int i_ = 0; i_ < result_.line_; i_++) {
        for (int j_ = 0; j_ < result_.col_; j_++) {
            long long sum_ = 0;
            for (int k_ = 0; k_ < A_.col_; k_++) {
                sum_ += A_.data_[i_][k_] * B_.data_[k_][j_]; // cálculo do elemento
            }
            result_.data_[i_][j_] = sum_;
        }
    }

    return result_;
}

// Função para salvar matriz em arquivo com tempo de execução
void saveResult_(const string &filename_, const Matrix_ &M_, double duration_) {
    ofstream file_(filename_);
    if (!file_.is_open()) {
        cerr << "Erro ao criar o arquivo: " << filename_ << ";" << endl;
        exit(1);
    }

    file_ << M_.line_ << " " << M_.col_ << endl;
    for (int i_ = 0; i_ < M_.line_; i_++) {
        for (int j_ = 0; j_ < M_.col_; j_++) {
            file_ << M_.data_[i_][j_] << " ";
        }
        file_ << endl;
    }

    file_ << "Tempo de execução: " << duration_ << " segundos;" << endl;

    file_.close();
}

int main(int argc_, char *argv_[]) {
    if (argc_ != 3) {
        cerr << "Uso: " << argv_[0] << " M1.txt M2.txt;" << endl;
        return 1;
    }

    string file1_ = argv_[1];
    string file2_ = argv_[2];

    Matrix_ M1_ = matrixLoad_(file1_);  // Carregando primeira matriz
    Matrix_ M2_ = matrixLoad_(file2_);  // Carregando segunda matriz

    auto start_ = chrono::high_resolution_clock::now(); // inicio da mediçao

    Matrix_ result_ = multiply_(M1_, M2_); // multiplicaçao sequenial

    auto end_ = chrono::high_resolution_clock::now();
    chrono::duration<double> duration_ = end_ - start_;

    saveResult_("resultado_sequencial.txt", result_, duration_.count()); // Salva resultados

    cout << "Multiplicação sequencial concluída em " << duration_.count() << " segundos;" << endl;

    return 0;
}
