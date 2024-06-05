%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Proximity Ligation Assay detection using
%%  wavelet denoising and multiscale products 
%%  of wavelet coefficients.
%%  See: 10.1016/s0031-3203(01)00127-3
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
iBatch = 1; % Set this parameter with the batch number to run parallel nodes on a cluster.
eDir = '/project/directory/'; % Set this
outDir = eDir + "plaDetect/";
% This example uses Slide Set (https://github.com/bnanes/slideset) to organize 
% image MovieData files and associated ROIs marking cell areas. See other scripts
% in this repository for alternate organization strategies.
ssTab = [eDir 'slideset-table.xml'];
imgFileNames = eDir + bnGetSlidesetTableColumn(ssTab, "Data", "Img");

%% Setup the parallel pool for concurrent jobs
if exist('iBatch', 'var') == 1
    cl = parcluster();
    slurmid = getenv('SLURM_JOB_ID');
    parjsl = cl.JobStorageLocation;
    parjsl = [parjsl filesep slurmid];
    if ~isfolder(parjsl), mkdir(parjsl); end
    cl.JobStorageLocation = parjsl;
    ppobj = parpool(cl);
end

batchSize = 2; % Number of images to run on each SLURM batch job
if exist('iBatch', 'var') == 0
    iBatch = 1;
    batchSize = length(imgFileNames);
end
nImg = length(imgFileNames);
imStart = ((iBatch - 1) * batchSize) + 1;
imEnd = min([(imStart+(batchSize-1)) nImg]);

%%
parfor i = imStart:imEnd % Loop through the images
%%
%i = 5;
imgFileName = imgFileNames(i);
[posA, posB] = regexp(imgFileName, "batchName-\d_\d+(?=.nd2)");
imgName = extractBetween(imgFileName, posA, posB);

%%
I = bfopen(char(imgFileName));
Ipla = I{1}{4,1};
Inuc = I{1}{1,1};

%% Filtering and wavelet detection
IplaFilt = imadjust(Ipla, stretchlim(Ipla, [0.67 1]), [0 1], 1.5);
[frameInfo, imgDenoised] = detectSpotsWT(IplaFilt, 'PostProc', 2);

%% Create detection image
RGB = bnRGBify(IplaFilt, 'rel', [0 0.9999]);
M = zeros(size(Ipla));
M(sub2ind(size(Ipla), round(frameInfo.yav), round(frameInfo.xav))) = 1;
M = imdilate(M,  [1 1 1 1; 1 0 0 1; 1 0 0 1; 1 1 1 1]);
RGB = bnRGBoverlay(RGB, M, 255, 0, 0);
if ~isfolder(outDir)
    mkdir(outDir);
end
imwrite(RGB, char(outDir + imgName + "_spotDetect.png"));

%% Create detection point mask
M = zeros(size(Ipla));
M(sub2ind(size(Ipla), round(frameInfo.yav), round(frameInfo.xav))) = 1;
if ~isfolder(outDir)
    mkdir(outDir);
end
imwrite(M, char(outDir + imgName + "_pointMask.png"));

%%
end
