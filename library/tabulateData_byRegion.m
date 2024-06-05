%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Extract a table of migration speeds split by
%%  expression region. Requires running both the
%%  MonolayerKymographs package and a segmentation process.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex-combined.mat'; % Index file containing list of MovieData files to process.
load([eDir indexFile]);
minDist = 10; % um
maxDist = 200; % um
nMovie = length(mdFileNames);

mNames = strings(1,nMovie);
mHealingRate = strings(1,nMovie);
for i = 1:nMovie
    mNames(i) = strcat("movieName", string(i)); % Need to adjust this to fit naming convention
    mHealingRate(i) = strcat(eDir, "healingRate/", mNames(i), "_healingRate.mat");
end

%% Get dimensionality info from first movie
load(mdFileNames(1), 'MD');
nFrame = MD.nFrames_;
nChan = MD.getDimensions();
nChan = nChan(4);
clear MD;

%% Get kymograph table by segmentation
% Columns:
% 1, Movie #
% 2, Frame #
% 3, C1-high
% 4, C2-high
% 5, Speed
% 6, Directionality
% 7, Coordination
% 8, Area, in pixels
% 9, Angular change, in radians

subtabCells = cell(1,nMovie);
for i = 1:nMovie
    subtabCells{i} = bnSegmentationKymograph(...
        2,3,...
        minDist/0.65,maxDist/0.65,... % um to px
        mdFileNames(i), i,...
        strcat(eDir, mNames(i), "/ROI/roi/"),...
        strcat(eDir, mNames(i), "/MF/mf/"),...
        strcat(eDir, mNames(i), "/coordination/")...
     );
end

%% Reformat and save CSV
tabDat = zeros(nMovie * (nFrame-1) * 4, 9);
blockSize = (nFrame-1)*4;
for i = 1:nMovie    
    tabDat((i-1)*blockSize+1 : i*blockSize, :) = subtabCells{i};
end
writematrix(tabDat,...
    [eDir 'results_table.csv'...
    sprintf('%03d', minDist) '_' sprintf('%03d', maxDist) '.csv']);
