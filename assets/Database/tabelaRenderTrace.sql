CREATE DATABASE rendertrace;

USE rendertrace;

CREATE TABLE empresa(
id INT PRIMARY KEY AUTO_INCREMENT,
cod_acesso_adm CHAR(5) UNIQUE,
cod_acesso_op CHAR(5) UNIQUE,
nome VARCHAR(45) NOT NULL,
cnpj CHAR(14) NOT NULL UNIQUE,
numero INT,
logradouro VARCHAR(60),
bairro VARCHAR(45),
cidade VARCHAR(45),
estado CHAR(2),
telefone VARCHAR(10),
fk_empresa_sede INT, CONSTRAINT fk_empresa_sede
			   FOREIGN KEY (fk_empresa_sede) REFERENCES empresa(id)
);



CREATE TABLE usuario(
id INT PRIMARY KEY AUTO_INCREMENT,
nome VARCHAR(45) NOT NULL,
email VARCHAR(60) NOT NULL UNIQUE,
senha VARCHAR(100) NOT NULL,
user_admin TINYINT, CONSTRAINT user_admin CHECK (user_admin IN(0,1)),
fk_empresa INT NOT NULL, CONSTRAINT fk_usuario_empresa 
				FOREIGN KEY (fk_empresa) REFERENCES empresa(id)
);

CREATE TABLE tolva(
id INT PRIMARY KEY AUTO_INCREMENT,
distancia_maxima INT NOT NULL,
capacidade_maxima INT NOT NULL,
em_operacao TINYINT NOT NULL, CONSTRAINT chk_operacao CHECK (em_operacao IN(0,1)),
fk_empresa INT NOT NULL, CONSTRAINT fk_tolva_empresa
				FOREIGN KEY (fk_empresa) REFERENCES empresa(id)
);

CREATE TABLE sensor(
id INT PRIMARY KEY AUTO_INCREMENT,
codigo VARCHAR(45) NOT NULL,
status_sensor TINYINT NOT NULL,
CONSTRAINT chk_sensor CHECK(status_sensor IN(0,1)),
dt_manutencao DATE NOT NULL,
dt_instalacao DATE NOT NULL,
fk_tolva INT UNIQUE NOT NULL, CONSTRAINT fk_tolva_sensor
			  FOREIGN KEY (fk_tolva) REFERENCES tolva(id)
);

CREATE TABLE leitura(
id INT PRIMARY KEY AUTO_INCREMENT,
distancia INT NOT NULL,
dt_leitura DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
tipo VARCHAR(10), CONSTRAINT chk_tipo CHECK (tipo IN('Sobrecarga','Ocioso')),
alerta TINYINT NOT NULL, CONSTRAINT chk_alerta CHECK(alerta IN(0,1)),
fk_sensor INT NOT NULL, CONSTRAINT fk_sensor
			   FOREIGN KEY (fk_sensor) REFERENCES sensor(id)
);


insert into empresa (cod_acesso_adm, cod_acesso_op, nome, cnpj, numero, logradouro, bairro, cidade, estado, telefone, fk_empresa_sede) values
('28TSA', 'B9II0', 'Spironelli', '82474003000121', '490', 'Rua', 'Barra funda', 'São Paulo', 'SP', 1120835486, null),
('ZUI09', 'CQAJ4', 'Grupo braido', '70733077000156', '640', 'Avenida', 'Penha', 'São Paulo', 'SP', 1120378923, null),
('M60CA', '058AA', 'Grapol', '59018721000171', '47', 'Rua', 'Vila Guilherme', 'São Paulo', 'SP', 1120236737, null),
('HE7DN', '1MP83', 'Spironelli', 27834561097326, 32, 'Avenida', 'Artur Alvim', 'São Paulo', 'SP', 1120543872, 1 );

insert into usuario(nome, email, senha, user_admin, fk_empresa) values
('Cristiano', 'cristiano@gmail.com', 'Cris123#', 1,1),
('Kaue', 'kaue@gmail.com', 'Kaue01k&', 0, 1),
('Caio', 'caio@gmail.com', 'Cai0%$', 0, 2),
('Pietro', 'pietro@gmail.com', 'P1etro#23', 1, 2),
('Kalebe', 'kalebe@gmail.com', 'Kal3b3%', 1, 3),
('José', 'jose@gmail.com', 'Jose2039@', 0, 3);

insert into tolva(distancia_maxima, capacidade_maxima, em_operacao, fk_empresa) values
(300, 5, 1, 1), -- Médio porte
(400, 10, 0, 1), -- Grande porte
(600, 14, 1, 2), -- Grande porte
(150, 1, 1, 3); -- Pequeno porte


insert into sensor(codigo, status_sensor, dt_manutencao, dt_instalacao, fk_tolva) values
('EW919VM', 1, '2026-09-22', '2026-09-22', 1),
('34RXGHJ', 0, '2026-03-12', '2026-03-12', 2),
('VJCLBJ3', 1, '2026-09-10', '2026-09-10', 3),
('FD56LC0', 1, '2026-11-02', '2026-11-02', 4);
