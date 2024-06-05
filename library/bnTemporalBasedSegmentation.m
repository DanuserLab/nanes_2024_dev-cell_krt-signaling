function [] = bnTemporalBasedSegmentation(MD, Cind, params, dirs, varargin)

    ip = inputParser;
    addParameter(ip, 'doTexture', true, @islogical); % Use texture based segmentation for first frame (default, true)?
    addParameter(ip, 'preproc', @(x) x, @(x) true); % Pre-processing function for image
    addParameter(ip, 'altTextureFxn', false); % Alternative texture segmentation function for first frame
    parse(ip, varargin{:});
    doTexture = ip.Results.doTexture;
    preproc = ip.Results.preproc;
    altTextureFxn = ip.Results.altTextureFxn;
    lbpMapping = getmapping(8,'riu2');

    for t = 1 : params.nTime

        roiFname = [dirs.roiData 'C' num2str(Cind) '_' sprintf('%03d',t) '_roi.mat'];

        if exist(roiFname,'file') && ~params.always
            load(roiFname);
            prevRoi = ROI;
            clear ROI;
            fprintf(sprintf('fetching segmentation frame %d\n',t));
            continue;
        end

        if exist('prevRoi','var') && sum(~prevRoi(:)) < 500
            ROI = false(size(prevRoi));
            prevRoi = ROI;
            save(roiFname,'ROI');
            fprintf(sprintf('segmentation frame - small ROI stay with previous one %d\n',t));
            continue;
        end

        fprintf(sprintf('segmentation frame %d\n',t));

        mfFname = [dirs.mfData 'C' num2str(Cind) '_' sprintf('%03d',t) '_mf.mat'];
        load(mfFname); % scores

        % Threhold the matching score
        scores1 = scores(~isnan(scores));
        scores2 = 1 - scores1;
        percentile2 = prctile(scores2(:),2);
        percentile98 = prctile(scores2(:),98);
        %     centers = 0 : 0.00001 : 0.001;
        centers = percentile2:(percentile98-percentile2)/100:percentile98;
        
        assert(percentile98~=percentile2);

        [nelements, centers] = hist(scores2,centers);
        [~,thMatching] =  cutFirstHistMode(nelements,centers,0); % rosin threshold
        scoresNoNans = inpaint_nans(scores,4);
        BIN = scoresNoNans < 1 - thMatching;

        % fill holes, select largest ROI and intersect with previous ROI
        roiMatching = fillRoiHoles(BIN);
        roiMatching = erode(roiMatching,params.patchSize);

        % First time go on the safe side and use two segmentations
        if ~exist('prevRoi','var') && doTexture
            I = MD.getChannel(Cind).loadImage(t, 1);
            if ~params.isDx
                I = rot90(I);
            end
            I = preproc(I);
            if(~(islogical(altTextureFxn) && ~altTextureFxn))
                curRoi = altTextureFxn(I);
            else
                [roiTexture,tmp] = segmentPhaseContrastLBPKmeans(I,params.patchSize,lbpMapping);
            
                if sum(roiTexture(:)) < 1.2 * sum(roiMatching(:))
                
                    % UGLY PATCH - switching roiTexture if necessary. This should be
                    % solved in segmentPhaseContrastLBPKmeans!!
                    
                    roiCombined = imfill(roiMatching | roiTexture,'holes');
                    roiCombined = morphClose(roiCombined,2*params.patchSize+1);
                    roiCombined = fillRoiHoles(roiCombined);
                    curRoi = discardExcesses(roiCombined,params);
                else
                    curRoi = roiMatching;
                end
            end
        else
            curRoi = roiMatching;
        end

        if ~exist('prevRoi','var')
            prevRoi = true(size(scores));
        end

        changeRadius = ceil(params.searchRadiusInPixels * 2); % *2 if under segmentation
        ROI = (curRoi & dilate(prevRoi,changeRadius));
        if sum(prevRoi(:)) ~= size(prevRoi,1)*size(prevRoi,2)
            ROI = ROI | prevRoi;
        end

        ROI = morphClose(ROI,2*params.patchSize+1);
        ROI = discardExcesses(ROI,params);
        ROI = imfill(ROI,'holes');

        save(roiFname,'ROI');
    
        prevRoi = ROI;

    end

end

%%
function [out] = fillRoiHoles(in)
    out = in;
    
    tmp = in;
    tmp(:,1) = true;
    tmp(end,:) = true;
    tmp = imfill(tmp,'holes');
    tmp = morphClose(tmp,3);
    out = out | tmp;
    
    tmp = in;
    tmp(end,:) = true;
    tmp(:,end) = true;
    tmp = imfill(tmp,'holes');
    tmp = morphClose(tmp,3);
    out = out | tmp;
    
    tmp = in;
    tmp(:,end) = true;
    tmp(1,:) = true;
    tmp = imfill(tmp,'holes');
    tmp = morphClose(tmp,3);
    out = out | tmp;
    
    tmp = in;
    tmp(1,:) = true;
    tmp(:,1) = true;
    tmp = imfill(tmp,'holes');
    tmp = morphClose(tmp,3);
    out = out | tmp;
    
    % [L,nL] = bwlabel(out,8);
    % 
    % out = false(size(out));
    % for i = 1 : nL
    %     cur = L == i;
    %     if (sum(cur(:)) > sum(out(:)))
    %         out = cur;
    %     end
    % end
end
    
%% discardExcesses - finds 1/2 ROIS
function [curRoi] = discardExcesses(roi,params)
    [L,nL] = bwlabel(roi);
    curRoi = false(size(roi));
    curRoiSize = 0;
    curRoi2 = false(size(roi));
    curRoiSize2 = 0;
    for l = 1 : nL
        CC = (L == l);
        if (sum(CC(:)) > curRoiSize)
            tmpRoi = curRoi;
            tmpRoiSize = curRoiSize;
            curRoiSize = sum(CC(:));
            curRoi = CC;
            % for 2nd ROI        
            if ((tmpRoiSize > 0.3 * curRoiSize) && (~isfield(params,'nRois') || params.nRois == 2))
                curRoi2 = tmpRoi;
            else
                curRoi2 = false(size(roi));
            end
            curRoiSize2 = sum(curRoi2(:));
        else
            if ((sum(CC(:)) > 0.3 * curRoiSize) && (~isfield(params,'nRois') || params.nRois == 2))
                if curRoiSize2 > 0
                    warning('more than 2 ROIs?');
                else
                    curRoi2 = CC;
                    curRoiSize2 = sum(CC(:));
                end
            end
        end
    end
    if (curRoiSize2 > 0.3 * curRoiSize)
        curRoi = curRoi | curRoi2;
    end
end
    
%% UTILS
function [Aer] = erode(A,maskSize)
    
    if nargin < 2
        error('whTemporalBasedSegmentation: erode missing mask size');
    end
    
    mask = ones(maskSize);
    se1 = strel(mask);
    
    Aer = imerode(A,se1);
    
    end
    
    function [Aer] = dilate(A,maskSize)
    
    if nargin < 2
        error('whTemporalBasedSegmentation: dilate missing mask size');
    end
    
    mask = ones(maskSize);
    se1 = strel(mask);
    
    Aer = imdilate(A,se1);
    
end
