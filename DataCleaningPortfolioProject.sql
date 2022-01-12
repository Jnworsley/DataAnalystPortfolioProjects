/*

Cleaning Data in SQL Queries 

*/

-- Standardize Date Format (Changing SaleDate format to Date instead DateTime format)

/*
Select SaleDate, CONVERT(Date,SaleDate)
From DataCleaningPortfolioProject.dbo.NashvilleHousing

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)
*/

--OR

Alter Table NashvilleHousing
Add SaleDateConverted Date;

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

Select SaleDateConverted, CONVERT(Date,SaleDate)
From DataCleaningPortfolioProject.dbo.NashvilleHousing


-- Populate Property Address Data
-- Some Property Addresses are null. The Parcel ID is unique to each Property Address, so if a Property Address is listed multiple times it will have the same Parcel ID.


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress, b.PropertyAddress) as UpdatedPropertyAddressA
From DataCleaningPortfolioProject.dbo.NashvilleHousing a
JOIN DataCleaningPortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null

Update a
Set PropertyAddress = ISNULL(a.PropertyAddress, b.PropertyAddress)
From DataCleaningPortfolioProject.dbo.NashvilleHousing a
JOIN DataCleaningPortfolioProject.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
Where a.PropertyAddress is null


-- Breaking out Address into Individual Columns (Address, City, State) for Property Address and Owner Address

--PropertyAddressColumn

Select 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN (PropertyAddress)) as PropertyCity
From DataCleaningPortfolioProject..NashvilleHousing

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1)

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Add PropertyCity Nvarchar(255);

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) +1, LEN (PropertyAddress))

--OwnerAdress Column

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2),
PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
From DataCleaningPortfolioProject..NashvilleHousing

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Add OwnerSplitAddress  Nvarchar(255);

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Add OwnerCity Nvarchar(255);

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Add OwnerState Nvarchar(255);

Update DataCleaningPortfolioProject.dbo.NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

--Change Y and No to Yes and No in "Sold as Vacant" field

Select Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From DataCleaningPortfolioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From DataCleaningPortfolioProject..NashvilleHousing

Update DataCleaningPortfolioProject..NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' Then 'Yes'
	   When SoldAsVacant = 'N' Then 'No'
	   Else SoldAsVacant
	   END
From DataCleaningPortfolioProject..NashvilleHousing

-- Removing Duplicates using CTE

WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER(
	Partition by ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From DataCleaningPortfolioProject..NashvilleHousing
--Order by ParcelID
)
Delete
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

-- Delete Unused Columns

Select *
From DataCleaningPortfolioProject..NashvilleHousing

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Drop Column OwnerAddress, TaxDistrict, PropertyAddress

Alter Table DataCleaningPortfolioProject..NashvilleHousing
Drop Column SaleDate