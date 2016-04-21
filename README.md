# Regional Data Store
This repo houses code and plans related to the development of a regional interface to data which will be stored on the CDRC CKAN platform.

The regions included will be: 

* Local Enterprise Partnerships (LEPS)
* Combined authorities (some are termed City Regions)

Both are aggregations of local authority districts.

Also:

* "Northern Powerhouse" - which we will define, but most sensibly as a selection of the combined authorities.

## Tasks - Data
For 1 - 3 I want:

* Full extent (dissolved LAD)
* LAD
* OA
* MSOA
* LSOA
* WARD

1. Generate a new set of Shapefile boundaries for the *LEPs* from the latest [OS Open Data release] (https://www.ordnancesurvey.co.uk/business-and-government/products/boundary-line.html)
	* [Map](https://www.gov.uk/government/publications/local-enterprise-partnerships-map)
	* [Lookup](https://www.gov.uk/government/publications/local-enterprise-partnerships-local-authority-mapping) - Please check with BIS that these are the latest definitions

2. Generate a new set of Shapefile boundaries for *Combined Authorities* from the latest [OS Open Data release](https://www.ordnancesurvey.co.uk/business-and-government/products/boundary-line.html)
	* [Lookup](https://en.wikipedia.org/wiki/Combined_authority)

3. Generate a new set of Shapefile boundaries for the *Northern Powerhouse*
	* Suggest we use an aggregation of the combined authorities as in this [report](http://www.centreforcities.org/wp-content/uploads/2015/06/15-06-01-Northern-Powerhouse-Factsheet.pdf)

4. Datasets (Michail has code for this - suggest getting this onto github here and then create new regional variant) Generate new data packs for the above regional extents - these will all be from England data

	* 2011 Census Key Statistics and Quick Statistics
	* 2011 Census - WZ stats
	* LSOA Population Estimates - [2014](http://www.ons.gov.uk/peoplepopulationandcommunity/populationandmigration/populationestimates/datasets/lowersuperoutputareamidyearpopulationestimates) {these also need updating for LADs
	* LSOA - Median house prices {these also need updating for LADs
	* 2015 IMD
	* IUC
	* 2011 OAC
	* [Broadand](http://stakeholders.ofcom.org.uk/market-data-research/market-data/infrastructure/connected-nations-2015/downloads/)  {these also need updating for LADs
	* [Mortgage lending](https://www.cml.org.uk/industry-data/about-postcode-lending/) {these also need updating for LADs
	* Flood Risk

5. Create icons for each of the regional extents - icon code in repo. These will be used to order on CKAN.

## Website
1. All of the above needs to get onto CKAN with appropriate metadata; this will involve talking to Wen Li at UCL.
2. Develop a Northern Regional Data Facility page which catalogues the data stored on CKAN. We can worry about the design later.