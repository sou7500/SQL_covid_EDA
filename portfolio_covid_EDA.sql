create database portfolio_covid_EDA -- Database created
-- Tables have been created for each excel file containing information about the Deaths and Vaccinations.
-- lets confirm if everything is working fine and then we will start.
select * 
from portfolio_covid_EDA.dbo.CovidDeaths
order by 3,4;

select * 
from portfolio_covid_EDA.dbo.CovidVaccinations
order by 3,4;
-- Both tables responding good, lets start the EDA now.

-- Lets check total cases, total deaths and death ratio trend in india.
-- Shows likelihood of dying if you contract covid in India.
select Location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_ratio
from portfolio_covid_EDA.dbo.CovidDeaths
where location like '%india%';

-- Looking at total cases Vs Population.
-- calculating infection ratio in india( shows chances of getting infected in india over time)
select Location, date, total_cases, population, (total_cases/population)*100 as Infection_ratio
from portfolio_covid_EDA.dbo.CovidDeaths
where location like '%india%'
order by 1,2;  -- so by 13th April 2021, 1% of total population was infected in India.



--  Lets see which countries have the highest infection rate compared to population.

select Location, population, max(total_cases) as highest_infection,Max((total_cases/population))*100 as Infection_ratio
from portfolio_covid_EDA.dbo.CovidDeaths
group by Location, population
order by Infection_ratio desc; -- Andorra a small country with less population has the highest infection ratio.
-- United States tops in comaprison to population among all.

-- Lets find countries with highest death count.

select Location, Max(cast(total_deaths as int)) as Total_deaths
from portfolio_covid_EDA.dbo.CovidDeaths
group by Location
order by Total_deaths desc;
-- This result contains Total deaths in terms of Continent
--Looking up on Excel file we can see that the data is presented as continent in location column 
--where continent has no value, thus we need to
-- filter the data where continent is not null.

select continent, Max(cast(total_deaths as int)) as Total_deaths
from portfolio_covid_EDA.dbo.CovidDeaths
where continent is not null
group by continent
order by Total_deaths desc;

-- GLOBAL NUMBERS for cases and deaths

select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as
DeathPercentage
from portfolio_covid_EDA.dbo.CovidDeaths
where continent is not null
group by date
order by 1;

-- Total number of cases, deaths and death percentage globally.
select sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, (sum(cast(new_deaths as int))/sum(new_cases))*100 as
DeathPercentage
from portfolio_covid_EDA.dbo.CovidDeaths
where continent is not null;
--group by date
--order by 1;

-- LETS FIND  TOTAL POPULATION Vs TOTAL VACCINATION.
-- FIRST LETS JOIN TWO TABLES ON LOCATION AND DATE TO MATCH THEM EXACTLY.
Select *
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date

-- Now lets find total population Vs total vaccination.

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date
where dea.continent is not null
--and dea.location = 'India'  -- filtering further for India.
order by 2,3


-- Lets check the moving sum of vaccination by location and date.

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as Moving_sum_vacccination
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date
where dea.continent is not null
order by 2,3

-- CALCULATING MOVING TOTAL VACCINATED OVER POLULATION METRICS.
-- FORT THAT WE NEED TO CREATE A CTE FOR (sum(convert(int,vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as Moving_sum_vacccination)

--CTE
WITH populationVsvac(continent, location, date, population, new_vaccinations,Moving_sum_vacccination)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as Moving_sum_vacccination
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date
where dea.continent is not null
)
select*, (Moving_sum_vacccination/population)*100 as Moving_vac
from populationvsvac


-- Lets save this result subset into a new temp table.
drop table if exists #percentagepeoplevaccinated
create table #percentagepeoplevaccinated
(
continent varchar(200),
location varchar(200),
date datetime,
population numeric,
new_vaccinations numeric,
Moving_sum_vaccination numeric
)

insert into #percentagepeoplevaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as Moving_sum_vaccination
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date

select*, (Moving_sum_vaccination/population)*100 as Moving_vac
from #percentagepeoplevaccinated



--Creating a view for practice to keep the queries in separate view.

create view population_vaccinated
as 
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(convert(int,vac.new_vaccinations)) over(partition by dea.location order by dea.location, dea.date) as Moving_sum_vacccination
from portfolio_covid_EDA..CovidDeaths dea
join portfolio_covid_EDA..CovidVaccinations vac
on dea.location= vac.location and
dea.date= vac.date
where dea.continent is not null







