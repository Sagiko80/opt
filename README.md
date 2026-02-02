const axios = require("axios");
const fs = require("fs");

const LEAGUE_ID = 922765;

// פונקציה עזר למשוך כל משתתפי הליגה
async function getLeagueEntries() {
  const url = `https://fantasy.premierleague.com/api/leagues-classic/${LEAGUE_ID}/standings/`;
  const res = await axios.get(url);
  return res.data.standings.results;
}

// פונקציה למשוך מידע של כל משתתף
async function getEntryData(entryId, gameweek) {
  const picksUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/event/${gameweek}/picks/`;
  const historyUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/history/`;

  const [picksRes, historyRes] = await Promise.all([
    axios.get(picksUrl),
    axios.get(historyUrl),
  ]);

  return {
    picks: picksRes.data.picks,
    automatic_subs: picksRes.data.automatic_subs || [],
    history: historyRes.data.current.find(h => h.event === gameweek) || {},
  };
}

// משוך רשימת כל השחקנים (למיפוי ID → שם)
async function getElementsDict() {
  const res = await axios.get("https://fantasy.premierleague.com/api/bootstrap-static/");
  const dict = {};
  res.data.elements.forEach(e => (dict[e.id] = e.web_name));
  return dict;
}

// פונקציה ראשית
async function main() {
  const gameweek = 24; // עדכן לפי מחזור נוכחי
  const elements = await getElementsDict();
  const leagueEntries = await getLeagueEntries();

  const leagueInfo = [];
  const gameweekData = [];

  for (const entry of leagueEntries) {
    const entryId = entry.entry;
    const entryData = await getEntryData(entryId, gameweek);

    // League Info
    const history = entryData.history;
    leagueInfo.push({
      rank: entry.rank,
      manager: entry.player_name,
      total_points: entry.total,
      gw_points: history.points || 0,
      team_value: history.value ? history.value / 10 : 0,
      transfers_cost: history.event_transfers_cost || 0,
      chip: history.chip || "None",
    });

    // Gameweek Data
    entryData.picks.forEach(p => {
      gameweekData.push({
        manager: entry.player_name,
        player: elements[p.element],
        position: p.position,
        captaincy: p.is_captain ? "C" : p.is_vice_captain ? "VC" : "",
        multiplier: p.multiplier,
        element_id: p.element,
      });
    });

    entryData.automatic_subs.forEach((s, i) => {
      gameweekData.push({
        manager: entry.player_name,
        player: "AUTO_SUB",
        position: `Out:${elements[s.element_out]} → In:${elements[s.element_in]}`,
        captaincy: `Order ${i + 1}`,
        multiplier: "",
        element_id: "",
      });
    });
  }

  // שמירה כ‑JSON
  fs.writeFileSync("League_Info.json", JSON.stringify(leagueInfo, null, 2));
  fs.writeFileSync("Gameweek_Data.json", JSON.stringify(gameweekData, null, 2));

  console.log("✅ Data exported to League_Info.json & Gameweek_Data.json");
}

main();