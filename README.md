# Linux for Data Scientists 23-24 - take-home scriptingopdracht

`task.sh` is een script dat een Linux gebruiker helpt bij het bijhouden van een todo-lijstje.

Het bijgevoegde bestand `task-start.sh` bevat startcode met een basisstructuur met een aantal voorgedefinieerde functies waar je mee kan beginnen. 

- [x] **Hernoem het naar `task.sh`.**

## :purple_heart: Hulp opvragen

- [x] Als je `help` opgeeft, drukt het script een hulpboodschap af 
- [x] en sluit meteen af met exit-status 0. 
- [x] Gebruik hiervoor een Here Document!
- [x] updaten nu er nieuwe functionality is

## :purple_heart: Algemene requirements

- [x] Zorg dat je naam en emailadres vermeld zijn op de voorziene plaats in de commentaar bovenaan het script!
- [x] Gebruik shell-opties om de robuustheid van het script te verhogen (bv. behandelen van onbestaande variabelen).
- [x] Gebruik ShellCheck om fouten te voorkomen!
- [x] Gebruik `stdout` exclusief voor het afdrukken van informatie uit het takenbestand: taakbeschrijvingen, contexten, labels, enz. Foutboodschappen, waarschuwingen, enz. worden afgedrukt op `stderr`.
- [x] Vermijd "hard-coded" waarden in de code, gebruik zoveel mogelijk variabelen!
- [x] Het script wordt altijd opgeroepen met als eerste argument een commando. Als dit niet het geval is, wordt verondersteld dat de gebruiker `help` bedoelde.

### :purple_heart: Minimale requirements voor inhoudelijke beoordeling

- [x] Het resultaat van zowel 
  - [x] `bash -n task.sh` als 
  - [x] `shellcheck --severity=error task.sh` moet succesvol zijn (dus zonder fouten).
- [x] Het script mag geen DOS regeleindes (CRLF) hebben, anders kan Bash het niet interpreteren
- [x] Het script moet een geldige "shebang" hebben op de eerste regel
- [x] Als we het script uitvoeren met optie `help`, dan moet dit lukken (we krijgen dus de Usage: boodschap te zien en de exit-status is 0)

- [x] gebruik maakt van het aangeleverde sjabloon en de daarin gedefinieerde functies implementeert. 
- [x] Je mag uiteraard wel extra functies toevoegen als je dat nuttig vindt.

## :purple_heart: Instellingen

- [x] Instellingen die de gebruiker kan aanpassen worden opgeslagen in een configuratiebestand `~/.taskrc`. 
- [x] De instellingen worden ingelezen met `source` en zijn dus Bash-syntax.

- [x] Als het bestand niet gevonden wordt, wordt het aangemaakt met standaardwaarden.

- [x] task_file en task_editor zijn mogelijk in te stellen via settings

| Instelling    | Standaardwaarde                                        |
| :------------ | :----------------------------------------------------- |
| `TASK_FILE`   | Bestand `.tasks` in de home-directory van de gebruiker |
| `TASK_EDITOR` | Absoluut pad naar `nano`                               |


## :purple_heart: Taak toevoegen

- [x] Met `add` kan je een nieuwe taak toevoegen. 
  - [x] Elke taak krijgt een ID, een geheel getal beginnend bij 1 (zie verder). 
  - [x] Na toevoegen van de taak wordt deze ID afgedrukt. 
  - [x] De taak wordt toegevoegd aan het einde van het taakbestand. 
  - [x] Aan het begin van de lijn komt het ID, gevolgd door een TAB-karakter en vervolgens de taakbeschrijving zelf.

### Extra functionality
- [x] controleer correct formaat als er datum is bijgevoegd

- [x] Als je geen taakbeschrijving opgeeft, stopt het script met een geschikte foutmelding en exit-status.

- [x] Het script bevat een functie `get_next_task_id` die de laagst mogelijke ID-waarde teruggeeft die nog niet in gebruik is. Deze wordt bepaald door in het takenbestand te zoeken naar reeds gebruikte IDs, beginnend met 1, vervolgens 2, enz. totdat een vrij ID gevonden wordt. Deze wordt dan toegekend aan de nieuwe taak.

In de beschrijving van een taak *kan* je volgende elementen gebruiken:

- [x] Een deadline, in de vorm van `jjjj-mm-dd` (wordt gecheckt)
- [x] Een "context", in de vorm van `@context`. Hiermee bedoelen we de plaats waar de taak kan uitgevoerd worden (bv. `@home`, `@campus`, `@phone`, ...).
- [x] Een "tag", in de vorm van `#tag`. Dit kan de naam van een project zijn, een trefwoord, prioriteitcode, ... Meerdere tags zijn mogelijk. Let op! Omdat Bash het `#`-teken speciaal behandelt (commentaar), moet je dit op de CLI escapen met een `\`-teken of de taakbeschrijving tussen aanhalingstekens zetten.

## :purple_heart: Alle taken afdrukken

- [x] Met `dump` druk je de inhoud van het takenbestand af.

## :purple_heart: Taakbestand bewerken

- [x] Soms wil je wijzigingen aanbrengen aan een taak. Dit kan met `edit`. Het script opent het takenbestand in de teksteditor die in de instelling `TASK_EDITOR` staat.


## :purple_heart: Overzicht contexten

- [x] Met `list-contexts` druk je een alfabetisch gesorteerd overzicht af van alle contexten die in het takenbestand voorkomen, met voor elk het aantal taken. Dit zijn woorden die beginnen met een `@`-teken.

## :purple_heart: Overzicht tags

- [x] Met `list-tags` druk je een gesorteerd overzicht af van alle tags die in de taken voorkomen. Dit zijn woorden die beginnen met een `#`-teken. Let er op dat als een taakbeschrijving meerdere tags bevat, alle tags ook in de lijst voorkomen.

## :purple_heart: Taken zoeken

- [x] Met `search` kan je zoeken naar taken die een bepaald (regex) tekstpatroon bevatten. Het script drukt alle taken af die voldoen aan het patroon, samen met hun ID.

## :purple_heart: Verlopen taken

- [x] Met `overdue` toon je een lijst van taken met een deadline die verstreken is.

## :purple_heart: Taak als afgerond markeren

- [x] Met `done` kan je een taak als afgerond markeren. 
  - [x] Dit doe je door het ID van de taak op te geven. 
  - [x] Het script toont de taak en vraagt bevestiging. 
  - [x] Als de gebruiker antwoordt met 'y', wordt de taak uit het taakbestand verwijderd, 
  - [x] zo niet blijft de taak ongewijzigd.

  - [x] Als de gebruiker geen ID opgeeft, of de ID komt niet voor in het takenbestand, stopt het script met een geschikte foutmelding en exit-status.

## :white_heart: Extra functionality
### :purple_heart: Settings file moet nodige values hebben
- [x] wanneer settings file niet compleet is met nodige values, vul het aan
### :purple_heart: Settings kunnen bewerken via script
- [x] mogelijkheid om settings aan te passen door task.sh edit-settings op te roepen
- [x] mogelijkheid om huidige settings te bekijken door task.sh list-settings op te roepen 
- [x] Checken of .tasks effectief juiste data bevat mbv `ensure_task_file()`
- [ ] List logs met variabele N last logs mbv `list_logs()`