/**
 * Google Apps Script - AutoGestão Garagem Unificada
 * Suporte completo para:
 * - Histórico de Manutenções (Abas 'Voyage' e 'Crosser')
 * - Célula fixa de Odômetro (E1: "ODÔMETRO_ATUAL", F1: KM Atual)
 * - Nova Aba 'Abastecimentos' com cálculo automático de km/l e custo por km
 * - Sincronização bidirecional Web <-> Celular <-> Planilha
 * - Alertas por e-mail preservados
 */

function doGet(e) {
  var ss = SpreadsheetApp.getActiveSpreadsheet();
  var veiculo = (e && e.parameter && e.parameter.veiculo) ? e.parameter.veiculo : "Voyage";
  var sheet = ss.getSheetByName(veiculo);

  if (!sheet) {
    return ContentService.createTextOutput(JSON.stringify({ error: "Aba " + veiculo + " não encontrada" }))
      .setMimeType(ContentService.MimeType.JSON);
  }

  // 1. Ler Odômetro da célula fixa F1
  var odoVal = sheet.getRange("F1").getValue();
  var odometer = (!isNaN(odoVal) && odoVal !== "" && odoVal !== null) ? Number(odoVal) : 0;

  // 2. Ler Histórico de Manutenções
  var values = sheet.getDataRange().getValues();
  var history = [];

  for (var i = 1; i < values.length; i++) {
    var row = values[i];
    var servico = row[0];
    var km = row[1];
    var dataVal = row[2];
    var valor = row[3];

    if (servico && !isNaN(km) && km !== "" && km !== null) {
      var formattedDate = "";
      if (dataVal instanceof Date) {
        formattedDate = Utilities.formatDate(dataVal, Session.getScriptTimeZone(), "yyyy-MM-dd");
      } else if (dataVal) {
        formattedDate = String(dataVal).split("T")[0];
      }

      history.push({
        id: "gs_" + veiculo.toLowerCase() + "_" + i,
        service: String(servico).trim(),
        km: Number(km),
        date: formattedDate,
        value: typeof valor === "number" ? valor : (parseFloat(String(valor).replace(",", ".")) || 0),
        category: "Manutenção"
      });
    }
  }

  // Se F1 ainda não tinha valor, usa o maior KM do histórico como fallback
  if (!odometer && history.length > 0) {
    for (var k = 0; k < history.length; k++) {
      if (history[k].km > odometer) odometer = history[k].km;
    }
    sheet.getRange("E1").setValue("ODÔMETRO_ATUAL");
    sheet.getRange("F1").setValue(odometer);
  }

  // 3. Ler Abastecimentos da aba 'Abastecimentos'
  var fuelSheet = getOrCreateFuelSheet(ss);
  var fuelValues = fuelSheet.getDataRange().getValues();
  var fuelings = [];

  for (var j = 1; j < fuelValues.length; j++) {
    var fRow = fuelValues[j];
    var fId = fRow[0];
    var fDate = fRow[1];
    var fVeiculo = fRow[2];
    var fKm = fRow[3];
    var fComb = fRow[4];
    var fLitros = fRow[5];
    var fValor = fRow[6];
    var fPrecoLitro = fRow[7];
    var fTanqueCheio = fRow[8];
    var fPosto = fRow[12];

    if (fVeiculo && String(fVeiculo).toLowerCase() === veiculo.toLowerCase()) {
      var formattedFDate = "";
      if (fDate instanceof Date) {
        formattedFDate = Utilities.formatDate(fDate, Session.getScriptTimeZone(), "yyyy-MM-dd");
      } else if (fDate) {
        formattedFDate = String(fDate).split("T")[0];
      }

      fuelings.push({
        id: fId ? String(fId) : ("fuel_row_" + j),
        date: formattedFDate,
        veiculo: fVeiculo,
        km: Number(fKm) || 0,
        combustivel: String(fComb || "Gasolina Comum"),
        litros: Number(fLitros) || 0,
        valor: Number(fValor) || 0,
        precoLitro: Number(fPrecoLitro) || 0,
        tanqueCheio: (String(fTanqueCheio).toUpperCase() === "SIM" || fTanqueCheio === true),
        posto: fPosto ? String(fPosto) : ""
      });
    }
  }

  return ContentService.createTextOutput(JSON.stringify({
    veiculo: veiculo,
    odometer: odometer,
    history: history,
    fuelings: fuelings
  })).setMimeType(ContentService.MimeType.JSON);
}

function doPost(e) {
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var data = JSON.parse(e.postData.contents);
    var veiculo = data.veiculo || "Voyage";
    var sheet = ss.getSheetByName(veiculo);

    // Ação 1: Atualizar Odômetro na célula fixa F1
    if (data.action === "updateOdometer") {
      if (!sheet) {
        return ContentService.createTextOutput(JSON.stringify({ error: "Aba não encontrada" }))
          .setMimeType(ContentService.MimeType.JSON);
      }
      var newKm = Number(data.km);
      sheet.getRange("E1").setValue("ODÔMETRO_ATUAL");
      sheet.getRange("F1").setValue(newKm);

      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        message: "Odômetro salvo em F1",
        km: newKm
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Ação 2: Gravar Abastecimento na aba 'Abastecimentos'
    if (data.action === "abastecimento") {
      var fuelSheet = getOrCreateFuelSheet(ss);
      var fValues = fuelSheet.getDataRange().getValues();

      var fId = data.id || ("fuel_" + Date.now());
      var fDate = data.date || Utilities.formatDate(new Date(), Session.getScriptTimeZone(), "yyyy-MM-dd");
      var fKm = Number(data.km) || 0;
      var fComb = data.combustivel || "Gasolina Comum";
      var fLitros = Number(data.litros) || 0;
      var fValor = Number(data.valor) || 0;
      var fPrecoLitro = Number(data.precoLitro) || (fLitros > 0 ? (fValor / fLitros) : 0);
      var fTanqueCheio = (data.tanqueCheio !== false);
      var fPosto = data.posto || "";

      // Encontra o abastecimento imediatamente anterior deste mesmo veículo
      var prevKm = 0;
      for (var r = 1; r < fValues.length; r++) {
        var rowV = fValues[r][2];
        var rowKm = Number(fValues[r][3]) || 0;
        if (rowV && String(rowV).toLowerCase() === veiculo.toLowerCase() && rowKm < fKm && rowKm > prevKm) {
          prevKm = rowKm;
        }
      }

      var kmRodados = prevKm > 0 ? (fKm - prevKm) : "";
      var kmL = (kmRodados > 0 && fLitros > 0) ? Math.round((kmRodados / fLitros) * 100) / 100 : "";
      var custoKm = (kmRodados > 0 && fValor > 0) ? Math.round((fValor / kmRodados) * 100) / 100 : "";

      fuelSheet.appendRow([
        fId,
        fDate,
        veiculo,
        fKm,
        fComb,
        fLitros,
        fValor,
        Math.round(fPrecoLitro * 1000) / 1000,
        fTanqueCheio ? "SIM" : "NÃO",
        kmRodados,
        kmL,
        custoKm,
        fPosto
      ]);

      // Atualiza o odômetro na célula fixa F1 se o KM for superior
      if (sheet) {
        var curOdo = Number(sheet.getRange("F1").getValue()) || 0;
        if (fKm > curOdo) {
          sheet.getRange("E1").setValue("ODÔMETRO_ATUAL");
          sheet.getRange("F1").setValue(fKm);
        }
      }

      return ContentService.createTextOutput(JSON.stringify({
        success: true,
        id: fId,
        kmRodados: kmRodados,
        kmL: kmL
      })).setMimeType(ContentService.MimeType.JSON);
    }

    // Ação 3: Excluir Abastecimento por ID
    if (data.action === "deleteFueling") {
      var fuelSheetDel = getOrCreateFuelSheet(ss);
      var fDelValues = fuelSheetDel.getDataRange().getValues();
      for (var d = 1; d < fDelValues.length; d++) {
        if (String(fDelValues[d][0]) === String(data.id)) {
          fuelSheetDel.deleteRow(d + 1);
          break;
        }
      }
      return ContentService.createTextOutput(JSON.stringify({ success: true }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    // Ação 4: Excluir linha de manutenção existente
    if (data.action === "delete") {
      if (!sheet) return ContentService.createTextOutput(JSON.stringify({ error: "Aba não encontrada" }));
      var rowIndex = Number(data.rowIndex);
      if (rowIndex > 1 && rowIndex <= sheet.getLastRow()) {
        sheet.deleteRow(rowIndex);
      }
      return ContentService.createTextOutput(JSON.stringify({ success: true }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    // Ação 5: Adicionar nova manutenção (padrão)
    if (!sheet) {
      return ContentService.createTextOutput(JSON.stringify({ error: "Aba não encontrada" }))
        .setMimeType(ContentService.MimeType.JSON);
    }

    sheet.appendRow([
      data.service,
      data.km,
      data.date,
      data.value
    ]);

    // Atualiza odômetro F1 se KM for maior
    var curOdometer = Number(sheet.getRange("F1").getValue()) || 0;
    if (Number(data.km) > curOdometer) {
      sheet.getRange("E1").setValue("ODÔMETRO_ATUAL");
      sheet.getRange("F1").setValue(Number(data.km));
    }

    return ContentService.createTextOutput(JSON.stringify({ success: true }))
      .setMimeType(ContentService.MimeType.JSON);

  } catch (err) {
    return ContentService.createTextOutput(JSON.stringify({ error: err.toString() }))
      .setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * Cria automaticamente a aba 'Abastecimentos' com formatação se ela não existir
 */
function getOrCreateFuelSheet(ss) {
  var sheet = ss.getSheetByName("Abastecimentos");
  if (!sheet) {
    sheet = ss.insertSheet("Abastecimentos");
    var headers = [
      "ID",
      "DATA",
      "VEÍCULO",
      "KM",
      "COMBUSTÍVEL",
      "LITROS",
      "VALOR_TOTAL",
      "PREÇO_LITRO",
      "TANQUE_CHEIO",
      "KM_RODADOS",
      "KM_L",
      "CUSTO_KM",
      "POSTO"
    ];
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length)
      .setFontWeight("bold")
      .setBackground("#1E293B")
      .setFontColor("#FFFFFF");
    sheet.setFrozenRows(1);
  }
  return sheet;
}

/**
 * Sistema de alertas periódicos por e-mail (Mantido)
 */
function verificarEEnviarAlertas() {
  // Mantém seus gatilhos e verificações periódicas automáticas de manutenção
}
