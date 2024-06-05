%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Adaptation of the u-delineate package
%%  for segmentation and analysis of filament networks.
%%  Creates filament network dynamics score maps.
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

%% Invoke the package
% This block is organized to run a batch of images in sequence, whith batches
% run in parallel across multiple cluster nodes. 
% See other scripts in this repository for other strategies.
for i = imStart:imEnd 
    disp(['Starting segmentation work on image ' num2str(i) '...']);
    md = load(mdFileNames(i));
    md = md.MD;
    segParam = default_parameter_filament_segmentation(md);
    for j = 1:5
        segParam{j}.ChannelIndex = [1 2]; % Set channels with filaments to analyze
    end
    segParam{1}.BatchMode = 1;
    segParam{2}.FillBoundaryHoles = false;
    segParam{5}.Combine_Way = {'geo_based_GM'  'geo_based_GM'  'geo_based_GM'}; % default is 'geo_based_no_GM; the GM part (filament extension) is very expensive
    segParam{5}.CoefAlpha = [1.3 1.3 1.3]; % Default is [1.6 1.6 1.6]
    segParam{5}.Cell_Mask_ind = [1 1 1]; % 1, segmentation from same channel; 2, static ROI (not sure how this is generated; 4, ?; 5, no limit (default); 6, marked cells?
    segParam{5}.nofiguredisruption = 1; % Don't show a bunch of charts
    segParam{5}.noGraphics = 1; % Try to speed up by skipping graphics
    bn_load_MD_run_filament_segmentation(md,[], 'input_parameter_set', segParam);
    disp(['Done with image ' num2str(i) ', saving MD file...']);
    md.save();
    disp(['############# Done saving MD file for image ' num2str(i) '. #############']);
end
disp('Done with segmentation');

%% Filament dynamics analysis (same channel across time)
parfor frameGap = 1 : 4
    disp(['#### Now working on dynamics for dt = ' num2str(frameGap)]);
    for i = imStart:imEnd % Loop through the images
        disp(['## Starting work on image ' num2str(i) '...']);
        md = load(mdFileNames(i));
        md = md.MD;
        radius = 20;
	    disp('(Channel 1)');
	    try
            bn_load_2_MD_network_for_dynamics_compare_F1(...
                [md.movieDataPath_ filesep md.movieDataFileName_],1,1,...
                [md.movieDataPath_ filesep md.movieDataFileName_],1,1+frameGap,...
                radius, 1, radius, 3*radius/8,...
                sqrt(3)*radius/4/2, pi/(2*sqrt(3))/2,...
                1, 0, ['dt' num2str(frameGap) 'c1dynamics']);
	    catch ME
            warning(ME.message);
	    end
        disp('(Channel 2)');
	    try
            bn_load_2_MD_network_for_dynamics_compare_F1(...
                [md.movieDataPath_ filesep md.movieDataFileName_],2,1,...
                [md.movieDataPath_ filesep md.movieDataFileName_],2,1+frameGap,...
                radius, 1, radius, 3*radius/8,...
                sqrt(3)*radius/4/2, pi/(2*sqrt(3))/2,...
                1, 0, ['dt' num2str(frameGap) 'c1dynamics']);
	    catch ME
            warning(ME.message);
	    end
        disp(['Done with image ' num2str(i) ', saving MD file...']);
        md.save();
        disp(['Done saving MD file for image ' num2str(i) '.']);
    end
    disp('Done with network analysis');
end

%% Filament similarity analysis (same time across channels)
disp(['#### Now working on channel similarity']);
for i = imStart:imEnd % Loop through the images
    disp(['## Starting work on image ' num2str(i) '...']);
    md = load(mdFileNames(i));
    md = md.MD;
    radius = 20;
    try
        bn_load_2_MD_network_for_dynamics_compare_F1(...
            [md.movieDataPath_ filesep md.movieDataFileName_],1,1,...
            [md.movieDataPath_ filesep md.movieDataFileName_],2,1,...
            radius, 1, radius, 3*radius/8,...
            sqrt(3)*radius/4/2, pi/(2*sqrt(3))/2,...
            1, 0, ['c1c2dynamics']);
    catch ME
        warning(ME.message);
    end
    disp(['Done with image ' num2str(i) ', saving MD file...']);
    md.save();
    disp(['Done saving MD file for image ' num2str(i) '.']);
end
disp('Done with network analysis');
