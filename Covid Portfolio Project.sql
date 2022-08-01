select * from [Portfolio Project].dbo.CovidDeaths
order by 3,4 /*to check that we have what we are looking for*/

--select * from [Portfolio Project].dbo.CovidVaccinations
--order by 3,4

--Select Data that we are going to be using

select location,  date, total_cases, New_cases, total_deaths, population
from [Portfolio Project]..CovidDeaths
order by 1,2

-- looking at TotalCases V. TotalDeaths

select location,  date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage /*row 28 shows a decimal at the end, need to multiply by 100 to get percentage*/
from [Portfolio Project]..CovidDeaths
where location like '%canada%'
order by 1,2
/* this query shows that by April 30th 2021, Canada had a total case amount of 1.2m with 1.9% chance of death*/

-- TotalCases V. Population
-- population percentage w/ Covid

select location,  date, population, total_cases, (total_cases/population)*100 as InfectionPercentage 
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
order by 1,2

--Countries with highest infection rate compared to population

select location, population, MAX(total_cases) as InfectionCount, MAX((total_cases/population))*100 as InfectionPercentage /*MAX allows for us to see the highest infection count*/
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
group by location, population /* we need a group by because we have an aggragate function in our select */
order by InfectionPercentage desc /*we want to see the highest infection count, so we order by InfectionPercentage */

--Countries with highest death count per population

select location, MAX(total_deaths) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
group by location
order by TotalDeathCount desc 
/* after executing this specific code, we see that the first result is = Austria TotalDeathCount= 9997 , whereas France is 5th and shows = 99936. The issue comes from the data type, so we need to convert the data type for total_deaths using CAST*/


select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
group by location
order by TotalDeathCount desc
/* this code shows the 1st option as World with TotalDeathCount of 3180238, but it is showing Continents as the location instead of specific countries */


select location, MAX(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
where continent is not null /* after checking the data, we see that some of the data has some continents set to NULL */
group by location
order by TotalDeathCount desc
/*United States now shows #1 with a TotalDeathCount of 576,232 */




-- The following code will use continent instead of location
select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
from [Portfolio Project]..CovidDeaths
--where location like '%canada%'
where continent is not null 
group by continent
order by TotalDeathCount desc


-- Now we join the 2 tables we have for Total Population V. Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
, (RollingPeopleVaccinated/population)*100
from [Portfolio Project]..CovidDeaths dea /* dea as nickname */
join [Portfolio Project]..CovidVaccinations vac /*vac as nickname */
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
order by 2,3


-- Invalid column name 'RollingPeopleVaccinated' , in order to fix this we will use CTE

with PopvsVac (continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, 
SUM(convert(int,vac.new_vaccinations)) OVER (Partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
from [Portfolio Project]..CovidDeaths dea /* dea as nickname */
join [Portfolio Project]..CovidVaccinations vac /*vac as nickname */
ON dea.location = vac.location
and dea.date = vac.date
where dea.continent is not null
--order by 2,3
)
select *, (RollingPeopleVaccinated/population)*100
from PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

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
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From [Portfolio Project]..CovidDeaths dea
Join [Portfolio Project]..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
