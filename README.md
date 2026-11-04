# Chrome Setup

Een kleine installer voor Google Chrome op Debian/Ubuntu en ChromeOS Linux (Crostini).

## Installeren

1. Vervang `JE-GITHUBNAAM` in `bootstrap.sh` en `config/config.sh` door jouw GitHub-gebruikersnaam.
2. Zet in de repository een bestand `allowlist.txt`. Dit bestand bevat één apparaat-ID per regel.
3. Upload de map naar GitHub.
4. Installeer met één commando (vervang de GitHub-gebruikersnaam):

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/JE-GITHUBNAAM/chrome-setup/main/bootstrap.sh)
```

Bekijk `bootstrap.sh` eerst voordat je het uitvoert; het downloadt de rest van de repository en start de installer.

De installer toont daarna het apparaat-ID. Voeg dat ID als een losse regel toe aan `allowlist.txt` en commit/push het bestand. Start daarna Chrome via de desktop-snelkoppeling **Chrome** of met:

```bash
~/.local/bin/chrome-managed
```

## Wat wordt geïnstalleerd?

- Google Chrome Stable via Google's officiële Debian-repository.
- uBlock Origin Lite via Chrome's ExtensionInstallForcelist-policy.
- Een eigen lokale startpagina (`homepage/index.html`), ingesteld als Chrome-startpagina en opstartpagina.
- Een gebruikersservice die de allowlist iedere 15 minuten controleert.
- Bij een ontbrekende toestemming of mislukte HTTPS-controle sluit de service Chrome af.
- Een desktop-snelkoppeling die eerst de allowlist controleert.

## Let op: beveiligingsgrenzen

Dit project is een eenvoudige beheer-/toegangscontrole, geen DRM of waterdichte apparaatbeveiliging. Een gebruiker met volledige toegang tot zijn eigen Linux-account kan de wrapper, timer of scripts aanpassen of Chrome rechtstreeks starten via `/usr/bin/google-chrome`. Gebruik dit niet om andermans apparaat zonder toestemming te beheren. Voor echte afdwinging is een beheerd besturingssysteem of een organisatiebrede device-management-oplossing nodig.

De gekozen fail-closed instelling betekent dat Chrome wordt afgesloten wanneer de server niet bereikbaar is. Zorg dus dat de allowlist-host betrouwbaar is. Gebruik alleen een HTTPS-URL en bewaar geen gevoelige persoonsgegevens in de TXT-file.

## Startpagina

De installer stelt de lokale pagina in als Chrome-startpagina en als pagina die bij het opstarten wordt geopend. De Chrome New Tab-pagina wordt niet vervangen; dat vereist een aparte extensie.

## Extensie

Chrome krijgt de officiële uBlock Origin Lite-extensie geforceerd aangeboden via Chrome Enterprise policy. Dit is de Manifest V3-versie voor moderne Chrome; de klassieke uBlock Origin-extensie is niet compatibel met huidige Chrome-versies.

## Uitschakelen / verwijderen

```bash
systemctl --user disable --now chrome-device-check.timer
rm -f ~/.config/systemd/user/chrome-device-check.timer
rm -f ~/.config/systemd/user/chrome-device-check.service
systemctl --user daemon-reload
rm -rf ~/.local/share/chrome-setup ~/.config/chrome-setup
rm -f ~/.local/bin/chrome-managed
rm -f ~/.local/share/applications/"Chrome Setup.desktop"
sudo rm -f /etc/opt/chrome/policies/managed/chrome-setup.json
```

Verwijderen van Chrome zelf kan met `sudo apt remove google-chrome-stable`.
