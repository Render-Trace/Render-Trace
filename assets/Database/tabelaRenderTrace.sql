CREATE DATABASE rendertrace;

USE rendertrace;

CREATE USER 'user_insert'@'_gateway';

GRANT UPDATE ON rendertrace.leitura TO 'user_insert'@'_gateway';

FLUSH PRIVILEGES;

CREATE TABLE empresa (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cod_acesso_adm CHAR(5) NOT NULL UNIQUE,
    cod_acesso_op CHAR(5) NOT NULL UNIQUE,
    nome VARCHAR(45) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(10) NOT NULL,
    email VARCHAR(60) NOT NULL UNIQUE,
    numero INT NOT NULL,
    logradouro VARCHAR(60) NOT NULL,
    bairro VARCHAR(45) NOT NULL,
    cidade VARCHAR(45) NOT NULL,
    estado CHAR(2) NOT NULL
);

CREATE TABLE usuario (
    id INT PRIMARY KEY AUTO_INCREMENT,
    nome VARCHAR(45) NOT NULL,
    email VARCHAR(60) NOT NULL UNIQUE,
    senha VARCHAR(100) NOT NULL,
    user_admin TINYINT,
    CONSTRAINT user_admin CHECK (user_admin IN (0 , 1)),
    fk_empresa INT NOT NULL,
    CONSTRAINT fk_usuario_empresa FOREIGN KEY (fk_empresa)
        REFERENCES empresa (id)
);

CREATE TABLE tolva (
    id INT NOT NULL,
    distancia_maxima INT NOT NULL,
    capacidade_maxima INT NOT NULL,
    fk_empresa INT NOT NULL,
    CONSTRAINT fk_tolva_empresa FOREIGN KEY (fk_empresa)
        REFERENCES empresa (id),
    PRIMARY KEY (id , fk_empresa)
);

CREATE TABLE sensor (
    id INT PRIMARY KEY AUTO_INCREMENT,
    codigo VARCHAR(45) NOT NULL UNIQUE,
    status_sensor TINYINT NOT NULL,
    CONSTRAINT chk_sensor CHECK (status_sensor IN (0 , 1)),
    dt_manutencao DATE NOT NULL,
    dt_instalacao DATE NOT NULL,
    fk_tolva INT NOT NULL,
    fk_empresa INT NOT NULL,
    CONSTRAINT fk_tolva_sensor FOREIGN KEY (fk_tolva , fk_empresa)
        REFERENCES tolva (id , fk_empresa),
    CONSTRAINT uk_sensor_tolva UNIQUE (fk_tolva , fk_empresa)
);

CREATE TABLE leitura (
    id INT PRIMARY KEY AUTO_INCREMENT,
    distancia INT NOT NULL,
    dt_leitura DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    alerta TINYINT NOT NULL,
    CONSTRAINT chk_alerta CHECK (alerta IN (0 , 1)),
    fk_sensor INT NOT NULL,
    CONSTRAINT fk_sensor FOREIGN KEY (fk_sensor)
        REFERENCES sensor (id)
);

insert into empresa (cod_acesso_adm, cod_acesso_op, nome, cnpj, telefone, email, numero, logradouro, bairro, cidade, estado) values
('28TSA', 'B9II0', 'Spironelli', '82474003000121', '1120835486', 'matriz@spironelli.com.br', 490, 'Rua', 'Barra funda', 'São Paulo', 'SP'),
('ZUI09', 'CQAJ4', 'Grupo braido', '70733077000156', '1120378923', 'contato@grupobraido.com.br', 640, 'Avenida', 'Penha', 'São Paulo', 'SP'),
('M60CA', '058AA', 'Grapol', '59018721000171', '1120236737', 'atendimento@grapol.com.br', 47, 'Rua', 'Vila Guilherme', 'São Paulo', 'SP'),
('HE7DN', '1MP83', 'Spironelli', '27834561000126', '1120543872', 'filial.arturalvim@spironelli.com.br', 320, 'Avenida', 'Artur Alvim', 'São Paulo', 'SP');

insert into usuario(nome, email, senha, user_admin, fk_empresa) values
('Cristiano', 'cristiano@gmail.com', 'Cris123#', 1,1),
('Kaue', 'kaue@gmail.com', 'Kaue01k&', 0, 1),
('Caio', 'caio@gmail.com', 'Cai0%$', 0, 2),
('Pietro', 'pietro@gmail.com', 'P1etro#23', 1, 2),
('Kalebe', 'kalebe@gmail.com', 'Kal3b3%', 1, 3),
('José', 'jose@gmail.com', 'Jose2039@', 0, 3);

insert into tolva values
(1, 300, 5, 1), -- Médio porte
(2, 400, 10, 1), -- Grande porte
(3, 600, 14, 1), -- Grande porte
(4, 150, 1, 1), -- Pequeno porte
(1, 300, 5, 2), -- Médio porte
(2, 400, 10, 2), -- Grande porte
(1, 600, 14, 3), -- Grande porte
(1, 150, 1, 4); -- Pequeno porte;

insert into sensor(codigo, status_sensor, dt_manutencao, dt_instalacao, fk_tolva, fk_empresa) values
('EW919VM', 1, '2026-09-22', '2026-09-22', 1, 1),
('34RXGHJ', 0, '2026-03-12', '2026-03-12', 2, 1),
('VJCLBJ3', 1, '2026-09-10', '2026-09-10', 3, 1),
('FD56LC0', 1, '2026-11-02', '2026-11-02', 4, 1);