CREATE DATABASE rendertrace;

USE rendertrace;

-- usuarios
CREATE USER 'user_insert'@'%';

GRANT INSERT ON rendertrace.leitura TO 'user_insert'@'%';

FLUSH PRIVILEGES;


-- tabelas
CREATE TABLE empresa (
    id INT PRIMARY KEY AUTO_INCREMENT,
    cod_acesso_adm CHAR(5) NOT NULL UNIQUE,
    cod_acesso_op CHAR(5) NOT NULL UNIQUE,
    nome VARCHAR(45) NOT NULL,
    cnpj CHAR(14) NOT NULL UNIQUE,
    telefone VARCHAR(11) NOT NULL,
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
    fk_tolva_empresa INT NOT NULL,
    CONSTRAINT fk_tolva_sensor FOREIGN KEY (fk_tolva , fk_tolva_empresa)
        REFERENCES tolva (id , fk_empresa),
    CONSTRAINT uk_sensor_tolva UNIQUE (fk_tolva , fk_tolva_empresa)
);

CREATE TABLE leitura (
    id INT PRIMARY KEY AUTO_INCREMENT,
    distancia INT NOT NULL,
    dt_leitura DATETIME DEFAULT CURRENT_TIMESTAMP NOT NULL,
    fk_sensor INT NOT NULL,
    CONSTRAINT fk_sensor FOREIGN KEY (fk_sensor)
        REFERENCES sensor (id)
);


-- views
CREATE VIEW vw_infos_tolvas_individuais AS
SELECT 
    t.id AS id_tolva,
    t.fk_empresa,
    s.codigo AS codigo_sensor,
    l.distancia,
    t.distancia_maxima,
    ROUND(((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100, 2) AS perc_cheia,
    l.dt_leitura ultima_leitura
FROM tolva t
JOIN sensor s 
    ON s.fk_tolva = t.id 
   AND s.fk_tolva_empresa = t.fk_empresa
JOIN (
    SELECT fk_sensor, MAX(id) AS ultimo_id
    FROM leitura
    GROUP BY fk_sensor
) ult 
    ON ult.fk_sensor = s.id
JOIN leitura l 
    ON l.id = ult.ultimo_id
ORDER BY t.fk_empresa, t.id;

SELECT * FROM vw_infos_tolvas_individuais;

CREATE VIEW vw_tolvas_geral AS
SELECT 
    e.id id_empresa,
    e.nome empresa,
    COUNT(vit.id_tolva) AS tolvas_totais,
    SUM(CASE WHEN vit.perc_cheia > 85 OR vit.perc_cheia < 10 THEN 1 ELSE 0 END) AS tolvas_alerta,
    SUM(CASE WHEN vit.perc_cheia > 85 THEN 1 ELSE 0 END) AS tolvas_sobrecarga,
    SUM(CASE WHEN vit.perc_cheia < 10 THEN 1 ELSE 0 END) AS tolvas_ociosas
FROM empresa e
LEFT JOIN vw_infos_tolvas_individuais vit 
    ON vit.fk_empresa = e.id
GROUP BY e.id, e.nome;

SELECT * FROM vw_tolvas_geral;

CREATE VIEW vw_alertas AS
WITH leituras_com_estado AS (
    SELECT 
        l.id AS id_leitura,
        l.dt_leitura,
        e.id AS id_empresa,
        e.nome AS empresa,
        t.id AS id_tolva,
        s.codigo AS codigo_sensor,
        l.distancia,
        t.distancia_maxima,
        ROUND(((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100, 2) AS perc_cheia,
        CASE 
            WHEN ((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100 > 85 THEN 'Sobrecarga'
            WHEN ((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100 < 10 THEN 'Ociosidade'
            ELSE 'Normal'
        END AS estado_atual,
        LAG(
            CASE 
                WHEN ((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100 > 85 THEN 'Sobrecarga'
                WHEN ((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100 < 10 THEN 'Ociosidade'
                ELSE 'Normal'
            END
        ) OVER (PARTITION BY s.id ORDER BY l.dt_leitura, l.id) AS estado_anterior
    FROM leitura l
    JOIN sensor s ON l.fk_sensor = s.id
    JOIN tolva t ON s.fk_tolva = t.id AND s.fk_tolva_empresa = t.fk_empresa
    JOIN empresa e ON t.fk_empresa = e.id
),
episodios AS (
    SELECT 
        *,
        SUM(
            CASE 
                WHEN estado_atual <> COALESCE(estado_anterior, '') THEN 1 
                ELSE 0 
            END
        ) OVER (PARTITION BY codigo_sensor ORDER BY dt_leitura, id_leitura) AS id_episodio
    FROM leituras_com_estado
)
SELECT 
	id_empresa,
    empresa,
    id_tolva,
    codigo_sensor,
    estado_atual AS tipo_alerta,
    MIN(dt_leitura) AS inicio_alerta,
    MAX(dt_leitura) AS fim_alerta,
    TIMESTAMPDIFF(MINUTE, MIN(dt_leitura), MAX(dt_leitura)) AS duracao_minutos,
    COUNT(*) AS qtd_leituras_no_episodio
FROM episodios
WHERE estado_atual <> 'Normal'
GROUP BY empresa, id_tolva, codigo_sensor, estado_atual, id_episodio
HAVING TIMESTAMPDIFF(MINUTE, MIN(dt_leitura), MAX(dt_leitura)) > 10
ORDER BY inicio_alerta;

SELECT * FROM vw_alertas;

CREATE VIEW vw_tempo_alerta_geral AS
SELECT id_empresa, empresa, SUM(duracao_minutos) tempo_alerta_total,
SUM(CASE WHEN tipo_alerta = 'Sobrecarga' THEN duracao_minutos ELSE 0 END) tempo_sobrecarga_total,
SUM(CASE WHEN tipo_alerta = 'Ociosidade' THEN duracao_minutos ELSE 0 END) tempo_ociosidade_total
FROM vw_alertas
GROUP BY id_empresa, empresa;

SELECT * FROM vw_tempo_alerta_geral;

-- inserts
insert into empresa (cod_acesso_adm, cod_acesso_op, nome, cnpj, telefone, email, numero, logradouro, bairro, cidade, estado) values
('28TSA', 'B9II0', 'Spironelli', '82474003000121', '1120835486', 'matriz@spironelli.com.br', 490, 'Rua', 'Barra funda', 'São Paulo', 'SP'),
('ZUI09', 'CQAJ4', 'Grupo braido', '70733077000156', '1120378923', 'contato@grupobraido.com.br', 640, 'Avenida', 'Penha', 'São Paulo', 'SP'),
('M60CA', '058AA', 'Grapol', '59018721000171', '1120236737', 'atendimento@grapol.com.br', 47, 'Rua', 'Vila Guilherme', 'São Paulo', 'SP'),
('HE7DN', '1MP83', 'Render Company', '27834561000126', '1120543872', 'contato@render.com.br', 320, 'Avenida', 'Artur Alvim', 'São Paulo', 'SP');

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

insert into sensor(codigo, status_sensor, dt_manutencao, dt_instalacao, fk_tolva, fk_tolva_empresa) values
('EW919VM', 1, '2026-09-22', '2026-09-22', 1, 1),
('34RXGHJ', 1, '2026-03-12', '2026-03-12', 2, 1),
('VJCLBJ3', 1, '2026-09-10', '2026-09-10', 3, 1),
('FD56LC0', 1, '2026-11-02', '2026-11-02', 4, 1);

insert into sensor(codigo, status_sensor, dt_manutencao, dt_instalacao, fk_tolva, fk_tolva_empresa) values
('AV619VH', 1, '2026-09-22', '2026-09-22', 1, 2),
('CH3XGHI', 0, '2026-03-12', '2026-03-12', 2, 2),
('89LLBJP', 1, '2026-09-10', '2026-09-10', 1, 3),
('IO56H74', 1, '2026-11-02', '2026-11-02', 1, 4);

USE rendertrace;

USE rendertrace;

INSERT INTO leitura (distancia, dt_leitura, fk_sensor) VALUES
-- 1) Sensor 1 (Tolva 1, Empresa 1 | max 300):
-- Episódio de Sobrecarga de 20 min (20:00 -> 20:20): dist 30 (90%) e dist 24 (92%)
(30,  '2026-11-25 20:00:00', 1),
(24,  '2026-11-25 20:20:00', 1),

-- 2) Sensor 2 (Tolva 2, Empresa 1 | max 400):
-- Episódio de Ociosidade de 15 min (20:00 -> 20:15): dist 370 (7.5%) e dist 380 (5%)
(370, '2026-11-25 20:00:00', 2),
(380, '2026-11-25 20:15:00', 2),

-- 3) Sensor 3 (Tolva 3, Empresa 1 | max 600):
-- Alerta curto de 5 min (20:00 -> 20:05): não entra na vw_alertas (<= 10 min)
-- Última leitura em faixa normal (300 = 50%)
(560, '2026-11-25 20:00:00', 3),
(550, '2026-11-25 20:05:00', 3),
(300, '2026-11-25 20:10:00', 3),

-- 4) Sensor 4 (Tolva 4, Empresa 1 | max 150):
-- Leitura normal (75 = 50%)
(75,  '2026-11-25 20:10:00', 4),

-- 5) Sensor 5 (Tolva 1, Empresa 2 | max 300):
-- Episódio de Sobrecarga de 25 min (20:30 -> 20:55): dist 30 (90%) e dist 20 (93.33%)
(30,  '2026-11-25 20:30:00', 5),
(20,  '2026-11-25 20:55:00', 5),

-- 6) Sensor 6 (Tolva 2, Empresa 2 | max 400 | status_sensor = 0):
-- Leitura normal (200 = 50%)
(200, '2026-11-25 20:30:00', 6),

-- 7) Sensor 7 (Tolva 1, Empresa 3 | max 600):
-- Episódio de Ociosidade de 30 min (21:00 -> 21:30): dist 560 (6.67%) e dist 570 (5%)
(560, '2026-11-25 21:00:00', 7),
(570, '2026-11-25 21:30:00', 7),

-- 8) Sensor 8 (Tolva 1, Empresa 4 | max 150):
-- Leitura normal (75 = 50%)
(75,  '2026-11-25 21:00:00', 8);


-- alguns selects
SELECT * FROM leitura ORDER BY dt_leitura DESC LIMIT 10;

SELECT s.codigo, t.id id_tolva, e.nome FROM sensor s 
INNER JOIN tolva t ON s.fk_tolva = t.id AND s.fk_tolva_empresa = t.fk_empresa
INNER JOIN empresa e ON t.fk_empresa = e.id
ORDER BY e.nome;

SELECT 
    u.nome 'usuário',
    u.email,
    CASE
        WHEN u.user_admin = 1 THEN 'Administrador'
        ELSE 'Operário'
    END AS cargo,
    e.nome
FROM usuario u INNER JOIN
empresa e ON u.fk_empresa = e.id