%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Invoke the MonolayerKymographs package
%%  for analysis of monolayer migration.
%%  See: https://github.com/DanuserLab/MonolayerKymographs
%%  Based on Zaritsky et al., J Cell Biol, 2017
%%
%%  This routine includes several adaptations to use the 
%%  MovieData system, and package scripts have been re-implemented.
%%  Re-implementations are included in this repository.
%%  See methods of this paper for additional details.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
iBatch = 1; % Set this parameter with the batch number to run parallel nodes on a cluster.
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex-combined.mat'; % Index file containing list of MovieData files to process (mdFileNames).
load([eDir indexFile]); 
batchSize = 1; % Number of movies to process per batch
nMovie = length(mdFileNames);
imStart = ((iBatch - 1) * batchSize) + 1;
imEnd = min([(imStart+(batchSize-1)) nMovie]);

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

%% Setup the parallel pool for concurrent jobs - this is needed to avoid concurrency issues running on multiple nodes. 
% Remove this section if not running on an HPC cluster.
cl = parcluster();
slurmid = getenv('SLURM_JOB_ID');
parjsl = cl.JobStorageLocation;
parjsl = [parjsl filesep slurmid];
if ~isfolder(parjsl), mkdir(parjsl); end
cl.JobStorageLocation = parjsl;
ppobj = parpool(cl, 12);

%% Invoke the package
% This block is organized to run a batch of images in parallel. 
% See other scripts in this repository for other strategies.
parfor iImg = imStart:imEnd
    load(mdFileNames(iImg));
    imgPrms.nTime = MD.nFrames_ - 1;
    [params, dirs] = bnInitMigrationParamsDirs(MD, imgPrms, eDir);
    bnLocalMotionEstimation(MD, iChan, params, dirs);
    bnTemporalBasedSegmentation(MD, iChan, params, dirs);
    bnCorrectGlobalMotion(MD, iChan, params, dirs);
    bnMonolayerMigrationMovie(MD, iChan, params, dirs); % Generate visualizations
end
