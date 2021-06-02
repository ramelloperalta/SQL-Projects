use [COVID19-SQL-Project]

Select * 
from covid_deaths
order by 3, 4


Select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths
order by 1,2

-- case-mortality rate
-- case mortality is the proportion of people dying from total reported covid cases
-- ie. as of the most recent data, 2021-05-24, if you are infected with covid you have a 1.84% chance of death. 
Select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 3) as case_mortality
from covid_deaths
order by 1,2

-- case-mortality rate in Canada
Select location, date, total_cases, total_deaths, round((total_deaths/total_cases)*100, 3) as case_mortality
From covid_deaths
Where location = 'Canada'
Order by 1,2

-- Total Cases vs Population
-- Shows what percentage of population infected with Covid
Select Location, date, Population, total_cases, (total_cases/population)*100 as percent_infected
From covid_deaths
Where location = 'Canada'
Order by 1,2


-- highest rate of infection in Canada
Select Location, Population, MAX(total_cases) as max_total_cases,  Max((total_cases/population))*100 as percent_infected
From covid_deaths
Where location = 'Canada'
Group by location, population
order by percent_infected desc


-- highest deaths in each location
Select Location, MAX(Total_deaths) as highest_deaths
From covid_deaths as a
Where continent is not null 
Group by Location
order by highest_deaths desc



-- highest deaths per continent
Select location, max(total_deaths) as a
From covid_deaths
Where continent is null 
Group by location
order by a desc
-- or 
Select continent, sum(highest_deaths) as b from
(Select continent, Location, MAX(Total_deaths) as highest_deaths
From covid_deaths as a
Where continent is not null 
Group by continent, Location) as c
group by continent
order by b desc


--global death and cases
Select SUM(new_cases) as total_cases, SUM(new_deaths) as total_deaths, SUM(new_deaths)/SUM(New_Cases)*100 as death_percent
From covid_deaths
where continent is not null 
order by 1,2


Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(CONVERT(int,v.new_vaccinations)) OVER (Partition by d.Location Order by d.location, d.Date) as cumvacc
From covid_deaths d
Join covid_vaccines v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
order by 2,3

--Creating a View for vaccinations
Create View rollingpfv as
With pvv (Continent, Location, Date, Population, New_Vaccinations, cumvacc, People_fully_vaccinated)
as
(
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as cumvacc, people_fully_vaccinated
From covid_deaths d
Join covid_vaccines v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
)
Select *, round((People_fully_vaccinated/population)*100, 3) as percent_vaccinated
From pvv

--rolling number for vaccines
Select * from rollingpfv

--highest vaccinated locations 
Select Continent, Location, MAX(percent_vaccinated) as pv
from rollingpfv
group by Continent, location
order by pv desc
-- the numbers are correct; maybe people are coming into gibraltar from other places to get vaccinated?
select * from rollingpfv where location = 'Gibraltar' and date = '2021-05-22'

-- vaccination percentage per continent
-- there is a large vaccine disparity between continents
Select Continent, SUM(pop) as total_population, SUM(max_pfv) as people_vaccinated, SUM(max_pfv)/SUM(pop)*100 as percentvaccinated 
from
(Select Continent, location, max(population) as pop, max(people_fully_vaccinated) as max_pfv
From rollingpfv
group by continent, location) as a
group by continent
order by percentvaccinated desc

--creating a table for vaccinations
DROP Table if exists #percent_pop_vaccinated
Create Table #percent_pop_vaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
cumvacc numeric,
people_fully_vaccinated numeric
)

Insert into #percent_pop_vaccinated
Select d.continent, d.location, d.date, d.population, v.new_vaccinations
, SUM(v.new_vaccinations) OVER (Partition by d.Location Order by d.location, d.Date) as cumvacc, people_fully_vaccinated
From covid_deaths d
Join covid_vaccines v
	On d.location = v.location
	and d.date = v.date
where d.continent is not null 
order by 2,3

Select *, ROUND((people_fully_vaccinated/Population)*100,3) as percent_vacc
From #percent_pop_vaccinated

