%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Adaptation of the u-delineate package
%%  for segmentation and analysis of filament networks.
%%  Create a synthetic "scrambled" filament network
%%  for a similarity analysis control.
%%  See: https://github.com/DanuserLab/u-delineate
%%  Based on Gan et al., Cell Systems, 2016
%%
%%  This routine includes several adaptations for improved
%%  performance when run on a HPC cluster, but lacks some
%%  features available in the latest u-delineate releases.
%%  See methods of this paper for additional details.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
iBatch = 1; % Set this parameter with the batch number to run parallel nodes on a cluster.
eDir = '/project/directory/'; % Set this
% This example uses Slide Set (https://github.com/bnanes/slideset) to organize 
% image MovieData files and associated ROIs marking cell areas. See other scripts
% in this repository for alternate organization strategies.
xmlInFile = [eDir 'slideset-table.xml'];
mdFileNames = bnGetSlidesetTableColumn(xmlInFile, "Data", "ImageMD");
cellROIs = bnGetSlidesetTableColumn(xmlInFile, "Data", "ROI");

%% Setup the parallel pool for concurrent jobs - this is needed to avoid concurrency issues running on multiple nodes. 
% Remove this section if not running on an HPC cluster.
cl = parcluster();
slurmid = getenv('SLURM_JOB_ID');
parjsl = cl.JobStorageLocation;
parjsl = [parjsl filesep slurmid];
if ~isfolder(parjsl), mkdir(parjsl); end
cl.JobStorageLocation = parjsl;
ppobj = parpool(cl, 12);

batchSize = 1;
nMovie = length(mdFileNames);
imStart = ((iBatch - 1) * batchSize) + 1;
imEnd = min([(imStart+(batchSize-1)) nMovie]);

%%
for i = imStart:imEnd % Loop through the images
    mdFileName = mdFileNames(i);
    load(mdFileName);
    radius = 20;
    
    %%
    imgName = strsplit(MD.movieDataFileName_, '.');
    imgName = imgName{1};
    C1datFile = [MD.processes_{5}.outFilePaths_{1} '/DataOutput/filament_seg_' imgName '_c1_t1.mat'];
    C2datFile = [MD.processes_{5}.outFilePaths_{2} '/DataOutput/filament_seg_' imgName '_c2_t1.mat'];
    C1scrambleDatFile = [MD.processes_{5}.outFilePaths_{1} '/DataOutput/filament_scram_' imgName '_c1_t1.mat'];
    C2scrambleDatFile = [MD.processes_{5}.outFilePaths_{2} '/DataOutput/filament_scram_' imgName '_c2_t1.mat'];
    mdOutDir = MD.outputDirectory_;
    scramSimOutDir = [mdOutDir '/c1c2scramDynamics'];
    
    %%
    C1dat = load(C1datFile);
    C2dat = load(C2datFile);
    
    %% Generate scrambled network model
    tic
    [scrable_digital_model,scrable_orientation_model,scrable_VIF_current_seg,scrable_VIF_current_orientation,...
        scrable_XX,scrable_YY,scrable_OO, scrable_II] ...
        = filament_model_scrable( C1dat.current_model,...
            size(C1dat.current_seg_orientation),...
            radius, pi/2, ones(size(C1dat.current_seg_orientation)));
    save(C1scrambleDatFile, "scrable_digital_model","scrable_orientation_model",...
        "scrable_VIF_current_seg","scrable_VIF_current_orientation",...
        "scrable_XX","scrable_YY","scrable_OO", "scrable_II");
    C1scramble = scrable_digital_model;
    toc

    tic
    [scrable_digital_model,scrable_orientation_model,scrable_VIF_current_seg,scrable_VIF_current_orientation,...
        scrable_XX,scrable_YY,scrable_OO, scrable_II] ...
        = filament_model_scrable( C2dat.current_model,...
            size(C2dat.current_seg_orientation),...
            radius, pi/2, ones(size(C2dat.current_seg_orientation)));
    save(C2scrambleDatFile, "scrable_digital_model","scrable_orientation_model",...
        "scrable_VIF_current_seg","scrable_VIF_current_orientation",...
        "scrable_XX","scrable_YY","scrable_OO", "scrable_II");
    C2scramble = scrable_digital_model;
    toc
    
    %% Need to get rid of empty filaments
    empty = zeros(1,length(C1scramble));
    for(j = 1:length(C1scramble))
        empty(1,j) = isempty(C1scramble{j});
    end
    C1scramble = C1scramble(~empty);
    empty = zeros(1,length(C2scramble));
    for(j = 1:length(C2scramble))
        empty(1,j) = isempty(C2scramble{j});
    end
    C2scramble = C2scramble(~empty);
    
    %% Calculate scrambled network similarity
    tic
    [similarity_scoremap, difference_map] = ...
        network_similarity_scoremap(...
            C1scramble, C2scramble,...
            size(C1dat.current_seg_orientation),...
            radius, radius, sqrt(3)*radius/4/2,...
            pi/(2*sqrt(3))/2, 3*radius/8);
    toc
    similarity_scoremap_8bit = uint8(similarity_scoremap * 255);
    
    if ~exist(scramSimOutDir, 'dir')
        mkdir(scramSimOutDir)
    end
    imwrite(similarity_scoremap_8bit, [scramSimOutDir,filesep,'map.tif']);
    
end
