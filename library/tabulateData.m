%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Extract tabular data after running the
%%  the u-inferforce (TFM) package.
%%  See: https://github.com/DanuserLab/u-inferforce
%%  Based on Han et al., Nature Methods, 2015
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Prepare file lists
eDir = '/project/directory/'; % Set this
oldHome = cd(eDir);
fileLists = getFileLists();
cd(oldHome);

um_Px = 0.08; % um / px

outCsv = [eDir 'results.csv'];

mdFileNames = fileLists.mdFullFileNames;
refTif = fileLists.refTif;
imgNames = fileLists.imgName;
cellROIs = fileLists.cellROIs;
cellLines = fileLists.cellLine;
imgPlates = fileLists.imgPlate;

imgSize = [1024 1024];

%%
nVar = 500; % output preallocation size
meanTraction = zeros(nVar,1);
sumTractionX = zeros(nVar,1); % Magnitude of the sum of traction vectors projected on X (should be 0, as a quality control)
sumTractionY = zeros(nVar,1); % Magnitude of the sum of traction vectors projected on Y (should be 0, as a quality control)
strainEnergy = zeros(nVar,1); % Force dot displacement
cellAreaExp = zeros(nVar,1);
cellAreaTight = zeros(nVar,1);
cellRoundness = zeros(nVar,1); % Cell roundness, 4pi*Area/(perimiter)^2. This is a flawed measure as it will be mostly influenced by protrusions.
imgIndex = zeros(nVar,1);
imgName = strings(nVar,1);
batchIndex = zeros(nVar,1);
cellIndex = zeros(nVar,1);
plateIndex = zeros(nVar, 1);
cellAreaExpRad = zeros(nVar,1);
condition = strings(nVar,1);
batch = strings(nVar,1);
nextResult = 1;

%%
for iImg = 1:length(mdFileNames)
    %%
    disp(['Working on ' char(mdFileNames(iImg))]);
    %%
    load(mdFileNames(iImg));
    iEsrp = MD.getProcessIndex('EfficientSubpixelRegistrationProcess');
    iDfcp = MD.getProcessIndex('DisplacementFieldCorrectionProcess');
    iFfcp = MD.getProcessIndex('ForceFieldCalculationProcess');
    thisImgName = imgNames(iImg);
    %%
    if(isempty(iEsrp) || iEsrp<1)
        warning(strcat(thisImgName, ' is missing a process!'));
        continue;
    end
    if(isempty(iFfcp) || iFfcp<1)
        warning(strcat(thisImgName, ' is missing a process!'));
        continue;
    end
    
    %% Stress
    lf = load(MD.processes_{iFfcp}.outFilePaths_{2}); % Traction stress in Pa
    tMap = lf.tMap{1};
    tMapX = lf.tMapX{1};
    tMapY = lf.tMapY{1};
    
    %% Displacement
    lf = load(MD.processes_{iDfcp}.outFilePaths_{2}); % Displacement in Px
    dMap = lf.dMap{1};
    dMapX = lf.dMapX{1};
    dMapY = lf.dMapY{1};
    
    %% Strain energy map (strain energy at each px)
    seMap = 0.5 .* (tMapX .* dMapX + tMapY .* dMapY); % 1/2 * area integral of stress dot displacement
    
    %% Registration
    lf = load(MD.processes_{iEsrp}.outFilePaths_{3,1});
    registration = lf.T;
    
    %% Cell masks
    ROI = bnGetMasksFromRoiSvg(cellROIs(iImg), imgSize); % ROI masks
    if isempty(ROI)
        continue; % No ROI in this image
    end
    ROIt = imtranslate(ROI, flip(registration), 'nearest');
    
    %%
    nROI = size(ROIt, 3);
    ROIc = cell(1, nROI);
    ROIcc = zeros(size(ROIt, [1 2]));
    for(iROI = 1 : nROI) % Loop through each ROI (cell)
        anyROI = sum(ROIt, 3) > 0;
        thisROI = ROIt(:, :, iROI) > 0;
        otherROI = anyROI & ~thisROI;
        for iParam = 1:1 % Loop through each ROI dilation
            rROIexp = 0; %(iParam - 1) * 10;
            thisROId = imdilate(thisROI, strel('disk', rROIexp, 4)); % dilate
            ROIc{iROI} = thisROId & ~otherROI; % Exclude other ROIs
            ROIcc(ROIc{iROI}) = iROI;
            % ROI roundness
            [B, ~] = bwboundaries(ROIc{iROI}, 'noholes');
            ROIperim = sum(sqrt(sum(diff(B{:}).^2, 2)));
            %
            cellAreaExp(nextResult) = sum(ROIc{iROI}(:));
            cellAreaTight(nextResult) = sum(thisROI(:));
            meanTraction(nextResult) = mean(tMap(ROIc{iROI}),'omitnan'); % Pa
            sumTractionX(nextResult) = sum(tMapX(ROIc{iROI}), 'all');    % Pa
            sumTractionY(nextResult) = sum(tMapY(ROIc{iROI}), 'all');    % Pa
            strainEnergy(nextResult) = sum(seMap(ROIc{iROI}), 'all');  % To convert to J, multiply by (m/px)^3
            cellRoundness(nextResult) = 4*pi*cellAreaTight(nextResult)/ROIperim^2; % 4pi*Area/(perimiter)^2, no units
            imgIndex(nextResult) = iImg;
            cellIndex(nextResult) = iROI;
            batchIndex(nextResult) = 1;
            plateIndex(nextResult) = imgPlates(iImg);
            cellAreaExpRad(nextResult) = rROIexp;
            imgName(nextResult) = thisImgName;
            condition(nextResult) = cellLines(iImg);
            nextResult = nextResult + 1;
        end
    end
end

%%
cellAreaExp_um2 = cellAreaExp .* um_Px .* um_Px;
cellAreaTight_um2 = cellAreaTight .* um_Px .* um_Px;
strainEnergy_J = strainEnergy .* ((um_Px*1e-6)^3);
strainEnergyDensity_nJ_mm2 = strainEnergy_J .* 1e9 ./ cellAreaExp_um2 .* 1e6;

%%
T = table(meanTraction, cellAreaExp, cellAreaTight, imgIndex, imgName, ...
    cellIndex, batchIndex, plateIndex, cellAreaExpRad, ...
    sumTractionX, sumTractionY, strainEnergy, condition, ...
    cellRoundness, ...
    cellAreaExp_um2, cellAreaTight_um2, strainEnergy_J, strainEnergyDensity_nJ_mm2);
goodResults = imgIndex > 0;
T = T(goodResults, :);
writetable(T, outCsv);
