var tolvaModel = require("../models/tolvaModel");

function responderConsulta(req, res, consulta) {
    var idEmpresa = Number(req.params.idEmpresa);
    var idTolva = Number(req.params.idTolva);

    if (idEmpresa <= 0 || idTolva <= 0) {
        return res.status(400).json({ mensagem: "Empresa e tolva devem ter IDs inteiros positivos." });
    }

    return consulta(idEmpresa, idTolva).then(function (resultado) {
        res.status(200).json(resultado[0] || null);
    }).catch(function (erro) {
        console.log("Erro ao buscar KPI da tolva:", erro);
        res.status(500).json({ mensagem: "Erro ao buscar KPI da tolva." });
    });
}

function buscarUltimaLeitura(req, res) {
    return responderConsulta(req, res, tolvaModel.buscarUltimaLeitura);
}

function buscarEstadoAtual(req, res) {
    return responderConsulta(req, res, tolvaModel.buscarEstadoAtual);
}

function buscarTempoAlerta(req, res) {
    return responderConsulta(req, res, tolvaModel.buscarTempoAlerta);
}

function buscarQuantidadeAlertas(req, res) {
    return responderConsulta(req, res, tolvaModel.buscarQuantidadeAlertas);
}

function buscarAlertaMaisLongo(req, res) {
    return responderConsulta(req, res, tolvaModel.buscarAlertaMaisLongo);
}

module.exports = {
    buscarUltimaLeitura,
    buscarEstadoAtual,
    buscarTempoAlerta,
    buscarQuantidadeAlertas,
    buscarAlertaMaisLongo
};
