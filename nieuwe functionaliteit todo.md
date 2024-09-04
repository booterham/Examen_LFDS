# Algemene richtlijnen

## CR-01 Commando's mogen niet hoofdlettergevoelig zijn

- [x] met sed aanpakken?
- [ ] kan veel mooier met switch, als ik tijd overheb

## CR-02 .task-archive bestand

- [x] .task-archive in de home-dir van de gebruiker als standaard waarde settings file

## CR-03: Deadline is verplicht voor elke taak.

- [x] Een deadline, in de vorm van jjjj-mm-dd.

## CR-04: Je kan geen twee keer dezelfde taak toevoegen

- [x] een taak met een volledig identieke beschrijving als een bestaande taak. In dit geval toon je een gepaste foutboodschap

## CR-05: Taak als afgerond markeren

- [x] Met done kan je een taak als afgerond markeren. Dit doe je door het ID van de taak op te geven
- [x] Het script toont de taak en vraagt bevestiging. CR-05:
  - [x] Als de gebruiker antwoordt met 'y', wordt de taak uit het taakbestand verwijderd en verplaatst naar het task-archive in de home-directory van de gebruiker
  - [x] zo niet blijft de taak ongewijzigd.
- [x] Bij het archiveren van taken wordt het ID van de taak verwijderd, de rest van de omschrijving blijft ongewijzigd.

## (CR-06) De contexten worden weergegeven volgens dalende hoeveelheid taken.

- [x] list-contexts aanpassen

## (CR-07) De tags worden weergegeven volgens dalende hoeveelheid taken.

- [x] list-tags aanpassen

## Uitstellen

- [ ] (CR-08) Met postpone kan je de deadline van een bepaalde taak uitstellen.
    - [ ] Je geeft een taaknummer mee, samen met het aantal dagen waarmee de deadline opgeschoven moet worden.
    - [ ] Als je geen termijn meegeeft, wordt de deadline standaard met 7 dagen opgeschoven.

### andere

- [ ] functies die geen argumenten mogen nemen moeten error throwen
