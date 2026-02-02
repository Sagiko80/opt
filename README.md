const axios = require("axios");
const fs = require("fs");

const LEAGUE_ID = 922765;

// מושך את המחזור האחרון שהסתיים
async function getLastFinishedGW() {
  const res = await axios.get("https://fantasy.premierleague.com/api/bootstrap-static/");
  const events = res.data.events;
  const lastFinished = events.filter(e => e.finished).pop();
  return lastFinished.id;
}

// מושך את כל המשתתפים בליגה
async function getLeagueEntries() {
  const url = `https://fantasy.premierleague.com/api/leagues-classic/${LEAGUE_ID}/standings/`;
  const res = await axios.get(url);
  return res.data.standings.results;
}

// מושך את picks + חילופים + היסטוריה למחזור ספציפי
async function getEntryData(entryId, gameweek) {
  const picksUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/event/${gameweek}/picks/`;
  const historyUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/history/`;

  const picksRes = await axios.get(picksUrl);
  const historyRes = await axios.get(historyUrl);

  return {
    picks: picksRes.data.picks || [],
    automatic_subs: picksRes.data.automatic_subs || [],
    history: (historyRes.data.current || []).find(h => h.event === gameweek) || {},
  };
}

// מושך את כל השחקנים + שמות
async function getElementsDict() {
  const res = await axios.get("https://fantasy.premierleague.com/api/bootstrap-static/");
  const dict = {};
  res.data.elements.forEach(e => dict[e.id] = e.web_name);
  return dict;
}

// מושך ניקוד אמיתי של כל השחקנים במחזור
async function getLivePoints(gameweek) {
  const url = `https://fantasy.premierleague.com/api/event/${gameweek}/live/`;
  const res = await axios.get(url);
  const points = {};
  (res.data.elements || []).forEach(e => {
    points[e.id] = e.stats.total_points || 0;
  });
  return points;
}

// פונקציה ראשית
async function main() {
  try {
    const GAMEWEEK = await getLastFinishedGW();
    console.log("Using Gameweek:", GAMEWEEK);

    const elements = await getElementsDict();
    const livePoints = await getLivePoints(GAMEWEEK);
    const leagueEntries = await getLeagueEntries();

    const leagueInfo = [];
    const gameweekData = [];

    for (const entry of leagueEntries) {
      const entryId = entry.entry;
      const entryData = await getEntryData(entryId, GAMEWEEK);
      const history = entryData.history;

      // League Info
      leagueInfo.push({
        rank: entry.rank || 0,
        manager: entry.player_name || "Unknown",
        total_points: entry.total || 0,
        gw_points: history.points || 0,
        team_value: history.value ? history.value / 10 : 0,
        transfers_cost: history.event_transfers_cost || 0,
        chip: history.chip || "None",
      });

      // Gameweek Data
      (entryData.picks || []).forEach(p => {
        const actualPoints = (livePoints[p.element] || 0) * (p.multiplier || 1);
        gameweekData.push({
          manager: entry.player_name,
          player: elements[p.element] || "Unknown",
          position: p.position || 0,
          captaincy: p.is_captain ? "C" : p.is_vice_captain ? "VC" : "",
          multiplier: p.multiplier || 1,
          element_id: p.element || 0,
          actual_points: actualPoints
        });
      });

      // חילופים אוטומטיים
      (entryData.automatic_subs || []).forEach((s, i) => {
        const actualPoints = (livePoints[s.element_in] || 0);
        gameweekData.push({
          manager: entry.player_name,
          player: "AUTO_SUB",
          position: `Out:${elements[s.element_out] || "?"} → In:${elements[s.element_in] || "?"}`,
          captaincy: `Order ${i + 1}`,
          multiplier: "",
          element_id: "",
          actual_points: actualPoints
        });
      });
    }

    // שמירה כ‑JSON
    fs.writeFileSync("League_Info.json", JSON.stringify(leagueInfo, null, 2));
    fs.writeFileSync("Gameweek_Data.json", JSON.stringify(gameweekData, null, 2));

    console.log("✅ All data exported with live points!");
  } catch (error) {
    console.error("Error:", error.message);
  }
}

main();