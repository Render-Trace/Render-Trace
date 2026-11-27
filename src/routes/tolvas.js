var express = require("express");
var router = express.Router();

var tolvaController = require("../controllers/tolvaController");

router.get("/kpis/:idEmpresa/:idTolva", function (req, res) {
    tolvaController.buscarKpisIndividuais(req, res);
});

module.exports = router;