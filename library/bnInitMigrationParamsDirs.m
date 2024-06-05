function [params, dirs] = bnInitMigrationParamsDirs(MD, params, eDir, varargin)
% MD, MovieData object
% params, parameters struct
% eDir, Experiment directory char array, ends with filesep ('/path/to/myExperiment/')
% (optional) analysisDirName, name of folder in the MD directory where the analysis results go, default = 'monolayerMigration'

    ip = inputParser;
    addParameter(ip, 'analysisDirName', 'monolayerMigration');
    parse(ip, varargin{:});
    analysisDirName = ip.Results.analysisDirName;    

    mainDirname = MD.outputDirectory_;

    %% Parameters

    if ~isfield(params,'pixelSize') || ~isfield(params,'timePerFrame')
        error('pixelSize and timePerFrame are obligatory parameters');
    end

    if ~isfield(params,'isDx')
        params.isDx = true;
    else
        if ~params.isDx
            warning('Images will be automatically rotated counterclockwise 90 degrees');
        end
    end

    if ~isfield(params,'frameJump')
        params.frameJump = 1;
    end
    
    if ~isfield(params,'maxSpeed')
        params.maxSpeed = 90; % um / hr    
    end
    
    if ~isfield(params,'fixGlobalMotion')
        params.fixGlobalMotion = false; % correct for bias due to motion
    end
    
    if ~isfield(params,'nRois')
        params.nRois = 1; 
    end

    params.searchRadiusInPixels = ...
    ceil((params.maxSpeed/params.pixelSize)*...
    (params.timePerFrame*params.frameJump/60)); 

    params.toMuPerHour = params.pixelSize * 60/(params.timePerFrame*params.frameJump);

    if ~isfield(params,'patchSize')
        params.patchSize = ceil(params.patchSizeUm/params.pixelSize); % 15 um in pixels
    end

    if ~isfield(params,'nBilateralIter')
        params.nBilateralIter = 1;
    end

    if ~isfield(params,'minClusterArea') % in mu^2
        params.minClusterArea = 5000;
    end

    if ~isfield(params,'regionMerginParams')
        params.regionMerginParams.P = 0.03;% small P --> more merging
        params.regionMerginParams.Q = 0.005;% large Q --> more merging (more significant than P)
    end

    if ~isfield(params,'kymoResolution') % jumps of patchSize
        params.kymoResolution.maxDistMu = 180; % um
        params.kymoResolution.min = params.patchSize;
        params.kymoResolution.stripSize = params.patchSize;    
    end

    params.kymoResolution.nPatches = floor(params.kymoResolution.maxDistMu / params.patchSizeUm);
    params.kymoResolution.max = params.kymoResolution.nPatches * params.patchSize;%ceil(params.kymoResolution.maxDistMu/params.pixelSize); % 500 um in pixels

    params.strips =  params.kymoResolution.min : params.kymoResolution.stripSize : params.kymoResolution.max;
    params.nstrips = length(params.strips);

    if ~isfield(params,'maxNFrames')
        params.maxNFrames = 300;
    end

    if ~isfield(params,'always')
        params.always = false;
    end

    %% Directories

    dirs.main = eDir; % Must end with filesep 
    dirs.dirname = [mainDirname filesep analysisDirName];

    % images
    dirs.images = [dirs.dirname filesep 'images' filesep];

    % MF
    dirs.mf = [dirs.dirname filesep 'MF' filesep];
    dirs.mfData = [dirs.mf 'mf' filesep];
    dirs.mfDataOrig = [dirs.mf 'mfOrig' filesep];
    dirs.mfScores = [dirs.mf 'scoresVis' filesep];
    dirs.mfBilateral = [dirs.mf 'bilateral' filesep];
    dirs.mfVis = [dirs.mf 'mfVis' filesep];

    % ROI
    dirs.roi = [dirs.dirname filesep 'ROI' filesep];
    dirs.roiData = [dirs.roi 'roi' filesep];
    dirs.roiVis = [dirs.roi 'vis' filesep];

    % Coordination
    dirs.coordination = [dirs.dirname filesep 'coordination' filesep];
    dirs.coordinationVis = [dirs.coordination 'vis'];

    % kymographs
    dirs.kymographs = [dirs.main 'kymographs' filesep];
    dirs.speedKymograph = [dirs.kymographs 'speed' filesep];
    dirs.directionalityKymograph = [dirs.kymographs 'directionality' filesep];
    dirs.coordinationKymograph = [dirs.kymographs 'coordination' filesep];

    % Healing rate
    dirs.healingRate = [dirs.dirname filesep 'healingRate' filesep];
    dirs.segmentation = [dirs.main 'segmentation' filesep];

    % motion correction (micrscope repeat error)
    dirs.correctMotion = [dirs.dirname filesep 'correctMotion' filesep];

    %% Create local directories
    if ~exist(dirs.dirname,'dir')
        mkdir(dirs.dirname);
    end

    if ~exist(dirs.images,'dir')
        mkdir(dirs.images);
    end

    if ~exist(dirs.mf,'dir')
        mkdir(dirs.mf);
    end

    if ~exist(dirs.mfData,'dir')
        mkdir(dirs.mfData);
    end

    if ~exist(dirs.mfDataOrig,'dir')
        mkdir(dirs.mfDataOrig);
    end

    if ~exist(dirs.mfScores,'dir')
        mkdir(dirs.mfScores);
    end

    if ~exist(dirs.mfBilateral,'dir')
        mkdir(dirs.mfBilateral);
    end

    if ~exist(dirs.mfVis,'dir')
        mkdir(dirs.mfVis);
    end

    if ~exist(dirs.roi,'dir')
        mkdir(dirs.roi);
    end

    if ~exist(dirs.roiData,'dir')
        mkdir(dirs.roiData);
    end

    if ~exist(dirs.roiVis,'dir')
        mkdir(dirs.roiVis);
    end

    if ~exist(dirs.coordination,'dir')
        mkdir(dirs.coordination);
    end

    if ~exist(dirs.coordination,'dir')
        mkdir(dirs.coordinationVis);
    end

    if ~exist(dirs.kymographs,'dir')
        mkdir(dirs.kymographs);
    end
    
    if ~exist(dirs.speedKymograph,'dir')
        mkdir(dirs.speedKymograph);
    end
    
    if ~exist(dirs.directionalityKymograph,'dir')
        mkdir(dirs.directionalityKymograph);
    end
    
    if ~exist(dirs.coordinationKymograph,'dir')
        mkdir(dirs.coordinationKymograph);
    end
    
    if ~exist(dirs.healingRate,'dir')
        mkdir(dirs.healingRate);
    end
    
    if ~exist(dirs.segmentation,'dir')
        mkdir(dirs.segmentation);
    end
    
    if ~exist(dirs.correctMotion,'dir')
        mkdir(dirs.correctMotion);
    end

end
