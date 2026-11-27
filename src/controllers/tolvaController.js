var tolvaModel = require("../models/tolvaModel");

function buscarKpisIndividuais(req, res) {
    var idEmpresa = req.params.idEmpresa;
    var idTolva = req.params.idTolva;

    Promise.all([
        tolvaModel.buscarKpisIndividuais(idEmpresa, idTolva),
        tolvaModel.buscarAlertas(idEmpresa, idTolva),
        tolvaModel.buscarAlertaMaisLongoHoje(idEmpresa, idTolva)
    ]).then(function ([infos, alertasHoje, alertaMaisLongo]) {
        if (infos.length > 0) {
            res.status(200).json({
                infos: infos[0],
                alertasHoje: alertasHoje[0],
                alertaMaisLongo: alertaMaisLongo[0] || null
            });
        } else {
            res.status(204).send("Nenhum resultado encontrado!");
        }
    }).catch(function (erro) {
        console.log(erro);
        console.log("Houve um erro ao buscar KPIs da tolva.", erro.sqlMessage);
        res.status(500).json(erro.sqlMessage);
    });
}

module.exports = {
    buscarKpisIndividuais
};