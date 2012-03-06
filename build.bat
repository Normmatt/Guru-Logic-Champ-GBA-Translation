copy rom\input.gba rom\output.gba
armips.exe asm/HWF.asm
armips.exe asm/name_entry_screen.asm
armips.exe asm/cutscene_font.asm
font_insert gfx\cutscene_font_eng.gba rom\output.gba

Atlas rom\output.gba script\gurulogic_script_000.txt
Atlas rom\output.gba script\gurulogic_script_001.txt
Atlas rom\output.gba script\gurulogic_script_002.txt
pause