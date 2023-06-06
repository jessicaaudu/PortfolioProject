/*
Covid 19 Data Exploration 
Dataset timeframe : 03/01/2020 - 31/05/2023
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- To view the content of the covidDeaths dataset
SELECT *
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL
ORDER BY 3,4

-- To view the content of the covidVaccination dataset
SELECT *
FROM `sanmarino-382917.Portfolio_project.covidVaccinations`
WHERE continent IS NOT NULL
ORDER BY 3,4

--To select data that we are going to be starting with

SELECT Location, 
  date, 
  total_cases, 
  new_cases, 
  total_deaths, 
  population
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL
ORDER BY 1,2

-- Total Cases vs Total Deaths
-- To show likelihood of dying if you contract covid in your country

SELECT Location, 
  date, 
  total_cases,
  total_deaths, 
  (total_deaths/total_cases)*100 as DeathPercentage
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent is not null 
ORDER BY 1,2

--To show likelihood of dying if you contract covid in your country (record at the end of each year and as at 31/05/2023)

SELECT Location, 
  date, 
  total_cases,
  total_deaths, 
  (total_deaths/total_cases)*100 as DeathPercentage
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent is not null
  AND total_cases > 0 AND total_deaths > 0
  AND date = "2020-12-31" OR date = "2021-12-31" OR date ="2022-12-31" OR date ="2023-05-31"
  -- AND Location like ='Nigeria'
ORDER BY 1,5 DESC 

-- Total Cases vs Population
-- To show what percentage of population infected with Covid

SELECT Location, 
  date, 
  Population, 
  total_cases,  
  (total_cases/population)*100 AS PercentPopulationInfected
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE total_cases > 0
 -- AND Location  ='Nigeria'
ORDER BY 1,2 DESC

-- To show countries with Highest Infection Rate compared to Population

SELECT Location, 
  Population, 
  MAX(total_cases) AS HighestInfectionCount,  
  MAX((total_cases/population))*100 AS PercentPopulationInfected
FROM PortfolioProject..CovidDeaths
--WHERE Location = 'Nigeria'
GROUP BY Location, Population
ORDER BY PercentPopulationInfected DESC

--To show infection rate grouped per year
SELECT location, 
  EXTRACT(YEAR FROM date) AS year, 
  MAX(total_cases) AS highest_infection_count,
MAX((total_cases / population) * 100) AS percent_population_infected
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE total_cases > 0
GROUP BY location, population, year
ORDER BY location, percent_population_infected DESC;


-- To show countries with Highest Death Count per Population
SELECT Location, 
  MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL 
--AND Location ='Nigeria'
GROUP BY Location
ORDER BY TotalDeathCount DESC

-- To show death count per year
SELECT Location,
  EXTRACT(YEAR FROM date) AS year, 
  MAX(cast(Total_deaths AS int)) AS TotalDeathCount
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL
--AND Location ='Nigeria'
GROUP BY Location,year
ORDER BY TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT
-- Showing continents with the highest death count per population
SELECT continent, 
  MAX(CAST(Total_deaths AS int)) AS TotalDeathCount
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC


-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS total_cases, 
  SUM(CAST(new_deaths AS int)) AS total_deaths, 
  SUM(CAST(new_deaths AS int))/SUM(New_Cases)*100 AS DeathPercentage
FROM `sanmarino-382917.Portfolio_project.covidDeaths`
WHERE continent IS NOT NULL
--AND Location = 'Nigeria'
ORDER BY 1,2

-- To show how excess mortality has evolved over time and during different waves of the pandemic
SELECT CONCAT(EXTRACT(MONTH FROM date), '-', EXTRACT(YEAR FROM date)) AS month_year, 
  MAX(excess_mortality) AS excess_mortality_per_month
FROM `sanmarino-382917.Portfolio_project.covidVaccinations`
WHERE excess_mortality IS NOT NULL
GROUP BY month_year
ORDER BY excess_mortality_per_month 

-- Total Population vs Vaccinations
SELECT d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS int)) OVER (Partition by d.Location Order by d.location, d.date) as RollingPeopleVaccinated
FROM `sanmarino-382917.Portfolio_project.covidDeaths` AS d
JOIN `sanmarino-382917.Portfolio_project.covidVaccinations` AS v
  ON d.location = v.location
  AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY 2,3

-- To show Percentage of Population that has recieved at least one Covid Vaccine using Temp Table to perform Calculation on Partition
DROP TABLE IF EXISTS `Portfolio_project.PopulationVaccinated`;
CREATE TABLE `Portfolio_project.PopulationVaccinated` (
  Continent STRING,
  Location STRING,
  Date DATE,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated NUMERIC
);

INSERT INTO `Portfolio_project.PopulationVaccinated`
SELECT
  d.continent,
  d.location,
  d.date,
  d.population,
  v.new_vaccinations,
  SUM(CAST(v.new_vaccinations AS INT64)) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS RollingPeopleVaccinated
FROM
  `sanmarino-382917.Portfolio_project.covidDeaths` AS d
JOIN
  `sanmarino-382917.Portfolio_project.covidVaccinations` AS v
  ON d.location = v.location
  AND d.date = v.date;


SELECT
  Location,
  MAX(RollingPeopleVaccinated / Population) * 100 AS percent_population_vaccinated
FROM
  `Portfolio_project.PopulationVaccinated`
WHERE RollingPeopleVaccinated IS NOT NULL
GROUP BY Location
ORDER BY percent_population_vaccinated

-- Creating View to store data for later visualizations
CREATE VIEW Portfolio_project.PercentagePopulationVaccinated AS
SELECT d.continent, 
  d.location, 
  d.date, 
  d.population, 
  v.new_vaccinations, 
  SUM(CAST(v.new_vaccinations AS int64)) OVER (Partition by d.Location Order by d.location, d.Date) AS RollingPeopleVaccinated
FROM `sanmarino-382917.Portfolio_project.covidDeaths` AS d
JOIN `sanmarino-382917.Portfolio_project.covidVaccinations` AS v
  ON d.location = v.location
  AND d.date = v.date
WHERE d.continent IS NOT NULL


CREATE VIEW Portfolio_project.excessMortalityProgression AS
SELECT CONCAT(EXTRACT(MONTH FROM date), '-', 
  EXTRACT(YEAR FROM date)) AS month_year, 
  MAX(excess_mortality) AS excess_mortality_per_month
FROM `sanmarino-382917.Portfolio_project.covidVaccinations`
WHERE excess_mortality IS NOT NULL
GROUP BY month_year
ORDER BY excess_mortality_per_month ;
