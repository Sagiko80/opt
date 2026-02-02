const axios = require("axios");
const fs = require("fs");

const LEAGUE_ID = 922765;
const GAMEWEEK = 24; // עדכן למחזור הרצוי

// ------------------------- פונקציות עזר -------------------------

async function getLeagueEntries() {
    const url = `https://fantasy.premierleague.com/api/leagues-classic/${LEAGUE_ID}/standings/`;
    const res = await axios.get(url);
    return res.data.standings.results;
}

async function getEntryData(entryId) {
    const picksUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/event/${GAMEWEEK}/picks/`;
    const historyUrl = `https://fantasy.premierleague.com/api/entry/${entryId}/history/`;

    const picksRes = await axios.get(picksUrl);
    const historyRes = await axios.get(historyUrl);

    return {
        picks: picksRes.data.picks || [],
        automatic_subs: picksRes.data.automatic_subs || [],
        history: (historyRes.data.current || []).find(h => h.event === GAMEWEEK) || {},
    };
}

async function getElementsDict() {
    const res = await axios.get("https://fantasy.premierleague.com/api/bootstrap-static/");
    const dict = {};
    res.data.elements.forEach(e => dict[e.id] = e.web_name);
    return dict;
}

async function getLivePoints() {
    const url = `https://fantasy.premierleague.com/api/event/${GAMEWEEK}/live/`;
    const res = await axios.get(url);
    const points = {};
    (res.data.elements || []).forEach(e => {
        points[e.id] = e.stats.total_points || 0;
    });
    return points;
}

// ------------------------- פונקציות לסיכום -------------------------

function getExtremes(managerName, gameweekData) {
    const gwPlayers = gameweekData.filter(p => p.manager === managerName);
    const best = gwPlayers.reduce((a,b)=>a.actual_points>b.actual_points?a:b,{actual_points:0});
    const worst = gwPlayers.reduce((a,b)=>a.actual_points<b.actual_points?a:b,{actual_points:1000});
    return { best, worst };
}

function createSummary(leagueInfo, gameweekData) {
    let summary = `⚽ סיכום מחזור ${GAMEWEEK} ⚽\n\n`;

    const sortedByGW = [...leagueInfo].sort((a,b)=>b.gw_points - a.gw_points);
    const topManager = sortedByGW[0];
    const secondManager = sortedByGW[1];

    // מתח בצמרת
    summary += `🔥 הקרב על המקום הראשון! 🔥\n`;
    summary += `המוביל כרגע: ${topManager.manager} עם ${topManager.gw_points} נקודות במחזור הזה!\n`;
    summary += `במרחק נגיעה: ${secondManager.manager} עם ${secondManager.gw_points} נקודות.\n\n`;

    leagueInfo.forEach(manager => {
        const {best, worst} = getExtremes(manager.manager, gameweekData);
        summary += `🧑‍💼 ${manager.manager} - ${manager.gw_points} נקודות\n`;

        if(best.actual_points >= 15) {
            summary += `   🌟 מהלך חכם במיוחד: ${best.player} עם ${best.actual_points} נקודות!\n`;
        }
        if(worst.actual_points === 0 && worst.player !== "AUTO_SUB") {
            summary += `   ⚠️ מהלך מסוכן שכשל: ${worst.player} לא צבר נקודות.\n`;
        }

        const subs = gameweekData.filter(p=>p.manager===manager.manager && p.player==="AUTO_SUB");
        subs.forEach(s=>{
            summary += `   🔄 חילוף אוטומטי: ${s.position}, צבר ${s.actual_points} נקודות\n`;
        });

        if(manager.chip && manager.chip !== "None") {
            summary += `   🃏 צ’יפ שהופעל: ${manager.chip}\n`;
        }

        summary += `\n`;
    });

    return summary;
}

// ------------------------- פונקציה ראשית -------------------------

async function main() {
    try {
        const elements = await getElementsDict();
        const livePoints = await getLivePoints();
        const leagueEntries = await getLeagueEntries();

        const leagueInfo = [];
        const gameweekData = [];

        for (const entry of leagueEntries) {
            const entryId = entry.entry;
            const entryData = await getEntryData(entryId);
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

        // שמירה JSON
        fs.writeFileSync("League_Info.json", JSON.stringify(leagueInfo, null, 2));
        fs.writeFileSync("Gameweek_Data.json", JSON.stringify(gameweekData, null, 2));
        console.log("✅ JSON data exported successfully!");

        // סיכום אנליטי
        const summary = createSummary(leagueInfo, gameweekData);
        fs.writeFileSync("Weekly_Analysis_Summary.txt", summary);
        console.log("✅ Weekly summary created (Weekly_Analysis_Summary.txt)");

    } catch (error) {
        console.error("Error:", error.message);
    }
}

main();