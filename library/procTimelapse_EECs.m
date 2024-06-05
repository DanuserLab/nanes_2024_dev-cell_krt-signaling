%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Adaptation of the MonolayerKymographs package
%%  for analysis of epidermal organoid culture
%%  migration live imaging.
%%  See: https://github.com/DanuserLab/MonolayerKymographs
%%  Based on Zaritsky et al., J Cell Biol, 2017
%%
%%  This routine includes several adaptations for epidermal
%%  cultures, and package scripts have been re-implemented.
%%  Re-implementations are included in this repository.
%%  See methods of this paper for additional details.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
iBatch = 1; % Set this parameter with the batch number to run parallel nodes on a cluster.
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex-combined.mat'; % Index file containing list of MovieData files to process.
load([eDir indexFile]);

%% Set up params
imgPrms.pixelSize = 0.65;
imgPrms.timePerFrame = 6;
imgPrms.isDx = false; % horizontal motion
imgPrms.nTime = 140; % number of frames to analyze
imgPrms.nRois = 1;

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
% This block is organized to run on one image, processing two fluorescence channels in parallel. 
% See other scripts in this repository for other strategies.
load(mdFileNames(iBatch));
imgPrms.nTime = MD.nFrames_ - 1;
parfor iChan = 1:2
    smoothFxn = @(x) imgaussfilt(x, 5); % Preproc gauss filter to smooth pattern from filer support for the epidermal organoid.
    [params, dirs] = bnInitMigrationParamsDirs(MD, imgPrms, eDir);
    bnLocalMotionEstimation(MD, iChan, params, dirs, 'preproc', smoothFxn);
    bnTemporalBasedSegmentation(MD, iChan, params, dirs, 'preproc', smoothFxn, 'altTextureFxn', @bnFirstFrameSegmentationEEC); % Note alternate segmentation seed is needed for fluorescence images.
    bnCorrectGlobalMotion(MD, iChan, params, dirs, 'preproc', smoothFxn);
    bnMonolayerMigrationMovie(MD, iChan, params, dirs); % Generate visualizations
end
