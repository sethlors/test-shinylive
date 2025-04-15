# Ergast Database User Guide

## List of Tables

- [circuits](#circuits-table)
- [constructorResults](#constructorresults-table)
- [constructorStandings](#constructorstandings-table)
- [constructors](#constructors-table)
- [driverStandings](#driverstandings-table)
- [drivers](#drivers-table)
- [lapTimes](#laptimes-table)
- [pitStops](#pitstops-table)
- [qualifying](#qualifying-table)
- [races](#races-table)
- [results](#results-table)
- [seasons](#seasons-table)
- [status](#status-table)

## General Notes

- Dates, times and durations are in ISO 8601 format
- Dates and times are UTC
- Strings use UTF-8 encoding
- Primary keys are for internal use only
- Fields ending with "Ref" are unique identifiers for external use
- A grid position of '0' is used for starting from the pitlane
- Labels used in the positionText fields:
    - "D" - disqualified
    - "E" - excluded
    - "F" - failed to qualify
    - "N" - not classified
    - "R" - retired
    - "W" - withdrew

## circuits table

**circuits.csv**

| Field      | Type         | Null | Key | Default | Extra          | Description               |
|------------|--------------|------|-----|---------|----------------|---------------------------|
| circuitId  | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key               |
| circuitRef | varchar(255) | NO   |     |         |                | Unique circuit identifier |
| name       | varchar(255) | NO   |     |         |                | Circuit name              |
| location   | varchar(255) | YES  |     | NULL    |                | Location name             |
| country    | varchar(255) | YES  |     | NULL    |                | Country name              |
| lat        | float        | YES  |     | NULL    |                | Latitude                  |
| lng        | float        | YES  |     | NULL    |                | Longitude                 |
| alt        | int(11)      | YES  |     | NULL    |                | Altitude (metres)         |
| url        | varchar(255) | NO   | UNI |         |                | Circuit Wikipedia page    |

## constructorResults table

**constructor_results.csv**

| Field                | Type         | Null | Key | Default | Extra          | Description                            |
|----------------------|--------------|------|-----|---------|----------------|----------------------------------------|
| constructorResultsId | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                            |
| raceId               | int(11)      | NO   |     | 0       |                | Foreign key link to races table        |
| constructorId        | int(11)      | NO   |     | 0       |                | Foreign key link to constructors table |
| points               | float        | YES  |     | NULL    |                | Constructor points for race            |
| status               | varchar(255) | YES  |     | NULL    |                | "D" for disqualified (or null)         |

## constructorStandings table

**constructor_standings.csv**

| Field                  | Type         | Null | Key | Default | Extra          | Description                              |
|------------------------|--------------|------|-----|---------|----------------|------------------------------------------|
| constructorStandingsId | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                              |
| raceId                 | int(11)      | NO   |     | 0       |                | Foreign key link to races table          |
| constructorId          | int(11)      | NO   |     | 0       |                | Foreign key link to constructors table   |
| points                 | float        | NO   |     | 0       |                | Constructor points for season            |
| position               | int(11)      | YES  |     | NULL    |                | Constructor standings position (integer) |
| positionText           | varchar(255) | YES  |     | NULL    |                | Constructor standings position (string)  |
| wins                   | int(11)      | NO   |     | 0       |                | Season win count                         |

## constructors table

**constructors.csv**

| Field          | Type         | Null | Key | Default | Extra          | Description                   |
|----------------|--------------|------|-----|---------|----------------|-------------------------------|
| constructorId  | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                   |
| constructorRef | varchar(255) | NO   |     |         |                | Unique constructor identifier |
| name           | varchar(255) | NO   | UNI |         |                | Constructor name              |
| nationality    | varchar(255) | YES  |     | NULL    |                | Constructor nationality       |
| url            | varchar(255) | NO   |     |         |                | Constructor Wikipedia page    |

## driverStandings table

**driver_standings.csv**

| Field             | Type         | Null | Key | Default | Extra          | Description                         |
|-------------------|--------------|------|-----|---------|----------------|-------------------------------------|
| driverStandingsId | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                         |
| raceId            | int(11)      | NO   |     | 0       |                | Foreign key link to races table     |
| driverId          | int(11)      | NO   |     | 0       |                | Foreign key link to drivers table   |
| points            | float        | NO   |     | 0       |                | Driver points for season            |
| position          | int(11)      | YES  |     | NULL    |                | Driver standings position (integer) |
| positionText      | varchar(255) | YES  |     | NULL    |                | Driver standings position (string)  |
| wins              | int(11)      | NO   |     | 0       |                | Season win count                    |

## drivers table

**drivers.csv**

| Field       | Type         | Null | Key | Default | Extra          | Description              |
|-------------|--------------|------|-----|---------|----------------|--------------------------|
| driverId    | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key              |
| driverRef   | varchar(255) | NO   |     |         |                | Unique driver identifier |
| number      | int(11)      | YES  |     | NULL    |                | Permanent driver number  |
| code        | varchar(3)   | YES  |     | NULL    |                | Driver code e.g. "ALO"   |     
| forename    | varchar(255) | NO   |     |         |                | Driver forename          |
| surname     | varchar(255) | NO   |     |         |                | Driver surname           |
| dob         | date         | YES  |     | NULL    |                | Driver date of birth     |
| nationality | varchar(255) | YES  |     | NULL    |                | Driver nationality       |
| url         | varchar(255) | NO   | UNI |         |                | Driver Wikipedia page    |

## lapTimes table

**lap_times.csv**

| Field        | Type         | Null | Key | Default | Extra | Description                       |
|--------------|--------------|------|-----|---------|-------|-----------------------------------|
| raceId       | int(11)      | NO   | PRI | NULL    |       | Foreign key link to races table   |
| driverId     | int(11)      | NO   | PRI | NULL    |       | Foreign key link to drivers table |
| lap          | int(11)      | NO   | PRI | NULL    |       | Lap number                        |
| position     | int(11)      | YES  |     | NULL    |       | Driver race position              |
| time         | varchar(255) | YES  |     | NULL    |       | Lap time e.g. "1:43.762"          |
| milliseconds | int(11)      | YES  |     | NULL    |       | Lap time in milliseconds          |

## pitStops table

**pit_stops.csv**

| Field        | Type         | Null | Key | Default | Extra | Description                       |
|--------------|--------------|------|-----|---------|-------|-----------------------------------|
| raceId       | int(11)      | NO   | PRI | NULL    |       | Foreign key link to races table   |
| driverId     | int(11)      | NO   | PRI | NULL    |       | Foreign key link to drivers table |
| stop         | int(11)      | NO   | PRI | NULL    |       | Stop number                       |
| lap          | int(11)      | NO   |     | NULL    |       | Lap number                        |
| time         | time         | NO   |     | NULL    |       | Time of stop e.g. "13:52:25"      |
| duration     | varchar(255) | YES  |     | NULL    |       | Duration of stop e.g. "21.783"    |
| milliseconds | int(11)      | YES  |     | NULL    |       | Duration of stop in milliseconds  |

## qualifying table

**qualifying.csv**

| Field         | Type         | Null | Key | Default | Extra          | Description                            |
|---------------|--------------|------|-----|---------|----------------|----------------------------------------|
| qualifyId     | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                            |
| raceId        | int(11)      | NO   |     | 0       |                | Foreign key link to races table        |
| driverId      | int(11)      | NO   |     | 0       |                | Foreign key link to drivers table      |
| constructorId | int(11)      | NO   |     | 0       |                | Foreign key link to constructors table |
| position      | int(11)      | YES  |     | NULL    |                | Grid position                          |
| q1            | varchar(255) | YES  |     | NULL    |                | Q1 time                                |
| q2            | varchar(255) | YES  |     | NULL    |                | Q2 time                                |
| q3            | varchar(255) | YES  |     | NULL    |                | Q3 time                                |
| time          | varchar(255) | YES  |     | NULL    |                | Qualifying time                        |
| milliseconds  | int(11)      | YES  |     | NULL    |                | Qualifying time in milliseconds        |

## races table

**races.csv**

| Field    | Type         | Null | Key | Default | Extra          | Description          |
|----------|--------------|------|-----|---------|----------------|----------------------|
| raceId   | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key          |
| season   | varchar(255) | NO   |     |         |                | Season (e.g. "2015") |
| round    | int(11)      | NO   |     | NULL    |                | Round number         |
| raceName | varchar(255) | NO   |     |         |                | Race name            |
| date     | date         | NO   |     | NULL    |                | Race date            |
| time     | time         | YES  |     | NULL    |                | Race time (UTC)      |
| url      | varchar(255) | NO   |     |         |                | Race Wikipedia page  |

## results table

**results.csv**

| Field         | Type         | Null | Key | Default | Extra          | Description                            |
|---------------|--------------|------|-----|---------|----------------|----------------------------------------|
| resultId      | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                            |
| raceId        | int(11)      | NO   |     | 0       |                | Foreign key link to races table        |
| driverId      | int(11)      | NO   |     | 0       |                | Foreign key link to drivers table      |
| constructorId | int(11)      | NO   |     | 0       |                | Foreign key link to constructors table |
| grid          | int(11)      | NO   |     | 0       |                | Grid position                          |
| position      | int(11)      | NO   |     | 0       |                | Race position                          |
| positionText  | varchar(255) | YES  |     | NULL    |                | Race position (text)                   |
| points        | float        | YES  |     | NULL    |                | Points for race                        |
| laps          | int(11)      | NO   |     | 0       |                | Number of laps completed               |
| time          | varchar(255) | YES  |     | NULL    |                | Race time                              |
| milliseconds  | int(11)      | YES  |     | NULL    |                | Race time in milliseconds              |
| statusId      | int(11)      | YES  |     | NULL    |                | Status id link to status table         |

## seasons table

**seasons.csv**

| Field  | Type         | Null | Key | Default | Extra | Description           |
|--------|--------------|------|-----|---------|-------|-----------------------|
| season | varchar(255) | NO   | PRI | NULL    |       | Season (e.g. "2015")  |
| url    | varchar(255) | NO   |     |         |       | Season Wikipedia page |

## status table

**status.csv**

| Field    | Type         | Null | Key | Default | Extra          | Description                     |
|----------|--------------|------|-----|---------|----------------|---------------------------------|
| statusId | int(11)      | NO   | PRI | NULL    | auto_increment | Primary key                     |
| status   | varchar(255) | NO   |     |         |                | Finishing status e.g. "Retired" |

## stints table

**stints.csv**

| Field         | Type         | Null | Key | Default | Extra | Description                                        |
|---------------|--------------|------|-----|---------|-------|----------------------------------------------------|
| lap           | int(11)      | NO   |     | NULL    |       | Lap number of the stint                            |
| sector1Time   | time         | YES  |     | NULL    |       | Time taken in sector 1                             |
| sector2Time   | time         | YES  |     | NULL    |       | Time taken in sector 2                             |
| sector3Time   | time         | YES  |     | NULL    |       | Time taken in sector 3                             |
| tireCompound  | varchar(255) | YES  |     | NULL    |       | Tire compound used for the stint                   |
| tyreLife      | int(11)      | YES  |     | NULL    |       | Number of laps completed on the current tire set   |
| freshTyre     | boolean      | NO   |     | NULL    |       | Whether the tire was new at the start of the stint |
| driverId      | int(11)      | NO   | MUL | NULL    |       | Foreign key referencing the driver                 |
| constructorId | int(11)      | NO   | MUL | NULL    |       | Foreign key referencing the constructor            |
| raceId        | int(11)      | NO   | MUL | NULL    |       | Foreign key referencing the race                   |