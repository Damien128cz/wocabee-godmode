; --- WOCABEE AUTO-TYPER ---
; Tato funkce spustí psaní, když zmáčkneš F2

F2::
{
    ; Zkontroluje, zda je ve schránce něco napsáno
    if (A_Clipboard != "") {
        ; a) Odstraní případné mezery na začátku a konci
        text := Trim(A_Clipboard)
        
        ; b) "Vyťuká" text ze schránky velmi rychle, ale lidsky
        SendText text
    }
}
