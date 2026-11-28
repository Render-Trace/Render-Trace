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


    -- -- // Tabela Histórico de Alertas, KPI Tempo em Alerta Atual (DASHBOARD INDIVIDUAL) - FIltrar pelo id_tolva e id_empresa // 
    --      esse não e o estado de operação atual --
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

    -- 1) VIEW DE APOIO: estado de cada leitura
CREATE OR REPLACE VIEW vw_leitura_estado AS
SELECT
    fk_empresa,
    fk_tolva,
    id_leitura,
    dt_leitura,
    dt,
    turno,
    percentual,
    estado,
    LAG(estado) OVER (
        PARTITION BY fk_empresa, fk_tolva
        ORDER BY dt_leitura, id_leitura
    ) AS estado_anterior
FROM (
    SELECT
        fk_empresa,
        fk_tolva,
        id_leitura,
        dt_leitura,
        DATE(dt_leitura) AS dt,
        CASE
            WHEN HOUR(dt_leitura) < 12 THEN 'manha'
            WHEN HOUR(dt_leitura) < 18 THEN 'tarde'
            ELSE 'noite'
        END AS turno,
        percentual,
        CASE
            WHEN percentual >= 85 THEN 'sobrecarga'
            WHEN percentual >= 70 THEN 'atencao'
            WHEN percentual >= 10 THEN 'normal'
            ELSE 'ociosidade'
        END AS estado
    FROM (
        SELECT
            t.fk_empresa AS fk_empresa,
            t.id AS fk_tolva,
            l.id AS id_leitura,
            l.dt_leitura AS dt_leitura,
            (t.distancia_maxima - l.distancia) / t.distancia_maxima * 100 AS percentual
        FROM leitura l
        JOIN sensor s ON l.fk_sensor = s.id
        JOIN tolva t ON s.fk_tolva = t.id
            AND s.fk_tolva_empresa = t.fk_empresa
    ) AS calculo
) AS classificada;

-- 1.2 VIEW DE APOIO) uma linha por ALERTA (só a leitura que abriu o alerta)
CREATE OR REPLACE VIEW vw_alerta_inicio AS
SELECT
    fk_empresa,
    fk_tolva,
    id_leitura,
    dt_leitura,
    dt,
    turno,
    estado
FROM vw_leitura_estado
WHERE estado IN ('ociosidade', 'sobrecarga')
AND (estado_anterior IS NULL OR estado_anterior <> estado);

-- 2) GRÁFICO: visão geral, alimenta o gráfico de barras "Quantidade de alertas por turno (semana)"
CREATE OR REPLACE VIEW vw_grafico_geral AS
SELECT
    fk_empresa,
    dt,
    SUM(CASE WHEN turno = 'manha' THEN 1 ELSE 0 END) AS manha,
    SUM(CASE WHEN turno = 'tarde' THEN 1 ELSE 0 END) AS tarde,
    SUM(CASE WHEN turno = 'noite' THEN 1 ELSE 0 END) AS noite
FROM vw_alerta_inicio
GROUP BY fk_empresa, dt;

-- 3) GRÁFICO: tolva individual, alimenta o gráfico de barras "Quantidade de alertas por turno (semana)"
CREATE OR REPLACE VIEW vw_grafico_tolva AS
SELECT
    fk_empresa,
    fk_tolva,
    dt,
    SUM(CASE WHEN turno = 'manha' THEN 1 ELSE 0 END) AS manha,
    SUM(CASE WHEN turno = 'tarde' THEN 1 ELSE 0 END) AS tarde,
    SUM(CASE WHEN turno = 'noite' THEN 1 ELSE 0 END) AS noite
FROM vw_alerta_inicio
GROUP BY fk_empresa, fk_tolva, dt;

-- 4) TABELA: visão geral, alimenta a tabela que fica embaixo do gráfico geral.
CREATE OR REPLACE VIEW vw_tabela_geral AS
SELECT
    fk_empresa,
    dt,
    SUM(CASE WHEN estado = 'ociosidade' THEN 1 ELSE 0 END) AS alertas_ociosidade,
    SUM(CASE WHEN estado = 'sobrecarga' THEN 1 ELSE 0 END) AS alertas_sobrecarga,
    COUNT(*) AS alertas_totais
FROM vw_alerta_inicio
GROUP BY fk_empresa, dt;

-- 5) TABELA: tolva individual, alimenta a tabela que fica embaixo do gráfico geral.
CREATE OR REPLACE VIEW vw_tabela_tolva AS
SELECT
    fk_empresa,
    fk_tolva,
    dt,
    SUM(CASE WHEN estado = 'ociosidade' THEN 1 ELSE 0 END) AS alertas_ociosidade,
    SUM(CASE WHEN estado = 'sobrecarga' THEN 1 ELSE 0 END) AS alertas_sobrecarga,
    COUNT(*) AS alertas_totais
FROM vw_alerta_inicio
GROUP BY fk_empresa, fk_tolva, dt;

-- 6) TABELA: ranking das tolvas (hoje), leitura a cada 3 segundos, alimenta a tabela "Ranking das tolvas sobre o tempo em alerta (hoje)".
CREATE OR REPLACE VIEW vw_ranking_tolva_dia AS
SELECT
    t.fk_empresa AS fk_empresa,
    t.id AS fk_tolva,
    ROUND(COUNT(v.id_leitura) * 3 / 60) AS tempo_alerta_min
FROM tolva t
LEFT JOIN vw_leitura_estado v
    ON v.fk_empresa = t.fk_empresa
    AND v.fk_tolva = t.id
    AND v.dt = CURDATE()
    AND v.estado IN ('ociosidade', 'sobrecarga')
GROUP BY t.fk_empresa, t.id;

-- GRÁFICO DA VISÃO GERAL
-- Busca a quantidade de alertas (ociosidade + sobrecarga) de TODAS as tolvas
-- da empresa, separada por dia e por turno (manhã, tarde e noite).
-- Alimenta o gráfico de barras "Quantidade de alertas por turno (semana)".
SELECT dt, manha, tarde, noite
FROM vw_grafico_geral
WHERE fk_empresa = ${empresaId}
AND dt BETWEEN '${dataInicio}' AND '${dataFim}'
ORDER BY dt;

-- GRÁFICO DA TOLVA INDIVIDUAL
-- Igual ao anterior, mas só de UMA tolva específica.
-- Alimenta o mesmo gráfico quando o usuário escolhe uma tolva.
SELECT dt, manha, tarde, noite
FROM vw_grafico_tolva
WHERE fk_empresa = ${empresaId}
AND fk_tolva = ${tolvaId}
AND dt BETWEEN '${dataInicio}' AND '${dataFim}'
ORDER BY dt;

-- TABELA DA VISÃO GERAL
-- Busca, por dia, quantos alertas de ociosidade, quantos de sobrecarga
-- e o total, somando TODAS as tolvas da empresa.
-- Alimenta a tabela que fica embaixo do gráfico geral.
SELECT dt, alertas_ociosidade, alertas_sobrecarga, alertas_totais
FROM vw_tabela_geral
WHERE fk_empresa = ${empresaId}
AND dt BETWEEN '${dataInicio}' AND '${dataFim}'
ORDER BY dt;

-- TABELA DA TOLVA INDIVIDUAL
-- Igual à tabela anterior, mas só de UMA tolva específica.
-- Alimenta a tabela que fica embaixo do gráfico individual.
SELECT dt, alertas_ociosidade, alertas_sobrecarga, alertas_totais
FROM vw_tabela_tolva
WHERE fk_empresa = ${empresaId}
AND fk_tolva = ${tolvaId}
AND dt BETWEEN '${dataInicio}' AND '${dataFim}'
ORDER BY dt;

-- TABELA DO RANKING DAS TOLVAS (HOJE)
-- Busca quantos minutos cada tolva da empresa ficou em alerta hoje,
-- da que ficou mais tempo para a que ficou menos.
-- Alimenta a tabela "Ranking das tolvas sobre o tempo em alerta (hoje)".
SELECT fk_tolva, tempo_alerta_min
FROM vw_ranking_tolva_dia
WHERE fk_empresa = ${empresaId}
ORDER BY tempo_alerta_min DESC;