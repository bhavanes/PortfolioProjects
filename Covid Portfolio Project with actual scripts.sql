Select *
From PortfolioProject.. [Covid Deaths]
Where continent is not null 
Order by 3,4

--Select *
--From PortfolioProject..[Covid Vaccinations]
--Order by 3,4


Select location, date, total_cases, total_deaths, 
(CONVERT(float, total_deaths)/Nullif(CONVERT(float,total_cases),0))*100 AS death_percentage
From PortfolioProject ..[Covid Deaths] 
Where location like '%India%'
Where continent is not null 



--Total cases v/s Population

Select location, date, total_cases,population, 
(CONVERT(float, total_deaths)/Nullif(CONVERT(float,population),0))*100 AS PercentPopulationInfected
From PortfolioProject ..[Covid Deaths] 
Where continent is not null 
--Where location like 'India'



--Countries with highest infection rate

Select location, population,MAX(total_cases) AS HighestInfectionCount, 
MAX((CONVERT(float, total_cases)/Nullif(CONVERT(float,population),0)))*100 AS PercentPopulationInfected
From PortfolioProject ..[Covid Deaths] 
Where continent is not null 
Group by Location, population
Order by PercentPopulationInfected desc



-- Countries with highest death count per population

Select location, MAX(Convert(float,total_deaths)) AS TotalDeathCount
From PortfolioProject ..[Covid Deaths] 
Where continent is not null 
Group by Location
Order by TotalDeathCount desc


--By continent

Select continent, SUM(Convert(float,new_deaths)) AS TotalDeathCount
From PortfolioProject ..[Covid Deaths] 
Where COALESCE(continent, '') <>''
Group by continent
Order by TotalDeathCount desc


--Global Numbers

Select SUM(CONVERT(float,new_cases)) as total_cases, SUM(CONVERT(float, new_deaths)) as total_deaths,
SUM(CONVERT(float, new_deaths))/SUM(CONVERT(float,new_cases))*100 as DeathPercentage
From PortfolioProject..[Covid Deaths]
where continent is not null



--Total Population vs Vaccinations 

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) AS RollingPeopleVaccinated
--, RollingPeopleVaccinated/Population)*100
From PortfolioProject..[Covid Deaths] dea
	Join PortfolioProject..[Covid Vaccinations] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null

--Use CTE

;With Popsvac (Continent,location,Date, Population,New_Vaccinations, RollingPeopleVaccinated)
As
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(float,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location,dea.date) AS RollingPeopleVaccinated
--, RollingPeopleVaccinated/Population)*100
From PortfolioProject..[Covid Deaths] dea
	Join PortfolioProject..[Covid Vaccinations] vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, 
CASE
When RollingPeopleVaccinated = 0 then NULL
Else (RollingPeopleVaccinated/Population)*100
END
From Popsvac


--TEMP TABLE 

DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC(18,2),
    New_vaccinations NUMERIC(18,2),
    RollingPeopleVaccinated NUMERIC(18,2)
);

INSERT INTO #PercentPopulationVaccinated
SELECT 
    dea.continent, 
    dea.location, 
    TRY_CAST(dea.date AS DATETIME) AS Date,  
    TRY_CAST(dea.population AS FLOAT) AS Population,
    TRY_CAST(vac.new_vaccinations AS FLOAT) AS New_vaccinations,
    SUM(TRY_CAST(vac.new_vaccinations AS FLOAT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_CAST(dea.date AS DATETIME)) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..[Covid Deaths] dea
JOIN 
    PortfolioProject..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
    AND TRY_CAST(dea.date AS DATETIME) IS NOT NULL
    AND TRY_CAST(vac.date AS DATETIME) IS NOT NULL;

-- Final output
SELECT *, 
    CASE 
        WHEN Population IS NULL OR Population = 0 THEN NULL
        ELSE (RollingPeopleVaccinated / Population) * 100
    END AS PercentPopulationVaccinated
FROM 
    #PercentPopulationVaccinated;	



--Creating View to store data for later visualization

IF OBJECT_ID('PercentPopulationVaccinated', 'V') IS NOT NULL
    DROP VIEW PercentPopulationVaccinated

GO

CREATE VIEW PercentPopulationVaccinated AS
	SELECT 
    dea.continent, 
    dea.location, 
    TRY_CAST(dea.date AS DATETIME) AS Date,  
    TRY_CAST(dea.population AS FLOAT) AS Population,
    TRY_CAST(vac.new_vaccinations AS FLOAT) AS New_vaccinations,
    SUM(TRY_CAST(vac.new_vaccinations AS FLOAT)) 
        OVER (PARTITION BY dea.location ORDER BY dea.location, TRY_CAST(dea.date AS DATETIME)) AS RollingPeopleVaccinated
FROM 
    PortfolioProject..[Covid Deaths] dea
JOIN 
    PortfolioProject..[Covid Vaccinations] vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE 
    dea.continent IS NOT NULL
    AND TRY_CAST(dea.date AS DATETIME) IS NOT NULL
    AND TRY_CAST(vac.date AS DATETIME) IS NOT NULL;

SELECT TOP 10 * 
FROM PercentPopulationVaccinated;

SELECT TOP 10 * FROM PercentPopulationVaccinated;



SELECT * FROM PercentPopulationVaccinated;
