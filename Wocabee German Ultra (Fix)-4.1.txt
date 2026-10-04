// ==UserScript==
// @name         Wocabee German Ultra (Fix)
// @namespace    http://tampermonkey.net/
// @version      4.1
// @description  Německá nápověda pro Wocabee - Oprava zobrazení menu
// @author       AI Assistant
// @match        *://*.wocabee.app/*
// @grant        GM_setValue
// @grant        GM_getValue
// ==/UserScript==

(async function() {
    'use strict';

    let customDict = GM_getValue('wocabee_dict', {});
    let posledniOtazka = "";
    let jeViditelny = true;

    // Klávesa ';' pro schování
    window.addEventListener('keydown', (e) => {
        if (e.key === ';') {
            jeViditelny = !jeViditelny;
            const el = document.getElementById('napovedaWoca');
            if (el) el.style.display = jeViditelny ? 'block' : 'none';
        }
    });

    async function translateWord(word) {
        if (customDict[word]) return customDict[word];
        try {
            const isGerman = /^(der|die|das|ein|eine|einer)\b/i.test(word) || /[\u00C4\u00D6\u00DC\u00DF]/.test(word);
            const langPair = isGerman ? 'de|cs' : 'cs|de';
            const response = await fetch(`https://api.mymemory.translated.net/get?q=${encodeURIComponent(word)}&langpair=${langPair}`);
            const data = await response.json();
            return data.responseData.translatedText;
        } catch (e) {
            return "Chyba překladu";
        }
    }

    // Funkce pro vytvoření boxu, pokud neexistuje
    function vytvorBox() {
        let el = document.getElementById('napovedaWoca');
        if (!el) {
            el = document.createElement('div');
            el.id = 'napovedaWoca';
            el.style.cssText = `position: fixed; bottom: 20px; left: 20px; background: #111; color: lime; padding: 15px; z-index: 9999; border-radius: 10px; border: 2px solid lime; font-family: sans-serif; width: 320px; box-shadow: 0 0 15px black;`;
            document.body.appendChild(el);
        }
        return el;
    }

    async function napovezWocabee() {
        let el = vytvorBox(); // Box vytvoříme hned na začátku

        if (!jeViditelny) {
            el.style.display = 'none';
            return;
        } else {
            el.style.display = 'block';
        }

        // Hledání otázky
        let questionElement = document.querySelector('#q_word') || document.querySelector('.question, .word-text, [class*="question"]');

        if (!questionElement) {
            el.innerHTML = `<div style="text-align: center; color: #888;">🕒 Čekám na otázku...</div>`;
            return;
        }

        const question = questionElement.innerText.trim();
        if (!question) return;

        if (question === posledniOtazka) return;
        posledniOtazka = question;

        if (document.activeElement && (document.activeElement.id === 'woca_correct' || document.activeElement.id === 'woca_import_val')) return;

        const answer = await translateWord(question);

        el.innerHTML = `
            <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 10px;">
                <div style="font-size: 18px;">👉 <b style="color: white;">${answer}</b></div>
                <button id="woca_copy" style="background: lime; color: black; font-weight: bold; cursor: pointer; border: none; padding: 5px 10px; border-radius: 5px;">KOPÍROVAT</button>
            </div>
            <div style="font-size: 12px; color: #aaa; margin-bottom: 5px;">Špatně? Oprav:</div>
            <input type="text" id="woca_correct" style="width: 65%; background: #222; color: white; border: 1px solid lime; padding: 3px;" placeholder="Správné slovo...">
            <button id="woca_save" style="width: 30%; background: lime; color: black; cursor: pointer; font-weight: bold; border: none; padding: 4px;">OK</button>
            <hr style="margin: 15px 0; border: 0; border-top: 1px solid #333;">
            <div style="display: flex; justify-content: space-between; gap: 10px;">
                <button id="woca_export" style="flex: 1; background: #444; color: white; cursor: pointer; font-size: 11px; border: 1px solid #666; padding: 3px;">📤 Export</button>
                <button id="woca_import" style="flex: 1; background: #444; color: white; cursor: pointer; font-size: 11px; border: 1px solid #666; padding: 3px;">📥 Import</button>
            </div>
            <div id="woca_import_area" style="display:none; margin-top: 10px;">
                <input type="text" id="woca_import_val" style="width: 80%; background: #222; color: white; border: 1px solid white; font-size: 10px;" placeholder="Vlož kód sem...">
                <button id="woca_do_import" style="width: 15%; background: white; color: black; font-size: 10px; cursor: pointer;">OK</button>
            </div>
            <div style="font-size: 11px; color: #888; text-align: center; margin-top: 10px;">1. Klikni <b>Kopírovat</b> → 2. Klikni do políčka → 3. Stiskni <b style="color: lime;">F2</b></div>
        `;

        document.getElementById('woca_copy').onclick = () => {
            navigator.clipboard.writeText(answer).then(() => {
                const btn = document.getElementById('woca_copy');
                btn.innerText = "Zkopírováno!";
                btn.style.background = "white";
                setTimeout(() => {
                    btn.innerText = "KOPÍROVAT";
                    btn.style.background = "lime";
                }, 1000);
            });
        };

        document.getElementById('woca_save').onclick = () => {
            const correctValue = document.getElementById('woca_correct').value;
            if (correctValue) {
                customDict[question] = correctValue;
                GM_setValue('wocabee_dict', customDict);
                el.innerHTML = `✅ Uloženo!`;
                setTimeout(() => { posledniOtazka = ""; napovezWocabee(); }, 1000);
            }
        };

        document.getElementById('woca_export').onclick = () => {
            const data = JSON.stringify(customDict);
            console.log("--- ZÁLOHA ---", data);
            alert("Záloha byla vypsána do konzole (F12)!");
        };

        document.getElementById('woca_import').onclick = () => {
            document.getElementById('woca_import_area').style.display = 'block';
        };

        document.getElementById('woca_do_import').onclick = () => {
            const importedData = document.getElementById('woca_import_val').value;
            try {
                const parsed = JSON.parse(importedData);
                customDict = parsed;
                GM_setValue('wocabee_dict', customDict);
                alert("✅ Import byl úspěšný!");
                location.reload();
            } catch (e) {
                alert("❌ Chyba: Neplatný kód!");
            }
        };
    }

    setInterval(napovezWocabee, 1000);
    console.log("🚀 Wocabee German Helper (Fixed) aktivován!");
})();
