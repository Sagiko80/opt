/************ CONFIG ************/
const LEAGUE_ID = 922765;
const GAMEWEEK = getLastFinishedGW(); // אוטומטי
const BASE_URL = "https://fantasy.premierleague.com/api/";

/************ ENTRY POINT ************/
function runWeeklyFPLAnalysis() {
  const ss = SpreadsheetApp.getActive();
  resetSheets(ss);

  const leagueEntries = getLeagueEntries();
  const elements = getElementsDict();

  leagueEntries.forEach(entry => {
    const entryId = entry.entry;
    const picksData = getEntryPicks(entryId);
    const historyData = getEntryHistory(entryId);

    writeLeagueInfo(entry, historyData);
    writeGameweekData(entry, picksData, elements);
  });

  SpreadsheetApp.flush();
}

/************ DATA FETCHERS ************/
function getLeagueEntries() {
  const url = `${BASE_URL}leagues-classic/${LEAGUE_ID}/standings/`;
  return JSON.parse(UrlFetchApp.fetch(url)).standings.results;
}

function getEntryPicks(entryId) {
  const url = `${BASE_URL}entry/${entryId}/event/${GAMEWEEK}/picks/`;
  return JSON.parse(UrlFetchApp.fetch(url));
}

function getEntryHistory(entryId) {
  const url = `${BASE_URL}entry/${entryId}/history/`;
  return JSON.parse(UrlFetchApp.fetch(url));
}

function getElementsDict() {
  const data = JSON.parse(UrlFetchApp.fetch(`${BASE_URL}bootstrap-static/`));
  const dict = {};
  data.elements.forEach(e => dict[e.id] = e.web_name);
  return dict;
}

function getLastFinishedGW() {
  const data = JSON.parse(UrlFetchApp.fetch(`${BASE_URL}bootstrap-static/`));
  const gw = data.events.filter(e => e.finished).pop();
  return gw.id;
}

/************ WRITERS ************/
function writeLeagueInfo(entry, history) {
  const sheet = SpreadsheetApp.getActive().getSheetByName("League_Info");
  const lastGW = history.current.find(h => h.event === GAMEWEEK);

  sheet.appendRow([
    entry.rank,
    entry.player_name,
    entry.total,
    lastGW.points,
    lastGW.value / 10,
    lastGW.event_transfers_cost,
    lastGW.chip || "None"
  ]);
}

function writeGameweekData(entry, picksData, elements) {
  const sheet = SpreadsheetApp.getActive().getSheetByName("Gameweek_Data");

  picksData.picks.forEach(p => {
    sheet.appendRow([
      entry.player_name,
      elements[p.element],
      p.position,
      p.is_captain ? "C" : p.is_vice_captain ? "VC" : "",
      p.multiplier,
      p.element
    ]);
  });

  picksData.automatic_subs.forEach((s, i) => {
    sheet.appendRow([
      entry.player_name,
      "AUTO_SUB",
      `Out:${elements[s.element_out]} → In:${elements[s.element_in]}`,
      `Order ${i + 1}`,
      "",
      ""
    ]);
  });
}

/************ SHEET SETUP ************/
function resetSheets(ss) {
  const sheets = ["League_Info", "Gameweek_Data"];
  sheets.forEach(name => {
    let sh = ss.getSheetByName(name);
    if (!sh) sh = ss.insertSheet(name);
    sh.clear();
  });

  ss.getSheetByName("League_Info").appendRow([
    "Rank",
    "Manager",
    "Total Points",
    "GW Points",
    "Team Value",
    "Transfer Cost",
    "Chip Used"
  ]);

  ss.getSheetByName("Gameweek_Data").appendRow([
    "Manager",
    "Player",
    "Position",
    "Captaincy",
    "Multiplier",
    "Element ID"
  ]);
}