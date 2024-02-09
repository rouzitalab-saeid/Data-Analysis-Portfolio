SELECT name, physical_name AS NewLocation, state_desc AS OnlineStatus
FROM sys.master_files  
WHERE database_id = DB_ID(N'PortfolioProject') 
GO

select * 
from PortfolioProject..CovidDeaths
order by 3,4

select * 
from PortfolioProject..CovidVaccinations
order by 3,4

--Select data that we are going to be using
select Location,date,total_cases,new_cases,total_deaths,population 
from PortfolioProject..CovidDeaths
order by 1,2

--Looking at Totalcases vs TotalDeath
--Shows Likelihood of dying if you contract covid in your country
select Location,date,total_cases,(cast(total_deaths As int)/cast(total_cases As int)*100) as DeathPercentage
from PortfolioProject..CovidDeaths
where Location like '%States%'
order by 1,2

--Looking at TotalCases vs Population
--Shows what percentage of population got Covid

select Location,date,total_cases,Population,(cast(total_cases As int)/Population*100) as DeathPercentage
from PortfolioProject..CovidDeaths
where Location like '%States%'
order by 1,2

--Looking at countries with the highest infection rate compared to population

Select Location,Population,Max(total_cases) As HighestInfectionCount,Max(cast(total_cases As int)/Population*100) as PercentPopulationInfected
From PortfolioProject..CovidDeaths
--Where Location like '%States%'
Group by Location,Population
order by PercentPopulationInfected desc

--Showing countries with Highest Death Count per Population

Select Location,Max(Cast(total_deaths As int)) As TotalDeathCount,Max(cast(total_deaths As int)/Population*100) as PercentPopulationDeaths
From PortfolioProject..CovidDeaths
--Where Location like '%States%'
Where continent is not null -- and location='Iran'
Group by Location
order by TotalDeathCount desc


--LET'S BREAK THINGS DOWN BY CONTINENT

		-- 1)Alex solution
Select location,Max(Cast(total_deaths As int)) As TotalDeathCount
From PortfolioProject..CovidDeaths
--Where Location like '%States%'
Where continent is null 
Group by location
order by TotalDeathCount desc

	-- 2)My solution-The right one as I think
Select continent,Sum(new_deaths) As TotalDeathCount--,(Sum(cast(new_deaths As int))/(Sum(Population) Over (Partition By Location)))*100 as PercentPopulationDeaths
From PortfolioProject..CovidDeaths
Where continent is not null
Group by continent--,population,location
order by TotalDeathCount desc


--Population of each country

Select continent,location,Population
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent,location,population
order by 1

--Population of each continent
--Using subquery for calculation of continents population
Select continent,Sum(population) as population
From 
(
Select continent,location,Population
From PortfolioProject..CovidDeaths
Where continent is not null 
Group by continent,location,population
) as CountriesPopulation
--where continent=CountriesPopulation.continent
Group by continent

-- /Using CTE to determine death percentage in comparison with each continent population
WITH ContinentPopulation AS (
    SELECT continent, SUM(population) AS population
    FROM (
        SELECT continent, location, MAX(Population) AS Population
        FROM PortfolioProject..CovidDeaths
        WHERE continent IS NOT NULL 
        GROUP BY continent, location
    ) AS CountriesPopulation
    GROUP BY continent
)

SELECT CD.continent,
       SUM(CD.new_deaths) AS TotalDeathCount,
       (SUM(CAST(CD.new_deaths AS FLOAT)) / CP.population) * 100 AS PercentPopulationDeaths
FROM PortfolioProject..CovidDeaths CD
JOIN ContinentPopulation CP ON CD.continent = CP.continent
WHERE CD.continent IS NOT NULL
GROUP BY CD.continent, CP.population
ORDER BY TotalDeathCount DESC;

-- Using CTE to determine death percentage in comparison with each continent population/


-- Global Numbers
SELECT 
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths,
    SUM(new_cases) / NULLIF(SUM(new_deaths), 0) AS CaseFatalityRate
FROM 
    PortfolioProject..CovidDeaths;

-- /Global Numbers by using CTE
With GN As
	(
	SELECT 
    SUM(new_cases) AS TotalCases,
    SUM(new_deaths) AS TotalDeaths
FROM 
    PortfolioProject..CovidDeaths
	)

	Select   TotalCases,TotalDeaths, NULLIF(TotalCases / TotalDeaths, 0) AS CaseFatalityRate
	From GN
-- Global Numbers by using CTE/



?

/Looking at Total Population vs Vaccination, should use CTE regarding new created column manipulation

With PopvsVac As
(
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
	)

Select *,RollingPeopleVaccinated/population "vaccinated individuals as a portion of the population" --proportion of the population that has been vaccinated
From PopvsVac

-- Looking at Total Population vs Vaccination, should use CTE regarding new created column manipulation/



-- /Looking at Total Population vs Vaccination, should use Temp Table regarding new created column manipulation

Drop Table If Exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated (Continent nvarchar(255),Location nvarchar(255),Date datetime,Population float,new_vaccinations int,RollingPeopleVaccinated float)
Insert into #PercentPopulationVaccinated

SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
	

Select *,RollingPeopleVaccinated/population "vaccinated individuals as a portion of the population" --proportion of the population that has been vaccinated
From #PercentPopulationVaccinated

-- Looking at Total Population vs Vaccination, should use Temp Table regarding new created column manipulation/





-- /Looking at Total Vaccination in each Country, used Temp Table regarding new created column manipulation

Drop Table If Exists #TotalVaccination
Create Table #TotalVaccination (Continent nvarchar(255),Location nvarchar(255),Population float,RollingPeopleVaccinated float)
Insert into #TotalVaccination
SELECT 
    dea.continent,
    dea.location,
    dea.population,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
	
Select Location,Max(RollingPeopleVaccinated) "Total Vaccination",Population,Round(Max(RollingPeopleVaccinated)/Population*100,2) TotalVaccinationRate, DENSE_RANK() Over(Order By Round(Max(RollingPeopleVaccinated)/Population*100,2) Desc) As VaccinationRanking
From #TotalVaccination
Group by Location,Population
Order By 4 Desc;

-- Looking at Total Vaccination in each Country, used Temp Table regarding new created column manipulation/



--Create View for storing data for later visualisation
Create View PercentPopulationVaccinated As
SELECT 
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.date) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..CovidDeaths dea
JOIN 
    PortfolioProject..CovidVaccinations vac ON dea.location = vac.location AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
