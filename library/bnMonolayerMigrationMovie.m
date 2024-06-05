function [] = bnMonolayerMigrationMovie(MD, Cind, params, dirs)

    fprintf('start segmentation movie\n');

    segmentationFname = [dirs.segmentation MD.movieDataFileName_ '_C' num2str(Cind) '_segmentation.avi'];

    if exist(segmentationFname,'file') && ~params.always
        return;
    end

    vwriter = VideoWriter(segmentationFname, 'Motion JPEG AVI');
    vwriter.FrameRate = 12;
    open(vwriter);

    W = nan; H = nan;

    for t = 1 : params.nTime
        load([dirs.roiData 'C' num2str(Cind) '_' sprintf('%03d',t) '_roi.mat']); % ROI
        I = MD.getChannel(Cind).loadImage(t, 1);
        if ~params.isDx
            I = rot90(I);
        end

        perimWidth = round(max(size(I)) / 200);
        I(dilate(bwperim(ROI,8),perimWidth)) = max(255,max(I(:)));

        I = bnRGBify(I);
        writeVideo(vwriter, I);
    end
    close(vwriter);
    fprintf('finish segmentation movie\n');
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
