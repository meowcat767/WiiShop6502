C:\cc65\bin\ca65.exe .\music.s -o .\music.o
if ($LASTEXITCODE -ne 0) { throw "Assembly failed. Do not link." }

C:\cc65\bin\ld65.exe -C .\nes.cfg .\music.o -o .\WiiShop.nes
if ($LASTEXITCODE -ne 0) { throw "Linking failed." }
