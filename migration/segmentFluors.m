%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Segment a fluorescence image.
%%  Used to define expression regions for comparison of
%%  local migration speeds.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Prepare file lists
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex-combined.mat'; % Index file containing list of MovieData files to process.
load([eDir indexFile]);

%% Segment on K5-mNeonGreen (C2) and K6A-mCherry2 (C3)
nImages = length(mdFileNames);
parpool(35);
parfor imageIndex = 1:nImages
    md = load(mdFileNames(imageIndex), 'MD'); % MD
    tParms = struct;
    tParms.ChannelIndex = [2 3]; % Select channels to threshold
    tParms.ExcludeZero = true;
    tParms.MethodIndx = 3; % 1 = MinMax; 2 = Otsu; 3 = Rosin
    tParms.BatchMode = true;
    tParms.OutputDirectory = [md.MD.outputDirectory_ filesep 'masks'];
    thresholdMovie(md.MD, tParms);
end
