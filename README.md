# Sistema Integrado de Monitoramento IoT - Reciclagem Animal (Rendering) ♻️

Este repositório contém o código-fonte, a documentação e os entregáveis técnicos do projeto desenvolvido pela turma **ADSB1 (2026) da SPTech**. A solução utiliza Internet das Coisas (IoT) e análise de dados para otimizar o monitoramento de tremonhas (tolvas) no processo de reciclagem de resíduos animais.

**Equipe:** Dayvid Dias, Gustavo Santana, Leonardo Cardoso, Leonardo Magagnin, Luigi Alcâncio e Pedro Antunes.

---

## 🎯 Contexto e Solução

No processo de Rendering, o armazenamento de materiais (ossos, gorduras, vísceras) nas tremonhas é uma etapa crítica. A falta de monitoramento contínuo causa gargalos, superlotação, paradas na produção e perdas financeiras.

Nossa solução implementa **sensores sônicos** para o monitoramento contínuo dos níveis de preenchimento. Os dados são processados e enviados para um banco de dados em nuvem, alimentando uma dashboard de gestão que permite aos operadores prevenirem perdas e melhorarem a eficiência operacional e sustentável da empresa.

---

## 📦 Arquitetura e Entregáveis (Sprint 2)

O projeto está estruturado em frentes de desenvolvimento integradas, cobrindo desde a captura do dado físico até a visualização final pelo usuário:

### 💻 Front-End (Algoritmos e Interfaces)
Desenvolvimento das interfaces de interação com o usuário operando de forma estática (Local):
- **Site Institucional:** Construído com HTML, CSS e JavaScript, aplicando lógica de estruturas de repetição.
- **Plataforma de Acesso:** Telas estáticas para Cadastro e Login de usuários.
- **Dashboard de Monitoramento:** Interface gráfica para análise de dados utilizando a biblioteca **ChartJS**.

### 🗄️ Infraestrutura e Dados (Sistemas Operacionais e Banco de Dados)
Estruturação do armazenamento e hospedagem da aplicação:
- **Modelagem Lógica v1:** Mapeamento das entidades e relacionamentos do sistema.
- **Banco de Dados:** Scripts DDL para criação das tabelas e instanciamento do banco de dados local.
- **Servidor VMLinux:** Instalação e configuração do MySQL no servidor de dados da solução (Máquina Virtual Linux).
- **Integração:** Pipeline configurado para a inserção de dados gerados pelo Arduino diretamente no MySQL hospedado na VMLinux.

### 🔌 Hardware e IoT (Arquitetura Computacional)
Captura de dados do ambiente físico:
- **Testes de Integração:** Experimentos práticos utilizando o sensor sônico do projeto.
- **Simulação de Fluxo:** Utilização de API Local/Sensor para gerar dados, integrá-los com gráficos e simular a operação real nas tremonhas.

### ⚙️ Engenharia de Software e Gestão (TI e Inovação)
Planejamento, documentação e garantia da qualidade técnica:
- **Arquitetura Técnica:** Elaboração e validação do Diagrama da Solução.
- **Documentação de Requisitos:** Especificação detalhada da Dashboard e criação da Planilha de Riscos do Projeto.
- **Gestão Ágil:** Estruturação do Backlog da Sprint (Demandas, Pontuação, Prioridade) e organização das atividades na ferramenta de gestão.