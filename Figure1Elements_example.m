% Rachel Walter, February 26, 2023
%% INFO
% This script creates the elements of Figure 1 of the PAGES CoralHydro2k 
% database manuscript. 
% 
% * Window 1:   All records plotted, colored by group
% * Window 2:   Area plot showing temporal coverage of database
% 
% *Files required:*
% 
% * CoralHydro2k#_#_#.mat (CoralHydro2k)
% * m_map package         (external; link in citation)
% 
% *External Resources*
% 
% 
% Pawlowicz, R., 2020. "M_Map: A mapping package for
% MATLAB", version 1.4m, [Computer software], available online at
% www.eoas.ubc.ca/~rich/map.html

%% Update log
% * 6-22-21:  Added inset plot of pre~1600 time coverage.
%             Updated resolution color bar with >Annual (vs. 3- & 5-year).
% * 6-24-21:  Time plot now excludes >5 year gaps in data.
% * Oct.'21:  Colors changed from rainbow --> red-yellow-blue to aid in
%             distinction between record groups
% * 5-09-22:  v0.5.2 figures generated for manuscript submission.

%% Setup
% 
%  This section establishes colors and all fine-tune adjustments for the
%  final figure.
% 
addpath ../m_map
load CoralHydro2k1_0_0.mat

% Colors and formatting
colors = [17, 83, 141;...       % USAFA Blue        (G1)
          31, 136, 229;...      % Bleu de France    (G2)
          123, 185, 239;...     % Aero              (G3)
          204, 153, 0;...       % Lemon Curry       (G4)
          255, 191, 0;...       % Amber             (G5)
          216, 28, 96;...       % Ruby              (G6)
          236, 111, 157]/255;   % Cyclamen          (G7)

coastColor = [0.3 0.3 0.3]; % color for map coast outlines
pointSize = 100;            % controls marker size for mapped records
lwidth = 2.5;               % line width for mapped records

centerLine = -160;  % center longitude of map
centerLonLim = 20;  % max. longitude for given centerline (centerline+180)

% Manual figure formatting changes
cbarPos = [.25 .2775 .5 .0225]; % Location of resolution colorbar (norm.)

txlPosShift = [0 -1 0];         % Shift of the timePlot xlabel
tylPosShift = [-2 -5 0];        % Shift of the timePlot ylabel

allRecsPosShift = [-1.23 0 0];  % Shift of "All Records" title (total time series count)

% Figure dimensions/formatting - - - - - - - - - - - - - - - - - - - - - -
width = 8;  % Width in inches
height = 5; % Height in inches

% Set font and background color
baseFontSize = 14;
labelMult = 1.05;   % Font size multiplier for axis labels
titleMult = 1.2;    % Font size multiplier for titles
fontName = 'Arial';
set(0, 'DefaultAxesFontName', fontName,...
       'DefaultFigureColor',[1 1 1],...
       'DefaultAxesXcolor', [0, 0, 0],...
       'DefaultAxesYcolor', [0, 0, 0],...
       'defaultLineLineWidth',1,...
       'defaultLineMarkerSize',7); 
% Set display size
defpos = get(0,'defaultFigurePosition');
set(0,'defaultFigurePosition', [defpos(1) defpos(2) width*100, height*100]);
% Set the defaults for saving/printing to a file
set(0,'defaultFigureInvertHardcopy','on'); % This is the default anyway
set(0,'defaultFigurePaperUnits','inches'); % This is the default anyway
defsize = get(gcf, 'PaperSize');
left = (defsize(1)- width)/2;
bottom = (defsize(2)- height)/2;
defsize = [left, bottom, width, height];
set(0, 'defaultFigurePaperPosition', defsize);
% - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

% Catch glitches
failed = {};

%% Grab information from database

% Sort locations into their groups
recordNames = unique({TS.dataSetName});

list = NaN(length(recordNames), 4); % [lon, lat, group, avg. res]
numSeries = 0; % count of total time series available

for x = 1:length(recordNames)
    tempTS = TS(strcmp({TS.dataSetName},recordNames{x}));
    lat = tempTS(1).geo_latitude;                  % latitude
    lon = tempTS(1).geo_longitude;                 % longitude
    group = tempTS(1).paleoData_coralHydro2kGroup; % group
    if isempty(group) || strcmp(group,'NA')
        failed = [failed; recordNames(x)];
    elseif ischar(group)
        list(x,1:3) = [lon lat str2num(group)];
    else
        list(x,1:3) = [lon lat group];
    end
    switch group
        case {1,2,3}
            tempS = tempTS(strcmp({tempTS.paleoData_variableName},'SrCa')).paleoData_values;
            tempD = tempTS(strcmp({tempTS.paleoData_variableName},'d18O')).paleoData_values;
            
            if size(tempS,1) >= size(tempD,1)
                temp = tempS;
            else
                temp = tempD;
            end
        case {4,5}
            temp = tempTS(strcmp({tempTS.paleoData_variableName},'d18O')).paleoData_values;
        case {6,7}
            temp = tempTS(strcmp({tempTS.paleoData_variableName},'SrCa')).paleoData_values;
        otherwise
            error('Missing group: [%s]',recordNames{x})
    end
    avgRes = nanmean(diff(temp(:,1)));  % Average resolution
    if avgRes <= 1/12 || avgRes <= round(1/12,3)
        list(x,4) = 1;
    elseif avgRes <= 1/6 || avgRes <= round(1/6,3)
        list(x,4) = 2;
    elseif avgRes <= round(1/4,3)
        list(x,4) = 3;
    elseif avgRes <= 1
        list(x,4) = 4;
    elseif avgRes <= 3
        list(x,4) = 5;
    elseif avgRes <= 5
        list(x,4) = 6;
    else
        list(x,4) = 7;
    end
    % total timeseries count
    if ~isempty(tempTS(strcmp({tempTS.paleoData_variableName},'d18O'))); numSeries = numSeries + 1; end
    if ~isempty(tempTS(strcmp({tempTS.paleoData_variableName},'d18O'))); numSeries = numSeries + 1; end
%     if ~isempty(tempTS(strcmp({tempTS.paleoData_variableName},'d18O_sw'))); numSeries = numSeries + 1; end % sw time series not included in the count right now
end % x (recordNames)

% Fix longitude for the projection centered around lon = -150
lonFix = list(:,1);
lonFix(lonFix >centerLonLim) = lonFix(lonFix >centerLonLim) - 360;
list(:,1) = lonFix;

%% Site Plot
% Shows all record locations colored by group

figure(1);

[~,ind] = sort(list(:,3));      % Sort records by group
list = list(ind(end:-1:1),:);   % Group 7 listed and plotted first

hold on

% Set up the axes using m_map
m_proj('robinson', 'clon', centerLine, 'lat', [-50 50])
m_grid('fontname',fontName,'fontSize',12);
m_coast('color',coastColor);
% Attach title and manually left-justify it
ti = title(sprintf('(a) CoralHydro2k database - %.0f total timeseries', numSeries));
ti.Position = ti.Position + allRecsPosShift; % (see line 80 for shift amt.)

% Plot the sites
m_scatter(list(:,1), list(:,2), pointSize, list(:,3), 'linewidth',lwidth)
caxis([0.5 max(size(colors)+0.5)])  % Color code by group

% Text formatting (and colormap)
ax = gca;
ax.FontSize = baseFontSize;
ax.LabelFontSizeMultiplier = labelMult;
ax.TitleFontSizeMultiplier = titleMult;
ax.TitleFontWeight = 'normal';

ax.Colormap = colors;

% Set up a figure legend
invis = area(NaN(1,7), zeros(7));
% Change colors to designated group colors
for x = 1:7
    invis(x).FaceColor = colors(x,:);
end

legend(invis,{'Group 1{ }','Group 2{ }','Group 3{ }','Group 4{ }','Group 5{ }','Group 6{ }','Group 7'},...
        'orientation','horizontal',...
        'position',[.215 .2 .6 0.04], 'fontSize',baseFontSize)
legend('boxoff')

%% Time Plot
% Shows the cumulative number of records containing data for each year

figure(2);

years = 1:2020;
% Set up a matrix (for 7 groups) for counting # records with data each year
mainCount = zeros(1,length(years));
mainCount = repmat(mainCount', [1,7]);

% Count all groups with data falling in each year 1-2020 CE
for n = 1:length(recordNames)
    % Basic scheme:
    % 1) Pull out record data
    % 2) Round timeseries to calendar years and identify unique values
    % 3) Add 1 to each unique year with data (in the correct group)
    % * 3- and 5-year records are assumed to be continuous. Any records
    %   with a >5 year gap in the timeseries is considered non-continuous,
    %   and will have >5-year gaps removed from the count.
    
    % Pull out record data
    tempTS = TS(strcmp({TS.dataSetName},recordNames{n}));
    
    group = tempTS(1).paleoData_coralHydro2kGroup;
    if ischar(group); group = str2double(group); end
    try s = tempTS(strcmp({tempTS.paleoData_variableName},'SrCa')).year; catch; s = []; end
    try o = tempTS(strcmp({tempTS.paleoData_variableName},'d18O')).year; catch; o = []; end
    
    %Round timeseries to calendar years and pull out unique values
    temp = floor([s;o]);
    temp = unique(temp); temp = temp(~isnan(temp));
    % Find gaps >5 years and remove them from the count
    tempDiff = diff(temp); gapYears = find(tempDiff > 5);
    if ~isempty(gapYears)
        if length(gapYears) == 1
            yearIndex = [min(temp):temp(gapYears(1)),temp(gapYears(1)+1):max(temp)];
        else
            for x = 1:length(gapYears)+1
                if x == 1
                    yearIndex = min(temp):temp(gapYears(1));
                elseif x == length(gapYears)+1
                    yearIndex = [yearIndex, temp(gapYears(x-1)):max(temp)];
                else
                    yearIndex = [yearIndex, temp(gapYears(x-1)+1):temp(gapYears(x))];
                end
            end
        end % if length(gapYears) == 1 <-- there's only one >5yr gap
    else
        yearIndex = min(temp):max(temp);
    end % if ~isempty(gapYears) <-- there are gaps in time >5yrs
    
    % Add 1 to each unique year with data (in the correct group)
    mainCount(yearIndex,group) = mainCount(yearIndex,group) + 1;

end % n (recordNames)

% Plot the years with the most records (main axis)
years = 1600:2020;
count = mainCount(years,:);
h = area(years, count);
% Change colors to designated group colors
for x = 1:7
    h(x).FaceColor = colors(x,:);
end


%%
% 
% Adjust axes, create a map legend, add extra labels for proxy type, and 
% add annotations for the pre-1750 inset.
% 

% Add an annotation showing where the inset ends
hold on
plot([1750 1877],[20 91],'k-')
plot([1750 1750],[0 20],'k-')
hold off

% Add a legend for group colors
legend({'Group 1{ }','Group 2{ }','Group 3{ }','Group 4{ }','Group 5{ }','Group 6{ }','Group 7'},...
        'orientation','horizontal',...
        'position',[.215 .95 .6 0.04], 'fontSize',baseFontSize)
legend('boxoff')

% Format main axes
axis([min(years) max(years) 0 150])
xl = xlabel('Year');
xl.Position = xl.Position + txlPosShift;
yl = ylabel('# Records');
yl.Position = yl.Position + tylPosShift;
yticks(0:50:150)

% Format text
ax = gca;
ax.FontSize = baseFontSize;
ax.LabelFontSizeMultiplier = labelMult;
ax.TitleFontSizeMultiplier = titleMult;
ax.TitleFontWeight = 'normal';

figure(1);
% Add annotations denoting record type (additions to legend)
barHeight = 0.2; bLength = 0.02; thickness = 1; textHeight = 198; boxHeight = .04;
% Paired
% pLeft = 0.16; pRight = 0.4493; %(Old label formatting)
% pLeft = 0.0947; pRight = 0.4403; % centered in figure
pLeft = 0.1097; pRight = 0.4553; % centered on map
annotation('textbox','string', 'Paired Sr/Ca-\delta^{18}O records',...
           'position',[pLeft barHeight-boxHeight pRight-pLeft boxHeight],...
           'horizontalAlignment','center','fontSize',baseFontSize,...
           'edgeColor','w', 'verticalAlignment','middle','color',[0 0 0])
annotation('line', [pLeft pRight], [barHeight barHeight], 'lineWidth',thickness)
annotation('line', [pLeft pLeft], [barHeight barHeight+bLength], 'lineWidth',thickness)
annotation('line', [pRight pRight], [barHeight barHeight+bLength], 'lineWidth',thickness)
% d18O-only
% dLeft = pRight+0.003; dRight = 0.644; %(Old label formatting)
% dLeft = pRight+0.003; dRight = 0.6725; % centered in figure
dLeft = pRight+0.003; dRight = 0.6875; % centered on map
annotation('textbox','string', '\delta^{18}O-only records',...
           'position',[dLeft barHeight-boxHeight dRight-dLeft boxHeight],...
           'horizontalAlignment','center','fontSize',baseFontSize,...
           'edgeColor','w', 'verticalAlignment','middle','color',[0 0 0])
annotation('line', [dLeft dRight], [barHeight barHeight], 'lineWidth',thickness)
annotation('line', [dLeft dLeft], [barHeight barHeight+bLength], 'lineWidth',thickness)
annotation('line', [dRight dRight], [barHeight barHeight+bLength], 'lineWidth',thickness)
% Sr/Ca-only
sLeft = dRight+0.003; sRight = sLeft+(dRight-dLeft);
annotation('textbox','string', 'Sr/Ca-only records',...
           'position',[sLeft barHeight-boxHeight sRight-sLeft boxHeight],...
           'horizontalAlignment','center','fontSize',baseFontSize,...
           'edgeColor','w', 'verticalAlignment','middle','color',[0 0 0])
annotation('line', [sLeft sRight], [barHeight barHeight], 'lineWidth',thickness)
annotation('line', [sLeft sLeft], [barHeight barHeight+bLength], 'lineWidth',thickness)
annotation('line', [sRight sRight], [barHeight barHeight+bLength], 'lineWidth',thickness)

%% Plot the years 1-1750 (inset axis)

figure(2);
insetPos = [.142 .605 .5 .302]; % inset position in the figure

years = 1:1750;
count = mainCount(years,:);

axes('Position',insetPos)

bnds = [0 max(years) 0 15]; % axis limits (used later)
axis(bnds)

% Add an x-axis break
xBreak = [400 800];
breakYears = abs(diff(xBreak));
% Change tick labels
tl = xticklabels;
tli = cellfun(@str2num, tl);
ind = find(tli == min(xBreak)); ind2 = find(tli == max(xBreak));
tl(ind) = {[]}; tl(ind+1:ind2) = [];
% Remove broken data and artificially shift other data
mask = years < max(xBreak) & years > min(xBreak);
years(mask) = []; count(mask,:) = [];
years(years >= max(xBreak)) = years(years >= max(xBreak)) - breakYears;

% Plot inset data (temporal coverage)
h = area(years, count);
for x = 1:7
    h(x).FaceColor = colors(x,:);
end

% Format axes
axis([0 max(years) 0 15])
xticks(0:200:max(years)-1)
xticklabels(tl) % ensures artificially-shifted data has the correct labels
yticks([0 5 10])
xticks(0:200:max(years)-1)
% Add visual indication of inset x-axis break
text(min(xBreak)-11,min(bnds(3:4)),'//','fontsize',baseFontSize);
text(min(xBreak)-6,max(bnds(3:4))-.25,'//','fontsize',baseFontSize);

% Formatting (text, axes)
ax = gca;
ax.FontSize = baseFontSize*.75;
ax.LabelFontSizeMultiplier = labelMult/.9;
ax.TitleFontSizeMultiplier = titleMult;
ax.TitleFontWeight = 'normal';
ax.YAxisLocation = 'right';
ax.XRuler.TickLabelGapOffset = -2.25;

text(50, 12.5, '(b) Temporal coverage', 'fontSize', baseFontSize*titleMult)

%% Clean up
clear ans avgRes bnds bottom defpos defsize height lat left lon lonFix
clear lwidth mask msc n o s temp tempD tempDiff tempS ti group tl tli
clear width x xl yearIndex years yl
clear ax h barHeight bLength thickness textHeight boxHeight
clear pLeft pRight dLeft dRight sLeft sRight gapYears
% % % clear ind ind2 mainCount topLeft botRight xBreak breakYears count