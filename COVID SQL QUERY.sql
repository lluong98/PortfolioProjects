SELECT *
FROM PortfolioProject..CovidDeaths
ORDER BY 3,4

--SELECT *
--FROM PortfolioProject..CovidVaccinations
--ORDER BY 3,4

--Select data that we're going to be using

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2

--Looking at Total Cases vs Total Deaths
--Shows likelihood of dying if you contract Covid in your country

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS DeathPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--AND location = 'United States'
ORDER BY 1,2

--Looking at Total Cases vs Population
--Shows what percentage of population got Covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS HasCovidPercentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--AND location = 'United States'
ORDER BY 1,2

--Looking at Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) AS Highest_InfCount, MAX((total_cases/population))*100 AS 
	Highest_HasCovidPerc
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--AND location = 'United States'
GROUP BY location, population
ORDER BY Highest_HasCovidPerc DESC

--Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
--AND location = 'United States'
GROUP BY location
ORDER BY TotalDeathCount DESC

--SELECT location, MAX(total_deaths) AS TotalDeathCount
--FROM PortfolioProject..CovidDeaths
----WHERE location = 'United States'
--GROUP BY location
--ORDER BY TotalDeathCount DESC    \\This doesn't work because of the datatype and how it's read when using an aggregrate function.

--Breaking Things Down by Continent

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount_ByContinent
FROM PortfolioProject..CovidDeaths
WHERE NOT (location LIKE '%income%' OR location LIKE '%international%' OR location LIKE '%world%') 
	AND continent is null
GROUP BY location
ORDER BY TotalDeathCount_ByContinent DESC

--Breaking Things Down by Income

SELECT location, MAX(cast(total_deaths as int)) AS TotalDeathCount_ByIncome
FROM PortfolioProject..CovidDeaths
WHERE location like '%income%' ANd continent is null
GROUP BY location
ORDER BY TotalDeathCount_ByIncome DESC


--Showing continents with highest death count per population

SELECT continent, MAX(cast(total_deaths as int)) AS TotalDeathCount_ByContinent
FROM PortfolioProject..CovidDeaths
WHERE location NOT LIKE '%income%' AND continent is not null
GROUP BY continent
ORDER BY TotalDeathCount_ByContinent DESC

--GLOBAL NUMBERS 

SELECT date, SUM(new_cases) AS total_global_cases, SUM(cast(new_deaths as int)) AS total_global_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentGlobal
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

SELECT SUM(new_cases) AS total_global_cases, SUM(cast(new_deaths as int)) AS total_global_deaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 AS DeathPercentGlobal
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY 1,2


--Looking at Total Population vs Vaccinations
--USING CTE
WITH PopvsVac(Continent, Location, Date, Population, New_vaccinations, Rolling_Ppl_Vaccinated)
AS 
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Ppl_Vaccinated
	--(Rolling_Ppl_Vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3
)
SELECT *, (Rolling_Ppl_Vaccinated/Population)*100
FROM PopvsVac

--USING TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255), Location nvarchar(255), Date datetime, Population numeric, New_vaccinations numeric, Rolling_Ppl_Vaccinated numeric)
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Ppl_Vaccinated
	--(Rolling_Ppl_Vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3

SELECT *, (Rolling_Ppl_Vaccinated/Population)*100
FROM #PercentPopulationVaccinated


--Death Rates in Comparison to Before and After Release of COVID-19 Vaccine.


SELECT CONVERT(date,dea.date) AS Date,  (dea.total_deaths/dea.total_cases)*100 AS DeathPercentage, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Ppl_Vaccinated
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
--WHERE vac.people_vaccinated is not NULL



--Creating view to store data for later visualizations

CREATE VIEW PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location ORDER BY dea.location, dea.date) as Rolling_Ppl_Vaccinated
	--(Rolling_Ppl_Vaccinated/population)*100
FROM PortfolioProject..CovidDeaths dea
JOIN PortfolioProject..CovidVaccinations vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 2,3