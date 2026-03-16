# 💇‍♀️ Salão — Agenda

Web app Flutter completa para gestão de salão de cabelo com armazenamento local Hive.

---

## ✨ Funcionalidades

| Módulo | Recursos |
|---|---|
| **Agenda** | Visualização por dia, semana compacta, agendar/concluir/cancelar |
| **Clientes** | Cadastro com nome, telefone, e-mail, observações, busca |
| **Relatórios** | Diário, Semanal e Mensal com gráficos de barras e pizza |

---

## 🗂️ Estrutura de Arquivos

```
lib/
├── main.dart                     # Entrada, navegação principal
├── theme.dart                    # Paleta de cores e tema global
├── models/
│   ├── client.dart               # Modelo Cliente (Hive)
│   ├── client.g.dart             # Adapter gerado
│   ├── appointment.dart          # Modelo Agendamento (Hive)
│   └── appointment.g.dart        # Adapter gerado
├── services/
│   └── storage_service.dart      # CRUD Hive para clientes e agendamentos
└── screens/
    ├── agenda_screen.dart        # Tela de agenda com navegação diária
    ├── clients_screen.dart       # Cadastro e listagem de clientes
    └── reports_screen.dart       # Relatórios com fl_chart
```

---

## 🚀 Como Rodar

### Pré-requisitos
- Flutter SDK ≥ 3.10.0
- Dart SDK ≥ 3.0.0

### Passos

```bash
# 1. Instalar dependências
flutter pub get

# 2. Rodar no navegador (web)
flutter run -d chrome

# 3. Build para produção web
flutter build web --release
```

### Habilitar suporte web (se necessário)
```bash
flutter config --enable-web
```

---

## 📦 Dependências Principais

| Pacote | Versão | Uso |
|---|---|---|
| `hive` | ^2.2.3 | Banco NoSQL local |
| `hive_flutter` | ^1.1.0 | Inicialização web/mobile |
| `fl_chart` | ^0.66.2 | Gráficos de barras e pizza |
| `google_fonts` | ^6.1.0 | Fontes Playfair Display + Lato |
| `intl` | ^0.18.1 | Datas em pt_BR |
| `uuid` | ^4.2.1 | IDs únicos |

---

## 🎨 Design

- **Paleta**: Rosa rosé + dourado → elegância de salão
- **Tipografia**: Playfair Display (títulos) + Lato (corpo)
- **Tema**: claro, feminino, profissional

---

## 💾 Armazenamento Hive

Os dados ficam no **IndexedDB** do navegador (web) ou em arquivos locais (mobile).
Dois boxes:
- `clients` — dados das clientes
- `appointments` — agendamentos com status (`scheduled` / `completed` / `cancelled`)

Apenas agendamentos com status **concluído** entram nos relatórios de receita.

---

## 📊 Relatórios

| Período | Métricas |
|---|---|
| **Diário** | Atendimentos do dia, receita, gráfico pizza por serviço |
| **Semanal** | Gráfico de barras por dia, detalhamento por dia |
| **Mensal** | Navegação mês a mês, barras por semana, tabela top serviços |
