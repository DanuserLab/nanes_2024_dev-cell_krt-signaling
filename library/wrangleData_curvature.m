%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Extract tabular data related to static filament
%%  network properties after running the u-delineate package.
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
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex.mat';
load([eDir indexFile]);
% This example uses Slide Set (https://github.com/bnanes/slideset) to organize 
% image MovieData files and associated ROIs marking cell areas. See other scripts
% in this repository for alternate organization strategies.

%% Set up paths
dList = string(zeros(1,length(mdFileNames)));
fList = string(zeros(1,length(mdFileNames)));
eList = string(zeros(1,length(mdFileNames)));
f2List = string(zeros(1,length(mdFileNames)));
for i = 1:length(mdFileNames)
    [filepath,name,ext] = fileparts(mdFileNames(i));
    dList(i) = filepath;
    fList(i) = name;
    eList(i) = ext;
    [p0, p1] = regexp(name, '(?<=\d_s)0(?=\d$)');
    if(p0 > 0)
        f2List(i) = replaceBetween(name, p0, p1, '');
    else
        f2List(i) = name;
    end
end

fapC1 = "/FilamentAnalysisPackage/FilamentSegmentation/Channel1/";
C1segBin = string(zeros(1,length(mdFileNames)));
C1dat = string(zeros(1,length(mdFileNames)));
C1curveOut = string(zeros(1,length(mdFileNames)));
missingImage = "";
for i = 1:length(mdFileNames)
    C1segBin(i) = strcat(dList(i), fapC1, "segment_binary_", f2List(i), "_c1_t1.tif");
    if(~isfile(C1segBin(i))); C1segBin(i) = missingImage; end
    C1dat(i) = strcat(dList(i), fapC1, "DataOutput/filament_seg_", f2List(i), "_c1_t1.mat");
    C1curveOut(i) = strcat(dList(i), fapC1, "DataOutput/filament_curve_", f2List(i), "_c1_t1.mat");
end

%% Run the calculation
parfor iImg = 1:length(mdFileNames)
    makeCurveMap(C1dat(iImg), [2048 2048], C1curveOut(iImg), 5, 5);
end

%% Wrangle
ROIfiles = bnGetSlidesetTableColumn([eDir 'slideset-table.xml'], 'Data', 'cells');
ROIfiles = strcat(eDir, ROIfiles);
Krt = bnGetSlidesetTableColumn([eDir 'slideset-table.xml'], 'Data', 'chan1');
cellMeanCurve = NaN(200,1);
cellMedCurve = NaN(200,1);
cellKrt = strings(200,1);
cellInd = NaN(200,1);
dims = [2048 2048];

%%
iRow = 1;
for iImg = 1 : length(mdFileNames)
    load(C1curveOut(iImg));
    M = bnGetMasksFromRoiSvg(ROIfiles(iImg), dims);
    for iCell = 1 : size(M,3)
        U = M(:,:,iCell);
        cellMeanCurve(iRow) = mean(abs(Kimage(U>0)), 'all', 'omitnan');
        cellMedCurve(iRow) = median(abs(Kimage(U>0)), 'all', 'omitnan');
        cellKrt(iRow) = Krt(iImg);
        cellInd(iRow) = iImg;
        iRow = iRow + 1;
    end
end

T = table(cellInd, cellKrt, cellMeanCurve, cellMedCurve);
T = T(1:iRow-1,:);
writetable(T, [eDir 'csv/curvature.csv']);

%% Visualise
for iImg = 1 : length(mdFileNames)
    %%
    load(C1curveOut(iImg));
    Kimage = abs(Kimage);
    Kimage(isnan(Kimage)) = -100;
    Kdil = imdilate(Kimage, strel("square",2));
    Kdil(Kdil<0) = NaN;
    RGB = bnRGBify(Kdil, 'rel', [0.1,0.9], 'colormap', "Viridis");
    RGB(isnan(repmat(Kdil,1,1,3))) = 128;
    outfile = strcat(eDir, 'jpg/curvature/', f2List(iImg), '_curvature.png');
    imwrite(RGB, outfile);
end

%%
load(C1curveOut(1));
h = imagesc(abs(Kimage));
set(h,'alphadata',~isnan(Kimage));
caxis(quantile(abs(Kimage),[0.1,0.9],'all'));
colorbar;
set(gca,'color','#999') 

%%
function [] = makeCurveMap(filDatFile, dims, outFile, segRadius, order)
%makeCurveMap Create and save a filament curvature map
%   
%   Calculate a matrix of local curvature values along segmented filaments.
%   Inputs:
%   filDatFile - File name of Matlab data file containing the filament segmentation
%       output from the filament analysis package. See below for format.
%   dims - Dimensions of the underlying image, numeric array
%   outFile - File name of Matlab data file to save with the result.
%   segRadius - Size of filament segments for curvature calculations
%   order - Order for polynomial fits for curvature calculations
%
%   Example:
%   makeCurveMap('segModel.mat', [2048 2048], 'curveMap.mat', 5, 7);
%
%   Input data format:
%       current_model, Nx1 cell array, where each cell contains a Px2
%           numeric matrix of P points in the filament
%   Output data:
%       Kimage, numeric matrix of curvature values, or NaN in pixels
%           without a filament
%
%   Curvature calculation:
%   For each point on a filament, fit a polynomial of specified order
%   to the filament segment extending +/- `segRadius` points in both
%   directions. Curvature measure comes from
%   https://github.com/mattools/matGeom.
%
%   Benjamin Nanes 2021
%%
    load(filDatFile, 'current_model');
    Kimage = NaN(dims);
    for iFil = 1:size(current_model,1)
        fil = current_model{iFil};
        K = zeros(size(fil,1),1);
        for i = 2:(length(K)-1)
            pMin = max(1, i-segRadius);
            pMax = min(length(K), i+segRadius);
            U = fil(pMin:pMax, :);
            Kseg = curvature(U, 'polynom', order);
            K(i) = Kseg(i-pMin+1);
            Kimage(round(fil(i,2)),round(fil(i,1))) = K(i);
        end
    end
    save(outFile, 'Kimage');
end

