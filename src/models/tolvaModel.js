
var database = require("../database/config");

function buscarUltimaLeitura(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT ultima_leitura
        FROM vw_infos_tolvas_individuais
        WHERE fk_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva}
        ORDER BY ultima_leitura DESC
        LIMIT 1;
    `;

    return database.executar(instrucaoSql);
}

function buscarEstadoAtual(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT perc_cheia
        FROM vw_infos_tolvas_individuais
        WHERE fk_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva}
        ORDER BY ultima_leitura DESC
        LIMIT 1;
    `;

    return database.executar(instrucaoSql);
}

function buscarQuantidadeAlertas(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT COUNT(*) AS alertas_total
        FROM vw_alertas
        WHERE id_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva};
    `;

    return database.executar(instrucaoSql);
}

function buscarTempoAlerta(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT SUM(duracao_minutos) AS tempo_alerta_total
        FROM vw_alertas
        WHERE id_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva};
    `;
    return database.executar(instrucaoSql);
}

function buscarAlertaMaisLongo(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT duracao_minutos, tipo_alerta, inicio_alerta
        FROM vw_alertas
        WHERE id_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva}
        ORDER BY duracao_minutos DESC, inicio_alerta DESC
        LIMIT 1;
    `;

    return database.executar(instrucaoSql);
}

module.exports = {
    buscarUltimaLeitura,
    buscarEstadoAtual,
    buscarQuantidadeAlertas,
    buscarTempoAlerta,
    buscarAlertaMaisLongo
};
