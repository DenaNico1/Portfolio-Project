SELECT * FROM [Portfolio Project].dbo.[CovidDeaths]
Order By 3, 4

--SELECT * FROM [Portfolio Project].dbo.CovidVaccinations
--Order By 3, 4

-- select data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population 
FROM [Portfolio Project].dbo.[CovidDeaths]
Order By 1,2

-- looking at total_cases vs total_deaths

--1 remplaçons les cellules vides par nulles
UPDATE [Portfolio Project].dbo.[CovidDeaths]
SET total_cases = NULL
WHERE total_cases = ''

UPDATE [Portfolio Project].dbo.[CovidDeaths]
SET total_deaths = NULL
WHERE total_deaths = ''

UPDATE [Portfolio Project].dbo.[CovidDeaths]
SET population = NULL
WHERE population = ''

UPDATE [Portfolio Project].dbo.[CovidDeaths]
SET continent = NULL
WHERE continent = ''

UPDATE [Portfolio Project].dbo.CovidVaccinations
SET new_vaccinations = NULL
WHERE new_vaccinations = ''

Select Location, date, total_cases,total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float)) * 100 AS DeathPercentage
From [Portfolio Project].dbo.[CovidDeaths]
order by 1,2

-- 2 une autre approche
Select Location, date, total_cases,total_deaths, 
CASE 
        WHEN total_cases = 0 THEN 0  -- Si le nombre de cas est zéro, le pourcentage de décès est zéro
        ELSE (CAST(total_deaths AS float) / NULLIF(CAST(total_cases AS float), 0)) * 100  -- Évite la division par zéro
END AS DeathPercentage
From [Portfolio Project].dbo.[CovidDeaths]
Where location like '%burkina%'
--and continent is not null 
order by 1,2

-- looking at total_cases vs population
Select Location, date, population, total_cases, (CAST(total_cases AS float)/CAST(population AS float)) * 100 AS PercentPopulationInfected
From [Portfolio Project].dbo.[CovidDeaths]
Where location like '%burkina%'
order by 1,2

-- looking at countries with highest Infection rate population compared to population
Select Location, population, MAX(total_cases) AS HighestInfectionCount, MAX(CAST(total_cases AS float)/CAST(population AS float)) * 100 AS PercentPopulationInfected
From [Portfolio Project].dbo.[CovidDeaths]
Group BY Location, population
--Where location like '%burkina%'
order by PercentPopulationInfected desc

-- showing countries with highest deaths count per population
Select Location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].dbo.[CovidDeaths]
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathCount desc

-- let's break things by continent
Select location, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].dbo.[CovidDeaths]
--Where location like '%states%'
Where continent is null 
Group by location
order by TotalDeathCount desc

-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From [Portfolio Project].dbo.[CovidDeaths]
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null and vac.new_vaccinations is not null 
order by 2,3

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100
From PopvsVac


-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 AS RollingPeopleVaccinatedPopulation
From #PercentPopulationVaccinated

-- Creating View to store data for later visualizations
DROP VIEW PercentPopulationVaccinated;

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project].dbo.CovidDeaths dea
Join [Portfolio Project].dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

