var express = require("express");
var router = express.Router();

var tolvaController = require("../controllers/tolvaController");

router.get("/ultima-leitura/:idEmpresa/:idTolva", tolvaController.buscarUltimaLeitura);
router.get("/estado-atual/:idEmpresa/:idTolva", tolvaController.buscarEstadoAtual);
router.get("/tempo-alerta/:idEmpresa/:idTolva", tolvaController.buscarTempoAlerta);
router.get("/quantidade-alertas/:idEmpresa/:idTolva", tolvaController.buscarQuantidadeAlertas);
router.get("/alerta-mais-longo/:idEmpresa/:idTolva", tolvaController.buscarAlertaMaisLongo);

module.exports = router;
