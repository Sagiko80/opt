const fs = require("fs");

// קריאה של הקבצים שנשמרו
const leagueInfo = JSON.parse(fs.readFileSync("League_Info.json"));
const gameweekData = JSON.parse(fs.readFileSync("Gameweek_Data.json"));

// מיון לפי נקודות מחזור כדי למצוא את המובילים
const sortedByGW = [...leagueInfo].sort((a,b) => b.gw_points - a.gw_points);
const topManager = sortedByGW[0];
const secondManager = sortedByGW[1];

// פונקציה למציאת השחקן הכי טוב/רע של כל משתתף
function getExtremes(manager) {
    const gwPlayers = gameweekData.filter(p => p.manager === manager.manager);
    const best = gwPlayers.reduce((a,b)=>a.actual_points>b.actual_points?a:b,{actual_points:0});
    const worst = gwPlayers.reduce((a,b)=>a.actual_points<b.actual_points?a:b,{actual_points:1000});
    return { best, worst };
}

// יצירת סיכום
let summary = `⚽ סיכום מחזור ${gameweekData[0]?.position || ''} ⚽\n\n`;

// מתח בצמרת
summary += `🔥 הקרב על המקום הראשון! 🔥\n`;
summary += `המוביל כרגע: ${topManager.manager} עם ${topManager.gw_points} נקודות במחזור הזה!\n`;
summary += `במרחק נגיעה: ${secondManager.manager} עם ${secondManager.gw_points} נקודות.\n\n`;

leagueInfo.forEach(manager => {
    const {best, worst} = getExtremes(manager);
    summary += `🧑‍💼 ${manager.manager} - ${manager.gw_points} נקודות\n`;

    // החלטה חריגה חיובית
    if(best.actual_points >= 15) {
        summary += `   🌟 מהלך חכם במיוחד: ${best.player} עם ${best.actual_points} נקודות!\n`;
    }

    // החלטה חריגה שלילית
    if(worst.actual_points === 0 && worst.player !== "AUTO_SUB") {
        summary += `   ⚠️ מהלך מסוכן שכשל: ${worst.player} לא צבר נקודות.\n`;
    }

    // חילופים חריגים
    const subs = gameweekData.filter(p=>p.manager===manager.manager && p.player==="AUTO_SUB");
    subs.forEach(s=>{
        summary += `   🔄 חילוף אוטומטי: ${s.position}, צבר ${s.actual_points} נקודות\n`;
    });

    // צ'יפ אם שונה מ‑None
    if(manager.chip && manager.chip !== "None") {
        summary += `   🃏 צ’יפ שהופעל: ${manager.chip}\n`;
    }

    summary += `\n`;
});

// שמירה לקובץ טקסט מוכן לווצאפ
fs.writeFileSync("Weekly_Analysis_Summary.txt", summary);
console.log("✅ Summary created! Check Weekly_Analysis_Summary.txt");