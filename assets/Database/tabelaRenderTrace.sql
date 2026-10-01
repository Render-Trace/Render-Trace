CREATE DATABASE rendertrace;

USE rendertrace;

CREATE TABLE empresa(
id INT PRIMARY KEY AUTO_INCREMENT,
cod_acesso CHAR(5) UNIQUE,
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

CREATE TABLE alerta(
id INT PRIMARY KEY AUTO_INCREMENT,
dt_inicio DATETIME NOT NULL,
dt_fim DATETIME,
tipo_alerta VARCHAR(10) NOT NULL,
CONSTRAINT chk_alerta CHECK (tipo_alerta IN('Sobrecarga','Ocioso')),
fk_tolva INT NOT NULL, CONSTRAINT fk_tolva_alerta
					   FOREIGN KEY (fk_tolva) REFERENCES tolva(id)
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
fk_sensor INT NOT NULL, CONSTRAINT fk_sensor
			   FOREIGN KEY (fk_sensor) REFERENCES sensor(id)
);
