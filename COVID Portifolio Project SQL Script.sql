create database ProjectPortifolio
use ProjectPortifolio 



select * from CovidDeaths where continent is not null
select * from CovidVaccinations

-- Select our target data we are interested in

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
where continent is not null
order by 1,2

-- Change the Data Type of column total_deaths from nvarchar to float
ALTER TABLE CovidDeaths
ALTER COLUMN total_deaths float;
-- Change the Data Type of column total_cases from nvarchar to float
ALTER TABLE CovidDeaths
ALTER COLUMN total_cases float;

-- Looking at total_deaths Vs total_cases
-- Likelihood of dying if you contract COVID in African countries
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
from ProjectPortifolio..CovidDeaths
where location LIKE '%africa%' and continent is not null
order by 5 desc

-- Looking at total cases Vs Population
-- Shows that what percentage of population got Covid
select location, date, total_cases, total_deaths, (total_cases/population)*100 as PopulationInfectedPercentage
from ProjectPortifolio..CovidDeaths
where location LIKE '%africa%' and continent is not null
order by 5 desc


-- Looking at Countries with hughest infection rate compared to population

select location,population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PopulationInfectedPercentage
from ProjectPortifolio..CovidDeaths
where continent is not null
Group by location,population
order by PopulationInfectedPercentage desc

-- Showing the country with Highest Death count compared to population

select location, MAX(total_deaths) as HighestDeathCount
from ProjectPortifolio..CovidDeaths
where continent is not null
Group by location
order by HighestDeathCount desc

-- showing as per continent

select continent, MAX(total_deaths) as HighestDeathCount
from ProjectPortifolio..CovidDeaths
where continent is not null
Group by continent
order by HighestDeathCount desc

-- Global Numbers

select sum(new_cases) as Total_cases, SUM(total_deaths) as Total_deaths,
SUM(CAST(new_deaths as float))/SUM(new_cases)*100 as DeathPercentage
from ProjectPortifolio..CovidDeaths
where continent is not null
--Group by date
order by 1,2

-- Join the two table together on location and date 

select * 
from ProjectPortifolio..CovidDeaths dea
join ProjectPortifolio..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date

-- Looking totall population Vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from ProjectPortifolio..CovidDeaths dea
join ProjectPortifolio..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Rolling up Vaccinated people per location and date

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
from ProjectPortifolio..CovidDeaths dea
join ProjectPortifolio..CovidVaccinations vac
on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
order by 2,3

-- Using CTE to calculate number of vaccinated as per the population

WITH PopVsVac (continent,location,date,population,new_vaccinations,RollingPeopleVaccinated)
as
(
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	from ProjectPortifolio..CovidDeaths dea
	join ProjectPortifolio..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
	where dea.continent is not null
)
Select *,  (RollingPeopleVaccinated/population)*100
from PopVsVac

-- Using TEMP table
DROP Table if exists #PercentVaccinatedPopulation
create table #PercentVaccinatedPopulation
(
	continent nvarchar(255),
	location nvarchar(255),
	date datetime,
	population numeric,
	new_vaccinations numeric,
	RollingPeopleVaccinated numeric
)
insert into #PercentVaccinatedPopulation
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	from ProjectPortifolio..CovidDeaths dea
	join ProjectPortifolio..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
	where dea.continent is not null
Select *,  (RollingPeopleVaccinated/population)*100
from #PercentVaccinatedPopulation

-- Creating Views for later Visualization

create view PercentVaccinatedPopulation as
	select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(float, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as RollingPeopleVaccinated
	from ProjectPortifolio..CovidDeaths dea
	join ProjectPortifolio..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date
	where dea.continent is not null

select * from PercentVaccinatedPopulation