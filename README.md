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

function applySubs(picks, automatic_subs, livePoints, elements) {
    // יוצרים העתק של ההרכב
    let finalLineup = picks.map(p => ({ ...p }));

    // מחליפים לפי סדר ההחלפות האוטומטיות
    automatic_subs.forEach(sub => {
        const outIdx = finalLineup.findIndex(p => p.element === sub.element_out);
        if (outIdx !== -1) {
            finalLineup[outIdx].element = sub.element_in;
            finalLineup[outIdx].is_captain = finalLineup[outIdx].is_captain || false;
            finalLineup[outIdx].is_vice_captain = finalLineup[outIdx].is_vice_captain || false;
        }
    });

    // מחשבים actual points לאחר החלפות
    return finalLineup.map(p => ({
        player: elements[p.element] || "Unknown",
        captaincy: p.is_captain ? "C" : p.is_vice_captain ? "VC" : "",
        multiplier: p.multiplier || 1,
        actual_points: (livePoints[p.element] || 0) * (p.multiplier || 1),
    }));
}

function getExtremes(managerName, managerGWData) {
    const best = managerGWData.reduce((a,b)=>a.actual_points>b.actual_points?a:b,{actual_points:0});
    const worst = managerGWData.reduce((a,b)=>a.actual_points<b.actual_points?a:b,{actual_points:1000});
    return { best, worst };
}

function createSummary(leagueInfo, gameweekData) {
    let summary = `⚽ סיכום מחזור ${GAMEWEEK} (Live) ⚽\n\n`;

    const sortedByGW = [...leagueInfo].sort((a,b)=>b.gw_points - a.gw_points);
    const topManager = sortedByGW[0];
    const secondManager = sortedByGW[1];

    summary += `🔥 הקרב על המקום הראשון! 🔥\n`;
    summary += `המוביל כרגע: ${topManager.manager} עם ${topManager.gw_points} נקודות\n`;
    summary += `במרחק נגיעה: ${secondManager.manager} עם ${secondManager.gw_points} נקודות\n\n`;

    leagueInfo.forEach(manager => {
        const managerGWData = gameweekData.filter(p=>p.manager===manager.manager);
        const { best, worst } = getExtremes(manager.manager, managerGWData);

        summary += `🧑‍💼 ${manager.manager} - ${manager.gw_points} נקודות\n`;

        if(best.actual_points >= 15) {
            summary += `   🌟 מהלך חכם במיוחד: ${best.player} עם ${best.actual_points} נקודות!\n`;
        }
        if(worst.actual_points === 0) {
            summary += `   ⚠️ מהלך מסוכן שכשל: ${worst.player} לא צבר נקודות\n`;
        }

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

            leagueInfo.push({
                rank: entry.rank || 0,
                manager: entry.player_name || "Unknown",
                total_points: entry.total || 0,
                gw_points: history.points || 0,
                team_value: history.value ? history.value / 10 : 0,
                transfers_cost: history.event_transfers_cost || 0,
                chip: history.chip || "None",
            });

            // חישוב הרכב סופי אחרי חילופים
            const finalLineup = applySubs(entryData.picks, entryData.automatic_subs, livePoints, elements);
            finalLineup.forEach(p => gameweekData.push({ manager: entry.player_name, ...p }));
        }

        // שמירת JSON
        fs.writeFileSync("League_Info.json", JSON.stringify(leagueInfo, null, 2));
        fs.writeFileSync("Gameweek_Data.json", JSON.stringify(gameweekData, null, 2));
        console.log("✅ JSON data exported successfully!");

        // סיכום אנליטי Live
        const summary = createSummary(leagueInfo, gameweekData);
        fs.writeFileSync("Weekly_Analysis_Summary.txt", summary);
        console.log("✅ Live summary created (Weekly_Analysis_Summary.txt)");

    } catch (error) {
        console.error("Error:", error.message);
    }
}

main();