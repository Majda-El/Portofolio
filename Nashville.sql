--Getting infos about the DATA
PRAGMA table_info(NashvilleHousing);
--inspect the SaleDate format
SELECT DISTINCT SaleDate FROM NashvilleHousing LIMIT 10;
--Standardize the SaleDate Format
---Add new column 
ALTER TABLE NashvilleHousing ADD SaleDateConverted DATE;
---remove trailing and leading spaces 
UPDATE NashvilleHousing SET SaleDate = TRIM(SaleDate);
---check for nulls 
SELECT DISTINCT SaleDate FROM NashvilleHousing WHERE SaleDate IS  NULL ;
SELECT COUNT(*) AS BlankOrNullCount FROM NashvilleHousing WHERE TRIM(SaleDate) = '' OR SaleDate IS NULL;
---check format
SELECT DISTINCT SaleDate FROM NashvilleHousing LIMIT 10;
---convert dates--adding padding for single digit months and days
UPDATE NashvilleHousing SET SaleDateConverted = strftime('%Y-%m-%d',SUBSTR(SaleDate, LENGTH(SaleDate) - 3, 4) || '-' || printf('%02d', CAST(SUBSTR(SaleDate, 1, INSTR(SaleDate, '/') - 1) AS INT)) || '-' || printf('%02d', CAST(SUBSTR(SUBSTR(SaleDate, INSTR(SaleDate, '/') + 1), 1, INSTR(SUBSTR(SaleDate, INSTR(SaleDate, '/') + 1), '/') - 1) AS INT))) WHERE SaleDate IS NOT NULL;
---checking for nulls 
SELECT SaleDate,SaleDateConverted FROM NashvilleHousing WHERE SaleDateConverted IS NULL AND SaleDate IS NOT NULL;
--Analyse missing PropertyAddress data
SELECT COUNT(*) AS MissingPropertyAddresses FROM NashvilleHousing WHERE PropertyAddress IS NULL OR TRIM(PropertyAddress) = '';
SELECT *FROM NashvilleHousing WHERE PropertyAddress IS NULL OR TRIM(PropertyAddress) = '' ORDER BY ParcelID;
--- Update PropertyAddress using ParcelID
UPDATE NashvilleHousing SET PropertyAddress = (SELECT b.PropertyAddress FROM NashvilleHousing b WHERE b.ParcelID = NashvilleHousing.ParcelID AND b.UniqueID <> NashvilleHousing.UniqueID AND b.PropertyAddress IS NOT NULL LIMIT 1)WHERE PropertyAddress IS NULL OR TRIM(PropertyAddress) = '';
---Verify for null values 
SELECT COUNT(*) AS RemainingMissingAddresses FROM NashvilleHousing WHERE PropertyAddress IS NULL OR TRIM(PropertyAddress) = '';
--Breaking out Address into Individual Columns (Address, City)
---Verfiy format
SELECT DISTINCT PropertyAddress FROM NashvilleHousing ORDER BY PropertyAddress;
---Add new Columns 
ALTER TABLE NashvilleHousing ADD COLUMN Address TEXT;
ALTER TABLE NashvilleHousing ADD COLUMN City TEXT;
---Update with the split data 
UPDATE NashvilleHousing SET Address = TRIM(SUBSTR(PropertyAddress, 1, INSTR(PropertyAddress, ',') - 1));
UPDATE NashvilleHousing SET City = TRIM(SUBSTR(PropertyAddress, INSTR(PropertyAddress, ',') + 1));
---verfiy the changes 
SELECT PropertyAddress, Address, City FROM NashvilleHousing LIMIT 50;
--Update sodeasvacant field with YES or NO
UPDATE NashvilleHousing SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'WHEN SoldAsVacant = 'N' THEN 'No'ELSE SoldAsVacant END;
SELECT DISTINCT SoldAsVacant FROM NashvilleHousing;
--Remove duplicates
---Identify 
CREATE TABLE NashvilleHousingUnique AS SELECT * FROM NashvilleHousing WHERE rowid IN (SELECT MIN(rowid)FROM NashvilleHousing GROUP BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference);
---Replace original table 
DROP TABLE NashvilleHousing;
ALTER TABLE NashvilleHousingUnique RENAME TO NashvilleHousing;









  




SELECT DISTINCT SaleDateConverted FROM NashvilleHousing LIMIT 10;






  

