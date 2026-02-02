const fs = require("fs");

const LEAGUE_JSON = "League_Info.json";
const GAMEWEEK_JSON = "Gameweek_Data.json";
const PREVIOUS_LEAGUE_JSON = "League_Info_Previous.json"; // מחזור קודם להשוואה

// קריאה של JSONs
const leagueInfo = JSON.parse(fs.readFileSync(LEAGUE_JSON));
const gameweekData = JSON.parse(fs.readFileSync(GAMEWEEK_JSON));
let prevLeagueInfo = [];
try { prevLeagueInfo = JSON.parse(fs.readFileSync(PREVIOUS_LEAGUE_JSON)); } catch(e){}

// פונקציות עזר
function calculateROI(playerPoints, playerCost) {
    return (playerPoints / (playerCost || 1)) * 10;
}

function getManagerPreviousRank(managerName) {
    const prev = prevLeagueInfo.find(m => m.manager === managerName);
    return prev ? prev.rank : null;
}

function analyzeManager(manager) {
    const managerGWData = gameweekData.filter(p => p.manager === manager.manager);

    // הוספת ROI לכל שחקן
    const playersWithROI = managerGWData
        .map(p => ({ ...p, roi: calculateROI(p.actual_points, p.cost || 1) }))
        .sort((a, b) => b.roi - a.roi);

    const topPlayer = playersWithROI[0];
    const worstPlayer = playersWithROI[playersWithROI.length - 1];

    const captain = managerGWData.find(p => p.captaincy === "C");
    const viceCaptain = managerGWData.find(p => p.captaincy === "VC");

    const prevRank = getManagerPreviousRank(manager.manager);
    const rankChange = prevRank ? prevRank - manager.rank : null;

    return {
        manager: manager.manager,
        rank: manager.rank,
        rankChange,
        gw_points: manager.gw_points,
        topPlayer,
        worstPlayer,
        captain,
        viceCaptain,
        chip: manager.chip,
        playersWithROI
    };
}

// מתח בצמרת
const sortedByGW = [...leagueInfo].sort((a,b)=>b.gw_points - a.gw_points);
const topManager = sortedByGW[0];
const secondManager = sortedByGW[1];

// יצירת סיכום אסטרטגי
let summary = `⚽ סיכום אסטרטגי דרמטי – מחזור סופי ⚽\n\n`;

// מתח בצמרת
summary += `🔥 הקרב על המקום הראשון 🔥\n`;
summary += `המוביל כרגע: ${topManager.manager} עם ${topManager.gw_points} נקודות`;
summary += `\nהמנסה לתפוס אותו: ${secondManager.manager} עם ${secondManager.gw_points} נקודות\n\n`;

// ניתוח מנהלים
leagueInfo.forEach(manager => {
    const analysis = analyzeManager(manager);
    summary += `🧑‍💼 ${analysis.manager} – ${analysis.gw_points} נקודות (דירוג: ${analysis.rank}`;
    if(analysis.rankChange !== null) summary += `, שינוי לעומת מחזור קודם: ${analysis.rankChange>0?`⬆${analysis.rankChange}`:`⬇${-analysis.rankChange}`}`;
    summary += `)\n`;

    // שחקן שמביא ROI הכי גבוה
    summary += `   🌟 תרומת השחקן הטובה ביותר: ${analysis.topPlayer.player} → ${analysis.topPlayer.actual_points} נקודות, ROI: ${analysis.topPlayer.roi.toFixed(2)}\n`;

    // החלטות קפטן
    if(analysis.captain) {
        summary += `   👑 קפטן: ${analysis.captain.player} +${analysis.captain.actual_points} נקודות\n`;
    }

    // צ’יפ שהופעל
    if(analysis.chip && analysis.chip !== "None") {
        summary += `   🃏 צ’יפ שהופעל: ${analysis.chip}\n`;
    }

    // שחקן עם ROI הכי נמוך
    summary += `   ⚡ ROI נמוך ביותר: ${analysis.worstPlayer.player} → ${analysis.worstPlayer.actual_points} נקודות, ROI: ${analysis.worstPlayer.roi.toFixed(2)}\n`;

    // נקודות שיחה
    summary += `   📊 נקודות לדיון:\n`;
    if(analysis.topPlayer.roi > 2) summary += `      - מהלך חכם עם שחקן בעל ROI גבוה.\n`;
    if(analysis.worstPlayer.roi < 0.5) summary += `      - החלטה שהובילה לאובדן נקודות משמעותי.\n`;
    if(analysis.captain && analysis.captain.actual_points < 5) summary += `      - קפטן פספס את הציפיות.\n`;
    summary += `\n`;
});

// שמירה לסיכום
fs.writeFileSync("Weekly_Dramatic_Strategic_Summary.txt", summary);
console.log("✅ סיכום אסטרטגי דרמטי נוצר: Weekly_Dramatic_Strategic_Summary.txt");