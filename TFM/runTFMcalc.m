%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Run the u-inferforce (TFM) package
%%  See: https://github.com/DanuserLab/u-inferforce
%%  Based on Han et al., Nature Methods, 2015
%%
%%  This routine does not modify the u-inferforce package.
%%  It can be used to automate processing of a large number
%%  of images. An HPC cluster with >= 64 GB memory per node
%%  is recommended for the fastBEM method.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% iBatch = 1:39; Set this parameter with the batch number to run parallel nodes on a cluster.
%
%% Setup the parallel pool for concurrent jobs - this is needed to avoid concurrency issues running on multiple nodes. 
cl = parcluster();
slurmid = getenv('SLURM_JOB_ID');
parjsl = cl.JobStorageLocation;
parjsl = [parjsl filesep slurmid];
if ~isfolder(parjsl), mkdir(parjsl); end
cl.JobStorageLocation = parjsl;
ppobj = parpool(cl);

%%
eDir = '/project/directory/'; % Set this
oldHome = cd(eDir);
fileLists = getFileLists();
cd(oldHome);

mdFileNames = fileLists.mdFullFileNames;
refTif = fileLists.refTif;

%% FastBEM does not perform well running on multiple images in parallel
iImg = iBatch;
lf = load(mdFileNames(iImg), 'MD');
MD = lf.MD;

%% Setup ROI mask
% Note that the mask is created in pre-registration space, then registered
% as needed by the displacement and force field processes
ROI = sum(bnGetMasksFromRoiSvg(fileLists.cellROIs(iImg), [1024 1024]),3);
ROI = ROI > 0;
ROI = imdilate(ROI, strel('disk', 63, 4)); % dilate 63px * 0.08um/px = 5.04um; may need to adjust this depending on your segmentation quality
roiPath = fullfile(MD.getPath(), 'roi');
if ~isfolder(roiPath), mkdir(roiPath); end
roiMaskPath = fullfile(roiPath, 'mask.tif');
imwrite(ROI, roiMaskPath);
MD.roiMask = [];
MD.setROIMaskPath(roiMaskPath); % Generally required for FastBEM, but not needed for FTTC
MD.save;

%% TFM Package
iTfmPackage = MD.getPackageIndex('TFMPackage');
if(isempty(iTfmPackage))
    MD.addPackage(TFMPackage(MD));
    iTfmPackage = MD.getPackageIndex('TFMPackage');
end

%% Select processes to run
% 0, skip if process exists
% 1, run regardless
% [Registration, Displacement, Correction, Force]
forceRun = [0 0 0 1];

%% Registration
funParams = EfficientSubpixelRegistrationProcess.getDefaultParams(MD);
%funParams.ChannelIndex = 1; % 
funParams.referenceFramePath = char(refTif(iImg)); % Set reference bead image
funParams.BeadsChannel = 1; 

iEsrp = MD.getProcessIndex('EfficientSubpixelRegistrationProcess');
if(isempty(iEsrp))
    MD.addProcess(EfficientSubpixelRegistrationProcess(MD, 'funParams', funParams));
    iEsrp = MD.getProcessIndex('EfficientSubpixelRegistrationProcess');
    MD.processes_{iEsrp}.setParameters(funParams);
    MD.processes_{iEsrp}.run();
elseif forceRun(1)
    MD.processes_{iEsrp}.setParameters(funParams);
    MD.processes_{iEsrp}.run();
end

%% Displacement field calculation
funParams = DisplacementFieldCalculationProcess.getDefaultParams(MD);
funParams.ChannelIndex = 1; % beads 
funParams.referenceFramePath = char(refTif(iImg)); % Set reference bead image
funParams.minCorLength = 20;
funParams.maxFlowSpeed = 50;
funParams.highRes = true; %true;
funParams.addNonLocMaxBeads = false; % default is false
%funParams.alpha=.05;
funParams.mode = 'accurate'; %'fast'; % This seems to control whether or not to use SCII from Han et al (accurate = yes, this is slower)
funParams.useGrid = false; % Default is false; true uses faster, but less accurate, PIV-based estimation

iDfcp = MD.getProcessIndex('DisplacementFieldCalculationProcess');
if(isempty(iDfcp))
    MD.addProcess(DisplacementFieldCalculationProcess(MD, 'funParams', funParams));
    iDfcp = MD.getProcessIndex('DisplacementFieldCalculationProcess');
    MD.processes_{iDfcp}.setParameters(funParams);
    MD.processes_{iDfcp}.run();
elseif forceRun(2)
    MD.processes_{iDfcp}.setParameters(funParams);
    MD.processes_{iDfcp}.run();
end
    
%% Displacement field correction
funParams = DisplacementFieldCorrectionProcess.getDefaultParams(MD);
iDfcorp = MD.getProcessIndex('DisplacementFieldCorrectionProcess');
if(isempty(iDfcorp))
    MD.addProcess(DisplacementFieldCorrectionProcess(MD, 'funParams', funParams));
    iDfcorp = MD.getProcessIndex('DisplacementFieldCorrectionProcess');
    MD.processes_{iDfcorp}.setParameters(funParams);
    MD.processes_{iDfcorp}.run();
elseif forceRun(3)
    MD.processes_{iDfcorp}.setParameters(funParams);
    MD.processes_{iDfcorp}.run();
end

%% Force field calculation
funParams = ForceFieldCalculationProcess.getDefaultParams(MD);
funParams.YoungModulus = 8000;
%funParams.PoissonRatio = .5;
funParams.method = 'FastBEM'; %'FTTC';
funParams.meshPtsFwdSol = 4096; % Start at 4096, then step down as needed for memory
funParams.regParam=0.05;
funParams.solMethodBEM='1NormReg';
funParams.basisClassTblPath=[MD.outputDirectory_ filesep 'tfmbasistable.mat'];
%funParams.thickness=34000;
funParams.useLcurve=false; % Run this on a sample of images to determine an appropriate value for regParam
%funParams.lcornerOptimal='optimal';
meshPointsArray = [4096 3072 2048 1024 512 256 128];

iFfcp = MD.getProcessIndex('ForceFieldCalculationProcess');
if(isempty(iFfcp))
    MD.addProcess(ForceFieldCalculationProcess(MD, 'funParams', funParams));
    iFfcp = MD.getProcessIndex('ForceFieldCalculationProcess');
    tryWithMeshPoints(MD.processes_{iFfcp}, funParams, meshPointsArray);
elseif forceRun(4)
    tryWithMeshPoints(MD.processes_{iFfcp}, funParams, meshPointsArray);
end

%% Try running the TFM calculations, with decreasing mesh points for each failure (presuming out of memory)
function [] = tryWithMeshPoints(TFMproc, funParams, meshPointsArray)
    success = 0;
    meshCounter = 1;
    maxMeshTries = length(meshPointsArray);
    while success < 1
        if meshCounter > maxMeshTries
            error('#### Unable to run TFM calculation with any of the provided mesh sizes! ####');
        end
        try
            disp(['## Trying TFM calculations with mesh size: ' num2str(meshPointsArray(meshCounter)) ' ##']);
            funParams.meshPtsFwdSol = meshPointsArray(meshCounter);
            TFMproc.setParameters(funParams);
            TFMproc.run();
            success = 1; % I guess this means it worked
        catch ME
            success = 0;
            meshCounter = meshCounter + 1;
            disp('## Oh no, something went wrong! ##');
            disp(ME.message);
            if contains(ME.message, 'memory', 'IgnoreCase', true)
                disp('(looks like it might be an out of memory error, lets try again with decreased mesh size)');
            else
                disp('(not sure what to do with this one, lets stop here)');
                error('#### Unexpected error! ####');
            end
        end
    end
end
