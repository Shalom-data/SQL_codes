--EXPLORING THE COVID DATASET USING DATA FROM JANUARY 2020 TO APRIL 2021


select *
from covidDeaths
where continent is not null
order by 3,4


--LET'S SELECT THE NEEDED COLUMNS
SELECT location,date,total_cases,new_cases,total_deaths,population
FROM CovidDeaths
order by 1,2,5

--WE are looking at 219 distinct locations
SELECT COUNT(DISTINCT location)
FROM CovidDeaths

--let's look at total cases vs total deaths in Nigeria
--the first death in Nigeria was recorded on 23rd March 2020
--Nigeria recorded a death rate of 1.25%(2061) by 30/4/2021
SELECT location,
		date,
		total_cases,
		total_deaths,
		ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float)*100),2) AS DeathPercentage
FROM CovidDeaths
where location like '%Nigeria' and continent is not null
order by 1,2

--lets looking at total cases vs total deaths in the united states
--the first 7 cases were recorded on the 26/01/2020 and by 01/03/2020 there were 73 total cases and 1 death recorded
--The UNited States recorded a death rate of 1.8%(571,084) by 30/4/2021
SELECT location,
		date,
		total_cases,
		total_deaths,
		ROUND((CAST(total_deaths AS float)/CAST(total_cases AS float)*100),2) AS DeathPercentage
FROM covid_deaths
where location like '%states' and continent is not null
order by 1,2

--we are working with data from Jan 2020 to April 2021
select location,
		min(date) as min_date,
		max(date) as max_date
from CovidDeaths
group by location
--INFECTION RATE IN NIGERIA AND UNITED STATES
--lets look at population vs total cases, to show the percentage of population that has got covid in Nigeria and united states
--Nigeria had a population of _206,139,587_ and by the end of 2020 0.04% of the population was infected,by April 30 2021
--0.08% of the population were infected. while in the US with a populaiton of 331,002,647 6.07% of the population were infected
--by the end of 2020 and 9.77% by the end of April 2021
SELECT location,
		date,
		population,
		total_cases,
		ROUND((CAST(total_cases AS float)/CAST(population AS float)*100),2) AS Percentageinfected
FROM CovidDeaths
where location IN ('Nigeria','United States')
		and continent is not null
order by 1,2

--what countries has the highest infection rate compared to the population
--Andorra had the highest infection rate of 17.13% with respect to population, followed by Montenegro(15.51%) and Czechia(15.23%)
SELECT location,
		population,
		MAX(total_cases) AS Infection_count,
		MAX(ROUND((CAST(total_cases AS float)/CAST(population AS float)*100),2)) AS Infection_rate
FROM CovidDeaths
WHERE continent is not null
group by location,population 
order by Infection_rate desc

--COUNTRY WITH HIGHEST DEATH COUNT
--which countries has the highest death count per population, THE US has the highest death count of 576,232
SELECT location
		,MAX(CAST(total_deaths AS INT)) as Highest_death_count
FROM CovidDeaths
where continent is not null
group by location
ORDER BY Highest_death_count DESC

--CONTINENT WITH HIGHEST DEATH COUNT
--lets break things down by continent, showing continents with highest death counts per population
--North America has the highest death count of 576,232.
SELECT continent
		,MAX(CAST(total_deaths AS INT)) as Highest_death_count
FROM CovidDeaths
where continent is not null
group by continent
order by Highest_death_count desc


--PERIODS WITH HIGHEST DEATH RATE
--death rate was very high between february and april 2020 with february seeing the highest death rate(29.52%) from covid
SELECT date,
		SUM(new_cases) AS Total_cases,
		SUM(cast(new_deaths as int)) AS Total_deaths,
		ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) AS Global_Death_Percentage
FROM CovidDeaths
WHERE new_cases <> 0 and new_deaths <> 0 --handle divide by zero error
		and continent is not null
GROUP BY date
order by 4 DESC

--TOTAL GLOBAL DEATHS
--Total global death rate was 2.13% with total deaths of 10,227,068
SELECT	SUM(new_cases) AS Total_cases,
		SUM(cast(new_deaths as int)) AS Total_deaths,
		ROUND(SUM(cast(new_deaths as int))/SUM(new_cases)*100,2) AS Global_Death_Percentage
FROM CovidDeaths
WHERE new_cases <> 0 and new_deaths <> 0 --handle divide by zero error
		--and continent is not null
order by 1,2,3

--LOOKING AT TOTAL POPULATION VS VACCINATIONS.here we join the two tables
select *
from CovidDeaths d
join CovidVaccinations v
on d.location = v.location
and d.date = v.date



--LET'S CALCULATE THE CUMULATIVE SUM OF NEW VACCINATIONS PER LOCATION

CREATE INDEX idx_deaths ON CovidDeaths(location,date)
CREATE INDEX idx_vacs ON CovidVaccinations(location,date) --INDEXING TO OPTIMIZE QUERY PERFORMANCE
SELECT d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(Cast(v.new_vaccinations as bigint)) OVER (
		PARTITION BY d.location 
		ORDER BY d.location,d.date) as RollupPeopleVaccinated
FROM CovidDeaths as d
JOIN covidVaccinations as v
ON d.location = v.location
AND d.date= v.date
WHERE d.continent IS NOT NULL ---and d.location IN ('Gibraltar','Israel','United Arab Emirates')
ORDER BY 2,3


--NOW WE WANT TO FIND THE MAXIMUM PERCENTAGE OF PEOPLE VACCINATED PER LOCATION, this will require us to use the column 
--"RollupPeopleVaccinated" but we can't use a derived column on the same query from which it was derived. 
--so we need to create a TEMP TABLE.


DROP TABLE IF EXISTS #Percentage_vaccinated
CREATE TABLE #Percentage_vaccinated(
continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
cumulation_people_vaccinated numeric
)

INSERT INTO #Percentage_vaccinated
SELECT d.continent,
		d.location,
		d.date,
		d.population,
		v.new_vaccinations,
		SUM(Cast(v.new_vaccinations as bigint)) OVER (
		PARTITION BY d.location 
		ORDER BY d.location,d.date) as RollupPeopleVaccinated
FROM CovidDeaths as d
JOIN covidVaccinations as v
ON d.location = v.location
AND d.date= v.date
WHERE d.continent IS NOT NULL

SELECT location,MAX(cumulation_people_vaccinated/population)*100 AS max_vac
FROM #Percentage_vaccinated
group by location
order by MAX(cumulation_people_vaccinated/population)*100 DESC

--The above code gives on insight on the country with the highest vaccination rate which is "Gibraltar" with 182% of population vaccinated,
--followed by Israel with vaccination rate of 121%.


--I checked to see why the vaccination rates of these 2 countries were more than 100%, and here we can see the reason.
--they running total of people vaccinted was way more than the population, this could be attributed to input errors/political factors.

SELECT *
FROM #Percentage_vaccinated
WHERE location IN ('Gibraltar','Israel')


