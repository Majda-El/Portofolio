Select * FROM CovidDeaths where continent is not null order by location,date;
--Select Data that we are going to be starting with
Select Location, date, total_cases, new_cases, total_deaths, population From CovidDeaths Where continent is not null order by location,date;
-- Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country
SELECT Location,date,total_cases,total_deaths,ROUND(CAST(total_deaths AS FLOAT) / CAST(total_cases AS FLOAT) * 100, 2) AS DeathPercentage FROM CovidDeaths WHERE continent IS NOT NULL ORDER BY location, date;
--Death Rate by Continent
SELECT dea.continent,ROUND(SUM(CAST(dea.total_deaths AS INT)) * 100.0 / SUM(dea.population), 2) AS DeathRate FROM CovidDeaths dea WHERE dea.continent IS NOT NULL GROUP BY dea.continent ORDER BY DeathRate DESC;
-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases, round(CAST(total_cases as FLOAT)/CAST (population as FLOAT)*100,2) as PercentPopulationInfected From CovidDeaths order by location,date;
-- Countries with Highest Infection Rate compared to Population
Select Location, Population, MAX(total_cases) as HighestInfectionCount,round(MAX((CAST(total_cases AS FLOAT)/CAST (population as FLOAT))*100,2)) as PercentPopulationInfected From CovidDeaths Group by Location, Population order by PercentPopulationInfected desc;
-- Countries with Highest Death Count per Population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount From CovidDeaths Where continent is not null Group by Location order by TotalDeathCount desc;
-- BREAKING RESULTS DOWN BY CONTINENT
-- Showing contintents with the highest death count per population
Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount From CovidDeaths Where continent is not null Group by continent order by TotalDeathCount desc;
-- GLOBAL NUMBERS
SELECT SUM(new_cases) AS TotalCases,SUM(CAST(new_deaths AS INT)) AS TotalDeaths,CASE WHEN SUM(new_cases) = 0 THEN 0 ELSE ROUND(SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100, 2) END AS DeathPercentage FROM CovidDeaths WHERE continent IS NOT NULL;
--Top 10 countries by total death 
SELECT location,MAX(CAST(total_deaths AS INT)) AS TotalDeaths FROM CovidDeaths WHERE continent IS NOT NULL GROUP BY location ORDER BY TotalDeaths DESc LIMIT 10;
--Global Trends for Cases and Deaths
SELECT date,SUM(CAST(new_cases AS INT)) AS DailyCases, SUM(CAST(new_deaths AS INT)) AS DailyDeaths FROM CovidDeaths WHERE continent IS NOT NULL GROUP BY date ORDER BY date;
--vaccination rate for each location
SELECT dea.location,dea.population,COALESCE(MAX(CAST(vac.people_vaccinated AS INT)), 0) AS TotalVaccinated, ROUND(COALESCE(MAX(CAST(vac.people_vaccinated AS INT)), 0) * 100.0 / NULLIF(dea.population, 0), 2) AS VaccinationRate FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac ON dea.location = vac.location and dea.date=vac.date GROUP BY dea.location, dea.population ORDER BY VaccinationRate DESC;
--Average Daily Deaths Per Country
SELECT dea.location, AVG(CAST(dea.total_deaths AS INT)) AS AverageDeaths FROM CovidDeaths dea GROUP BY dea.location ORDER BY AverageDeaths DESC;
--Top 5 Countries with the Fastest Vaccination Rate
SELECT dea.location,ROUND(COALESCE(SUM(CAST(vac.new_vaccinations AS INT)), 0) * 100.0 / dea.population, 2) AS VaccinationRate FROM CovidDeaths dea LEFT JOIN CovidVaccinations vac ON dea.location = vac.location GROUP BY dea.location, dea.population ORDER BY VaccinationRate DESC LIMIT 5;
--Cumulative Deaths Over Time
SELECT dea.location,dea.date,SUM(CAST(dea.total_deaths AS INT)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS CumulativeDeaths FROM CovidDeaths dea ORDER BY dea.location, dea.date;
--Correlation Between New Cases and New Deaths
SELECT dea.location,SUM(CAST(dea.new_cases AS INT)) AS TotalNewCases,SUM(CAST(dea.new_deaths AS INT)) AS TotalNewDeaths FROM CovidDeaths dea GROUP BY dea.location ORDER BY TotalNewCases DESC;

