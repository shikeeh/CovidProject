-- @BLOCK
SELECT *
FROM covidproj.covidvaccinations
ORDER BY 3,
    4;
-- @BLOCK
SELECT *
FROM covidproj.coviddeaths
ORDER BY 3,
    4;
-- @BLOCK
SELECT location,
    date,
    total_cases,
    new_cases,
    total_deaths,
    population
FROM covidproj.coviddeaths
ORDER BY 1,
    2;
-- @BLOCK
--
-- looking at total cases vs total deaths
-- shows likelihood of dying from COVID-19
--
SELECT location,
    date,
    total_cases,
    total_deaths,
    (total_deaths / total_cases) * 100 as DeathPercentage
FROM covidproj.coviddeaths
WHERE location = 'Singapore'
ORDER BY 1,
    2;
-- @BLOCK
--
-- looking at total cases vs population
--
SELECT location,
    date,
    total_cases,
    population,
    (total_cases / population) * 100 as InfectionPercentage
FROM covidproj.coviddeaths
WHERE location like 'Singapore'
ORDER BY 1,
    2;
-- @BLOCK
--
-- looking at countries with highest infection rate compared to population
--
SELECT location,
    population,
    MAX(total_cases) as 'Highest Case Count',
    MAX((total_cases / population)) * 100 as InfectionPercentage
FROM covidproj.coviddeaths
GROUP BY location,
    population
ORDER BY InfectionPercentage desc -- cannot order by name in quotes, eg. 'population' vs population 
;
-- @BLOCK
--
-- showing countries with highest death count per population
--
SELECT location,
    MAX(cast(total_deaths AS UNSIGNED)) as TotalDeathCount -- because we convert text data type into int
FROM covidproj.coviddeaths
WHERE continent <> '' -- " is not NULL " was not accepted, because there were no null values, just empty inputs
GROUP BY location
ORDER BY TotalDeathCount desc;
-- @BLOCK
--
-- breaking things down by continent:
--
SELECT location,
    MAX(convert(total_deaths, UNSIGNED)) as TotalDeathCount -- can try convert instead
FROM covidproj.coviddeaths
WHERE continent = ''
GROUP BY location
ORDER BY TotalDeathCount desc;
-- @BLOCK
--
--
SELECT continent,
    MAX(cast(total_deaths as UNSIGNED)) as TotalDeathCount
FROM covidproj.coviddeaths
WHERE continent <> ''
GROUP BY continent
ORDER BY TotalDeathCount desc -- somehow this returns diff values than the above block. when i select continent instead of location
;
-- @BLOCK
--
-- Global Numbers
--
SELECT SUM(new_cases) as total_cases,
    SUM(new_deaths) as total_deaths,
    SUM(new_deaths) / SUM(new_cases) * 100 as DeathPercentage
FROM covidproj.coviddeaths
WHERE continent <> ''
ORDER BY 1,
    2;
-- @BLOCK
--
-- Looking into the vaccinations csv file
-- this query will combine the two csv files, matching them according to date
--
SELECT *
FROM coviddeaths dea
    JOIN covidvaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date;
-- @BLOCK
--
-- looking at total population vs vaccinations
--
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location,
            dea.date
    ) as RollingPplVaxed -- this creates a rolling count
FROM coviddeaths dea
    JOIN covidvaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> ''
ORDER BY 2,
    3;
-- @BLOCK
--
-- using a common table expression
--
WITH PopvsVac (
    continent,
    location,
    date,
    population,
    new_vaccinations,
    RollingPplVaxed
) as (
    SELECT dea.continent,
        dea.location,
        dea.date,
        dea.population,
        vac.new_vaccinations,
        SUM(vac.new_vaccinations) OVER (
            PARTITION BY dea.location
            ORDER BY dea.location,
                dea.date
        ) as RollingPplVaxed -- this creates a rolling count
    FROM coviddeaths dea
        JOIN covidvaccinations vac ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent <> ''
)
SELECT *,
    (RollingPplVaxed / Population) * 100
FROM PopvsVac
ORDER BY 2,
    3;
-- @BLOCK
DROP TABLE IF EXISTS PercentPopVaxed;
-- @BLOCK
--
-- creating a temporary table
-- 
CREATE TABLE PercentPopVaxed (
    continent varchar(255),
    location varchar(255),
    date DATE,
    population INT,
    new_vaccinations VARCHAR(255),
    RollingPplVaxed INT
);
-- @BLOCK
-- CREATE TABLE table_name () AS SELECT .... also works in a single query, as compared to this
--
INSERT INTO PercentPopVaxed
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location,
            dea.date
    ) as RollingPplVaxed
FROM coviddeaths dea
    JOIN covidvaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '';
-- @BLOCK
SELECT *,
    (RollingPplVaxed / Population) * 100
FROM PercentPopVaxed;
-- @BLOCK
-- 
-- Creating view to store data for later viz
-- 
CREATE VIEW PercentPopVaxed as
SELECT dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(vac.new_vaccinations) OVER (
        PARTITION BY dea.location
        ORDER BY dea.location,
            dea.date
    ) as RollingPplVaxed
FROM coviddeaths dea
    JOIN covidvaccinations vac ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent <> '';