--
-- these are the queries we will use for the Tableau Project
-- @BLOCK
--
-- 1. 
--
SELECT SUM(new_cases) as total_cases,
    SUM(cast(new_deaths as UNSIGNED)) as total_deaths,
    SUM(convert(new_deaths, UNSIGNED)) / SUM(new_cases) * 100 as DeathPercentage
FROM coviddeaths
WHERE continent <> ''
ORDER BY 1,
    2;
-- @BLOCK
-- 
-- 2.
-- 
SELECT location,
    SUM(convert(new_deaths, UNSIGNED)) as TotalDeathCount
FROM coviddeaths
WHERE continent = ''
    and location not in ('World', 'European Union', 'International')
GROUP BY location
ORDER BY TotalDeathCount desc;
-- @BLOCK
--
-- 3.
--
SELECT location,
    population,
    MAX(total_cases) as HighestInfectionCount,
    MAX(total_cases / population) * 100 as PercentPopulationInfected
FROM coviddeaths
GROUP BY location,
    population
ORDER BY PercentPopulationInfected desc;
-- @BLOCK 
--
-- 4.
--
SELECT location,
    population,
    date,
    MAX(total_cases) as HighestInfectionCount,
    MAX(total_cases / population) * 100 as PercentPopulationInfected
FROM coviddeaths
GROUP BY location,
    population,
    date
ORDER BY PercentPopulationInfected desc;