%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Invoke the MonolayerKymographs package
%%  for analysis of monolayer migration.
%%  See: https://github.com/DanuserLab/MonolayerKymographs
%%  Based on Zaritsky et al., J Cell Biol, 2017
%%
%%  This routine invokes the original package which
%%  requires single-channel TIFF images.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
iImg = 1; % Set this parameter with the batch number to run parallel nodes on a cluster.
eDir = '/project/directory/'; % Set this
imgFiles = ["image1.tiff" "image2.tiff"]; % Set this

%% Set up params
imgPrms.pixelSize = 0.65
imgPrms.timePerFrame = 6
imgPrms.isDx = false; % horizontal motion
imgPrms.nTime = 231 % number of frames to analyze
imgPrms.nRois = 1

imgPrms.always = false; % false means that available intermediate results are going to be used
imgPrms.patchSizeUm = 15.0; % 15 um
imgPrms.maxSpeed = 90; % um / hr (max cell speed)
% for region growing segmentation
imgPrms.regionMerginParams.P = 0.03;% small P --> more merging
imgPrms.regionMerginParams.Q = 0.005;% large Q --> more merging (more significant than P)
imgPrms.regionMerginParams.fVecSim = @vecEuclideanSimilarity;
% for kymographs display
imgPrms.kymoResolution.maxDistMu = 360; % how deep to go into the monolayer (um) 180 default
imgPrms.patchSize = ceil(imgPrms.patchSizeUm/imgPrms.pixelSize); % patch size in pixels
imgPrms.kymoResolution.min = imgPrms.patchSize;
imgPrms.kymoResolution.stripSize = imgPrms.patchSize;

%% Invoke the package
% This block is organized to run on one image.
% See other scripts in this repository for other strategies.
mainTimeLapse(char(imgFiles(iImg)), imgPrms);
