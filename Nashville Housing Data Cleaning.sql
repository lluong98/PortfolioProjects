/*

Cleaning Data in SQL Queries

*/

USE PortfolioProject

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing
------------------------------------------------------
--Standardize Date Format

SELECT SaleDate, CONVERT (DATE,SaleDate)  --Goal is to get rid of the H:M:S timestamp since it serves no purpose
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD SaleDate_C DATE;
UPDATE NashvilleHousing
SET SaleDate_C = CONVERT(DATE,SaleDate)

SELECT SaleDate_C, CONVERT (DATE,SaleDate)
FROM PortfolioProject.dbo.NashvilleHousing

-----------------------------------------------------------------------------------------------
--Populate Property Address Data


SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing
WHERE PropertyAddress is null

SELECT * 
FROM PortfolioProject.dbo.NashvilleHousing
ORDER BY ParcelID				--You can see that when the PardelID is the same, the PropertyAddress is same as well.
 
--Joining table to itself and using uniqueID to differentiate between rows
SELECT x.ParcelID, x.PropertyAddress, y.ParcelID, y.PropertyAddress, ISNULL(x.PropertyAddress,y.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing x  
JOIN PortfolioProject.dbo.NashvilleHousing y
	ON x.ParcelID = y.ParcelID
	AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress is null

UPDATE x
SET PropertyAddress = ISNULL(x.PropertyAddress,y.PropertyAddress)
FROM PortfolioProject.dbo.NashvilleHousing x  
JOIN PortfolioProject.dbo.NashvilleHousing y
	ON x.ParcelID = y.ParcelID
	AND x.[UniqueID ] <> y.[UniqueID ]
WHERE x.PropertyAddress is null


----------------------------------------------------------------------------------------------------------
---Breaking Out Address into Individual Columns (Address, City, State)

SELECT PropertyAddress, OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

SELECT 
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress)) AS City
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD P_SplitAddress Nvarchar(255);
UPDATE NashvilleHousing
SET P_SplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) - 1)

ALTER TABLE NashvilleHousing
ADD P_SplitCity Nvarchar(255); 
UPDATE NashvilleHousing
SET P_SplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1, LEN(PropertyAddress))

SELECT P_SplitAddress, P_SplitCity		--Check if table updated correctly
FROM NashvilleHousing


SELECT
PARSENAME(REPLACE(OwnerAddress,',','.'), 3), 
PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
PARSENAME(REPLACE(OwnerAddress,',','.'), 1)
FROM PortfolioProject.dbo.NashvilleHousing

SELECT PARSENAME(OwnerAddress, 1), OwnerAddress
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
ADD Owner_S_Address Nvarchar(255), Owner_S_City Nvarchar(255), Owner_S_State Nvarchar(255);

UPDATE NashvilleHousing
SET Owner_S_Address = PARSENAME(REPLACE(OwnerAddress,',','.'), 3),
	Owner_S_City = PARSENAME(REPLACE(OwnerAddress,',','.'), 2),
	Owner_S_State = PARSENAME(REPLACE(OwnerAddress,',','.'), 1)

SELECT Owner_S_Address, Owner_S_City, Owner_S_State	--Check if table updated correctly
FROM NashvilleHousing


---------------------------------------------------------------------------
--Change Y and N to Yes and No in "Sold as Vacant" Field

SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject.dbo.NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2

SELECT SoldAsVacant,
	CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		 WHEN SoldAsVacant = 'N' THEN 'No'
		 ELSE SoldAsVacant
		 END
FROM PortfolioProject.dbo.NashvilleHousing

UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
		WHEN SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END

--------------------------------------------------------------------------------------------------
----Remove Duplicates

WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
DELETE 
FROM RowNumCTE
WHERE row_num > 1

WITH RowNumCTE AS(                        ----CHECK IF REMOVED DUPLICATES
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject.dbo.NashvilleHousing
)
SELECT *
FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

---------------------------------------------------------
--Delete Unused Columns

SELECT *
FROM PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, PropertyAddress, TaxDistrict, SaleDate
