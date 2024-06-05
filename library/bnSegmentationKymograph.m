function tabDat = bnSegmentationKymograph(...
    segChan1, segChan2,...
    minDist, maxDist,...
    mdFileName, mdIndex,...
    roiDir, mfDir, coordDir)
%bnSegmentationKymograph Generate segmented kymograph-like data
%
%Inputs:
%   segChan1, segChan2 - Int 1-based indeces of the channels containing
%       segmentation data
%   minDist, maxDist - Numeric specification of the distance range (pixels)
%       from the wound edge to include. 
%       minDist <= included pixesl < maxDist
%   mdFileName - String of charachter path to the MD file containing the
%      segmentation data
%   mdIndex - Int indentifying index for the MD file to facilitate analysis
%      over multiple movies
%   roiDir - String or char directory containing ROI MAT files (ends c "/")
%   mfDir - Directory containing MF MAT files (ends c "/")
%   coordDir - Directory containing coordination MAT files (ends c "/")
%
%Output:
%   tabDat - Numeric array containg data in tabular form with the following
%       columns:
%           1, Movie index
%           2, Frame #
%           3, C1 high
%           4, C2 high
%           5, Speed
%           6, Directionality
%           7, Coordination
%           8, Area, in pixels
%           9, Angular change, in radians
%
    lf = load(mdFileName, 'MD');
    MD = lf.MD;
    nFrame = MD.nFrames_;
    nChan = MD.getDimensions();
    nChan = nChan(4);
    nProcess = numel(MD.processes_);
    iSegProc = 0;
    for iProc = 1:nProcess
       if(strcmp(MD.processes_{iProc}.getName,'Thresholding')==1)
           iSegProc = iProc;
           break;
       end
    end
    subtab = zeros((nFrame-1)*4, 9);
    curRow = 1;
    for t = 1:(nFrame-1)
        lf = load(strcat(roiDir, sprintf('%03d',t), '_roi.mat'), 'ROI'); % ROI
        ROI = lf.ROI;
        lf = load(strcat(mfDir, sprintf('%03d',t), '_mf.mat')); % dxs, dys
        dxs = lf.dxs;
        dys = lf.dys;
        lf = load(strcat(coordDir, sprintf('%03d',t), '_coordination.mat'), 'ROIclusters'); % ROIclusters
        ROIclusters = lf.ROIclusters;
        if(t < (nFrame-1))
            lf = load(strcat(mfDir, sprintf('%03d',t+1), '_mf.mat')); % dxs, dys
            dxs1 = lf.dxs;
            dys1 = lf.dys;
        else
            dxs1 = zeros(size(dxs));
            dys1 = zeros(size(dys));
        end
        clear lf;
        
        distance = bwdist(~ROI); % distance to wound edge
        inclDist = distance >= minDist & distance < maxDist;
        
        speed = sqrt(dxs.^2 + dys.^2);
        directionality = dxs ./ speed;
        
        segC2 = MD.processes_{iSegProc}.loadChannelOutput(segChan1,t);
        segC3 = MD.processes_{iSegProc}.loadChannelOutput(segChan2,t);
        
        speed1 = sqrt(dxs1.^2 + dys1.^2);
        ang0 = atan2(dys, dxs);
        ang1 = atan2(dys1, dxs1);
        ang0(speed < 0.5) = NaN;
        ang1(speed1 < 0.5) = NaN;
        dim = size(dxs);
        idxR = zeros(dim);
        idxC = zeros(dim);
        for ir = 1:dim(1)
            idxR(ir,:) = ir;
        end
        for ic = 1:dim(2)
            idxC(:,ic) = ic;
        end
        dys(isnan(dys)) = 0;
        dxs(isnan(dxs)) = 0;
        idxR = round(idxR + dys);
        idxC = round(idxC + dxs);
        idxR(idxR < 1) = 1;
        idxR(idxR > dim(1)) = dim(1);
        idxC(idxC < 1) = 1;
        idxC(idxC > dim(2)) = dim(2);
        angDiffMap = bnAngdiff(ang0, ang1(sub2ind(size(ang1),idxR,idxC)));
        
        subtab(curRow:curRow+3, 1) = mdIndex; % 1, Movie #
        subtab(curRow:curRow+3, 2) = t; % 2, Frame #
        subtab(curRow+0, 3) = 0; % 3, K5-mNG-high
        subtab(curRow+1, 3) = 1; % 3, K5-mNG-high
        subtab(curRow+2, 3) = 0; % 3, K5-mNG-high
        subtab(curRow+3, 3) = 1; % 3, K5-mNG-high
        subtab(curRow+0, 4) = 0; % 4, K6A-mRb-high
        subtab(curRow+1, 4) = 0; % 4, K6A-mRb-high
        subtab(curRow+2, 4) = 1; % 4, K6A-mRb-high
        subtab(curRow+3, 4) = 1; % 4, K6A-mRb-high
        for z = 0:3
            switch z
                case 0
                    segZ = ~segC2 & ~segC3;
                case 1
                    segZ = segC2 & ~segC3;
                case 2
                    segZ = ~segC2 & segC3;
                case 3
                    segZ = segC2 & segC3;
            end
            subtab(curRow+z, 5) = mean(speed(segZ & ROI & inclDist), 'omitnan'); % 5, Speed
            subtab(curRow+z, 6) = mean(directionality(segZ & ROI & inclDist), 'omitnan'); % 6, Directionality
            subtab(curRow+z, 7) = mean(ROIclusters(segZ & ROI & inclDist), 'omitnan'); % 7, Coordination
            subtab(curRow+z, 8) = sum(segZ & ROI & inclDist, 'all'); % 8, Area
            subtab(curRow+z, 9) = mean(angDiffMap(segZ & ROI & inclDist), 'omitnan'); % 9, Angular change, in radians
        end
        curRow = curRow + 4;
    end
    tabDat = subtab;
end

% Columns:
% 1, Movie #
% 2, Frame #
% 3, K5-mNG-high
% 4, K6A-mRb-high
% 5, Speed
% 6, Directionality
% 7, Coordination
% 8, Area, in pixels
% 9, Angular change, in radians
