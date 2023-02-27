% Rachel M. Walter, January 24, 2022
% -- Last updated April 12, 2022
%% Summary
% 
% This is MATLAB example code to aid in filtering for time series in the 
% CoralHydro2k database. This code is saved as a text ('.txt') file to aid
% users in creating similar code for other platforms (e.g. R, Python).
% 
% To use in MATLAB, change the file extension to '.m'
% 
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Suggested fields for filtering:
% - Group (see Table 1 in database descriptor): paleoData_coralHydro2kGroup
% - Proxy Type (SrCa, d18O, d18Osw): paleoData_variableName
% - Temporal Coverage:
%   - minYear (record start year)
%   - maxYear (record end year)
% - Record Resolution:
%   - hasResolution_nominal (nominal resolution; see Table 3)
%   - hasResolution_minimum (minimum resolution in units of 'Years CE')
%   - hasResolution_mean    (mean resolution)
%   - hasResolution_median  (median resolution)
%   - hasResolution_maximum (maximum resolution)
% - Location:
%   - geo_latitude  (record latitude; units: degrees N)
%   - geo_longitude (record longitude; units: degrees E)
%   - geo_siteName  (name of the site/location)
%   - geo_ocean     (ocean basin of the coral record)
% - Species: paleoData_archiveSpecies
% 
% ** Other fields (e.g. geo_secondarySiteName, geo_ocean2) can also be used
%    for filtering, but the list above is a suggested starting point. See
%    metadata tables in the database descriptor paper for more information.
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% 
%% Usage notes
% 
% File required: CoralHydro2k database (CoralHydro2kX_X_X.mat)
% 
% This example script uses version 0.5.4 (0_5_4) of the CoralHydro2k
% database. If you have a different local version, be sure to replace
% 'CoralHydro2k0_5_4.mat' with the correct file name in the 'Initialize'
% section below.
% 
%% Initialize
load('CoralHydro2k0_5_4.mat')

% Remove time series of type 'year' from consideration
mask = strcmp({TS.paleoData_variableName},'year');
searchTS = TS(~mask);

% Remove analytical error time series from consideration
mask = ~contains({searchTS.paleoData_variableName}, 'Uncertainty', 'ignoreCase', true);
searchTS = searchTS(mask);

% Create a separate list of only primary timeseries (no d18Osw records or
% annual averages of higher-resolution data)
mask = ~strcmp({searchTS.paleoData_variableName},'d18O_sw');
mask = mask & ~contains({searchTS.paleoData_variableName},'_annual');
primaryTS = searchTS(mask);

%% Filter by numerical fields
% Recommended fields:
% paleoData_coralHydro2kGroup, minYear, maxYear, geo_[latitude, longitude],
% hasResolution_[minimum, mean, median, maximum]
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Example: Filter for all paired records in the database (Groups 1-3)
% * Note that this only takes primary d18O and Sr/Ca timeseries into
% account. To include d18Osw timeseries and annual average timeseries,
% change 'primaryTS' to 'searchTS' in lines 74-75. Searching all timeseries
% will result in redundancies; annual time series (e.g. d18O_annual) are
% the annual averages of the primary time series.
mask = [primaryTS.paleoData_coralHydro2kGroup] <= 3;
results123 = primaryTS(mask);

% Example: Filter for all monthly-bimonthly records (Groups 1,2,4,6)
% * Note that this only takes primary d18O and Sr/Ca timeseries into
% account.
groupSearch = [1 2 4 6];
mask = any([primaryTS.paleoData_coralHydro2kGroup]' == groupSearch, 2);
results1246 = primaryTS(mask);

% Example: Filter for all records within 5 degrees of the equator
% * Note that this only takes primary d18O and Sr/Ca timeseries into
% account.
latitudeList = [primaryTS.geo_latitude]';
mask = (latitudeList <=5 & latitudeList >= -5);
results5deg = primaryTS(mask);

%% Filter by text fields
% Recommended fields:
% paleoData_variableName, hasResolution_nominal, paleoData_archiveSpecies,
% geo_siteName, geo_ocean
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Example: Filter for all d18O timeseries in the database
% * note that this only takes primary d18O time series into account. To
% search for all d18O time series, replace 'strcmp' with 'contains'. This
% is NOT recommended as annual d18O time series are the annual averages of
% primary time series
mask = strcmp({primaryTS.paleoData_variableName},'d18O');
resultsD18O = primaryTS(mask);

% Example: Filter for all monthly d18O and Sr/Ca records in the database
mask = strcmp({primaryTS.hasResolution_nominal},'monthly');
mask = mask | strcmp({primaryTS.hasResolution_nominal},'monthly_uneven');
resultsMonthly = primaryTS(mask); 
% note that 'resultsMonthly' is "monthly" and "monthly_uneven" resolution

% Example: Filter primary timeseries for corals of the genus Porites
mask = contains({primaryTS.paleoData_archiveSpecies}, 'porites', 'ignoreCase', true);
resultsPorites = primaryTS(mask);

% Example: Filter primary timeseries for records in the Atlantic Ocean
mask = contains({primaryTS.geo_ocean}, 'atlantic', 'ignoreCase', true);
resultsAtlantic = primaryTS(mask);

% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
% Special example: Filter for all annual d18O and Sr/Ca records
% ** This list includes EITHER the primary timeseries OR the annual average
%    data, but not both. Priority is given to primary timeseries.

% Remove d18Osw records from consideration
mask = ~contains({searchTS.paleoData_variableName},'d18O_sw');
resultsAnnual = searchTS(mask);

mask = strcmp({resultsAnnual.hasResolution_nominal},'annual') | ...
       strcmp({resultsAnnual.hasResolution_nominal},'annual_uneven');
recordIDs = unique({resultsAnnual.dataSetName})';
% Check record-by-record that annual data from each record appears only once
for x = 1:length(recordIDs)
    % Find all records belonging to each record
    indx = find(strcmp({resultsAnnual.dataSetName},recordIDs{x}));
    annData = mask(indx);
    recordTS = resultsAnnual(indx);
    % Remove redundant annual d18O time series
    d18Omask = contains({recordTS.paleoData_variableName}, 'd18O');
    if sum(d18Omask)>1 && sum(annData(d18Omask))>1
        annData(strcmp({recordTS.paleoData_variableName},'d18O_annual')) = false;
    end
    % Remove redundant annual Sr/Ca time series
    SrCamask = contains({recordTS.paleoData_variableName}, 'SrCa');
    if sum(SrCamask)>1 && sum(annData(SrCamask))>1
        annData(strcmp({recordTS.paleoData_variableName},'SrCa_annual')) = false;
    end
    mask(indx) = annData;
end
resultsAnnual = resultsAnnual(mask);
% note that 'resultsAnnual' is "annual" and "annual_uneven" resolution

%% Clean up temporary variables
clear latitudeList groupSearch mask annData d18Omask indx recordIDs
clear SrCamask x recordTS
