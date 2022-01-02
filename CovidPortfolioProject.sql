--Covid-19 Deaths & Covid-19 Vaccinations
--Data ranges from Feburary 15,2020 to December 28, 2021
--Source: ourwordindata.org/covid-deaths

--Looking at ALL data from CovidDeaths table
Select *
From CovidPortfolioProject..CovidDeaths
Where continent is not null
Order by 3,4

--Looking at ALL data from CovidVaccinations table
Select *
From CovidPortfolioProject..CovidVaccinations
Where continent is not null
Order by 3,4

--Selecting data that will be used for queries below
Select Location, date, total_cases, new_cases, total_deaths, population
From CovidPortfolioProject..CovidDeaths
Order by 1,2

--Looking at Total Cases vs Total Deaths
--Output shows likelihood of dying if you contract Covid-19. This calculation is displayed under DeathPercentage column.
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Order by 1,2


--Looking at Total Cases vs Total Deaths
--Output shows likelihood of dying if you contract Covid-19 in United States
Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Where location like '%states%'
Order by 1,2


--Looking at Total Cases vs Population
--Output shows what percentage of population who contracted Covid-19 in United States. This calculation is displayed under PercentPopulationInfected column.
Select Location, date, Population, total_cases, (total_cases/Population)*100 as PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
Where location like '%states%'
Order by 1,2


--Looking at Countries with Highest Infection Rate compared to Population
--Output shows the locations with the maximum total cases displayed under HighestInfectedCount and calculates the percentage of population that is infected. 
Select Location, Population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
Group by Location, population
Order by PercentPopulationInfected desc


--Looking at Countries with Lowest Infection Rate compared to Population
--Output shows the locations with the lowest total cases displayed under LowestInfectedCount and calculates the percentage of population that is infected. 
Select Location, Population, MIN(total_cases) as LowestInfectionCount, MIN((total_cases/population))*100 as PercentPopulationInfected
From CovidPortfolioProject..CovidDeaths
Group by Location, population
Order by PercentPopulationInfected desc


--Showing Countries with Highest Death Count per Population
--Output shows the locations(Countries) from highest to lowest of total deaths and displays them under the TotalDeathCount column.
Select Location, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolioProject..CovidDeaths
Where continent is not null
Group by Location
Order by TotalDeathCount desc


--Showing the Continent with the Highest Death Count per Population
--Output shows the continents from highest to lowest of death count and displays them under the TotalDeathCount column. 
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolioProject..CovidDeaths
Where continent is not null
Group by continent
Order by TotalDeathCount desc


-- Global Death Percentage Rate of Total Cases and Total Deaths 
--Output displays the sum of New Cases shown under TotalCases column, the sum of New Deaths shown under TotalDeaths column and the death percentage displayed under DeathPercentage column.
Select date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, SUM(cast(new_deaths as int))/SUM(new_cases)*100 as DeathPercentage
From CovidPortfolioProject..CovidDeaths
Where continent is not null
Group by date
Order by 1,2


--Joining CovidDeaths and CovidVaccinations tables together on Location and Date
--The alias shorthand dea has been created for CovidDeaths table and vac for CovidVaccinations table
Select *
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


--Looking at Total Population in the CovidDeaths table vs Vaccinations in CovidVaccinations table 
--Output displays the new vaccinations per population ordered by Location & Date
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
From CovidPortfolioProject..CovidDeaths dea --
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Order by 2,3


--Looking at rolling count of New Vaccinations per Day by partitioning Location so that the rolling count is computed for each location and not all together. The partition is the ordered by location and date. 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
Order by 2,3


--Total Population vs Total People Vaccinated Per Location (Using CTE & Temp Table)

--Using CTE
--Output shows VaccinatedPercentage by diving RollingPeopleVaccinated by population then multiplying by 100
With PopVsVac (continent, location, date, population, new_vaccinations, rollingpeoplevaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
)
Select *, (RollingPeopleVaccinated/population)*100 as VaccinatedPercentage
From PopVsVac


--Using Temp Table
--Output shows VaccinatedPercentage by diving RollingPeopleVaccinated by population then multiplying by 100
Drop Table if exists #PercentPopulationVaccinated 
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
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint,vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null

Select *, (RollingPeopleVaccinated/Population)*100 as PercentPopulationVaccinated
From #PercentPopulationVaccinated

--Creating View to store data for later visualiztions
Drop View If Exists DeathCount
Create View DeathCount as
Select continent, MAX(cast(total_deaths as int)) as TotalDeathCount
From CovidPortfolioProject..CovidDeaths
Where continent is not null
Group by continent


Drop View If Exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as 
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition by dea.location Order by dea.location, dea.date) as RollingPeopleVaccinated
From CovidPortfolioProject..CovidDeaths dea
Join CovidPortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
