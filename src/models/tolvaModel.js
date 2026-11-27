
var database = require("../database/config");

function buscarKpisIndividuais(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT *
        FROM vw_infos_tolvas_individuais
        WHERE fk_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva};
    `;

    return database.executar(instrucaoSql);
}

function buscarAlertas(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT *
        FROM vw_alertas
        WHERE id_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva};
    `;

    return database.executar(instrucaoSql);
}

function buscarAlertaMaisLongoHoje(idEmpresa, idTolva) {
    var instrucaoSql = `
        SELECT *
        FROM vw_alertas_por_tolva
        WHERE id_empresa = ${idEmpresa}
        AND id_tolva = ${idTolva};
    `;

    return database.executar(instrucaoSql);
}

module.exports = {
    buscarKpisIndividuais,
    buscarAlertas,
    buscarAlertaMaisLongoHoje
};
