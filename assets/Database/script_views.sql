-- TODAS AS VIEWS TÊM UMA LEVE DESCRIÇÃO FALANDO ONDE ELAS SERÃO USADAS E COMO FILTRÁ-LAS -- 


-- // KPI de Estado de Operação Atual, Gráfico de Ocupação Atual, Última atualização (DASHBOARD INDIVIDUAL) - Filtrar o select pelo id_empresa e id_tolva // --
-- // Gráfico de Ocupação Atual das Tolvas, KPI da Tolva Mais Crítica Atualmente (DASHBOARD GERAL) - Filtrar o select pelo id_empresa // --
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


-- // KPI Total de Tolvas, KPI Tolvas em Alerta Atualmente (DASHBOARD GERAL) - Filtrar pelo id_empresa // --
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


-- // Tabela Histórico de Alertas, KPI Tempo em Alerta Atual (DASHBOARD INDIVIDUAL) - FIltrar pelo id_tolva e id_empresa // --
CREATE OR REPLACE VIEW vw_alertas AS
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

        ROUND(
            ((t.distancia_maxima - l.distancia) / t.distancia_maxima) * 100,
            2
        ) AS perc_cheia,

        CASE 
            WHEN l.distancia < t.distancia_maxima * 0.15 THEN 'Sobrecarga'
            WHEN l.distancia > t.distancia_maxima * 0.90 THEN 'Ociosidade'
            ELSE 'Normal'
        END AS estado_atual,

        LAG(
            CASE 
                WHEN l.distancia < t.distancia_maxima * 0.15 THEN 'Sobrecarga'
                WHEN l.distancia > t.distancia_maxima * 0.90 THEN 'Ociosidade'
                ELSE 'Normal'
            END
        ) OVER (
            PARTITION BY s.id
            ORDER BY l.dt_leitura, l.id
        ) AS estado_anterior

    FROM leitura l
    JOIN sensor s ON l.fk_sensor = s.id
    JOIN tolva t ON s.fk_tolva = t.id
        AND s.fk_tolva_empresa = t.fk_empresa
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
        ) OVER (
            PARTITION BY codigo_sensor
            ORDER BY dt_leitura, id_leitura
            ROWS UNBOUNDED PRECEDING
        ) AS id_episodio

    FROM leituras_com_estado
)

SELECT 
    ROW_NUMBER() OVER (
        ORDER BY MIN(dt_leitura), codigo_sensor, id_episodio
    ) AS id_alerta,
    id_tolva,
    id_empresa,
    empresa,
    codigo_sensor,
    estado_atual AS tipo_alerta,
    MIN(dt_leitura) AS inicio_alerta,
    MAX(dt_leitura) AS fim_alerta,
    TIMESTAMPDIFF(MINUTE, MIN(dt_leitura), MAX(dt_leitura)) AS duracao_minutos

FROM episodios

WHERE estado_atual <> 'Normal'

GROUP BY
    id_empresa,
    empresa,
    id_tolva,
    codigo_sensor,
    estado_atual,
    id_episodio

HAVING duracao_minutos > 0;

SELECT * FROM vw_alertas;


-- // KPI Alertas Disparados Hoje, KPI Alerta Mais Longo (DASHBOARD INDIVIDUAL) - Filtrar pelo id_tolva, id_empresa e inicio_alerta (Últimas 24 Horas) // --
CREATE OR REPLACE VIEW vw_alertas_por_tolva AS
SELECT id_tolva, id_empresa, COUNT(id_alerta) alertas_total,
SUM(CASE WHEN tipo_alerta = 'Sobrecarga' THEN 1 ELSE 0 END) alertas_sobrecarga,
SUM(CASE WHEN tipo_alerta = 'Ociosidade' THEN 1 ELSE 0 END) alertas_ociosidade FROM vw_alertas
GROUP BY id_tolva, id_empresa;

SELECT * FROM vw_alertas_por_tolva;


-- // GRÁFICO ROSQUINHA (DASH GERAL) - Filtrar o select pelo id_empresa e id_tolva // --
CREATE VIEW vw_tempo_alerta_geral AS
SELECT id_empresa, empresa, SUM(duracao_minutos) tempo_alerta_total,
SUM(CASE WHEN tipo_alerta = 'Sobrecarga' THEN duracao_minutos ELSE 0 END) tempo_sobrecarga_total,
SUM(CASE WHEN tipo_alerta = 'Ociosidade' THEN duracao_minutos ELSE 0 END) tempo_ociosidade_total
FROM vw_alertas
GROUP BY id_empresa, empresa;

SELECT * FROM vw_tempo_alerta_geral;