function [] = bnCorrectGlobalMotion(MD, Cind, params, dirs, varargin)

    ip = inputParser;
    addParameter(ip, 'preproc', @(x) x, @(x) true);
    parse(ip, varargin{:});
    preproc = ip.Results.preproc;

    correctMotionFname = [dirs.correctMotion MD.movieDataFileName_ 'C_' num2str(Cind) '_correctMotion.mat'];

    if exist(correctMotionFname,'file') && ~params.always
        return;
    end

    % move back to original files
    if exist([dirs.mfDataOrig 'C' num2str(Cind) '_001_mf.mat'],'file')    
        copyfile([dirs.mfDataOrig 'C' num2str(Cind) '*.mat'], dirs.mfData);
    end

    copyfile([dirs.mfData 'C' num2str(Cind) '*.mat'], dirs.mfDataOrig);

    correctionsDx = [];
    correctionsDy = [];
    medianPrecentDx = [];
    medianPrecentDy = [];

    for t = 1 : params.nTime
        mfFname = [dirs.mfData 'C' num2str(Cind) '_' sprintf('%03d',t) '_mf.mat'];
        roiFname = [dirs.roiData 'C' num2str(Cind) '_' sprintf('%03d',t) '_roi.mat'];

        fprintf(sprintf('correcting motion estimation frame %d\n',t));
    
        load(mfFname); % dxs, dys
        load(roiFname); % ROI

        [correctDx, medianPDx] = getCorrection(dxs,ROI);
        correctionsDx = [correctionsDx correctDx];
        medianPrecentDx = [medianPrecentDx medianPDx];

        [correctDy, medianPDy] = getCorrection(dys,ROI);
        correctionsDy = [correctionsDy correctDy];
        medianPrecentDy = [medianPrecentDy medianPDy];

        if abs(correctDx) > 0.5 || abs(correctDy) > 0.5
            I0 = MD.getChannel(Cind).loadImage(t, 1);
            I1 = MD.getChannel(Cind).loadImage(t+params.frameJump,1);
            if ~params.isDx
                I0 = rot90(I0);
                I1 = rot90(I1);
            end
            I0 = preproc(I0);
            I1 = preproc(I1);       
            [dydx, dys, dxs, scores] = blockMatching(I0, I1, params.patchSize,params.searchRadiusInPixels,true(size(I0)),round(correctDx),round(correctDy)); % block width, search radius,
        end

        dxs = dxs + correctDx;
        dys = dys + correctDy;
        save(mfFname,'dxs','dys','scores');

    end

    nCorrected = sum(abs(correctionsDx) > 0.5 | abs(correctionsDy) > 0.5);
    nCorrectedDx = sum(abs(correctionsDx) > 0.5);
    nCorrectedDy = sum(abs(correctionsDy) > 0.5);
    precentCorrected = nCorrected/length(correctionsDx);
    save(correctMotionFname,'correctionsDx','correctionsDy','medianPrecentDy','medianPrecentDx','nCorrected','nCorrectedDx','nCorrectedDy','precentCorrected');%,'transDx','transDy'

end

%%
% medianPDx - precent of patches in the median +- 1 range, should be high!
function [correctDx, medianPDx] = getCorrection(dxs,ROI)
    xsBackground = dxs(~ROI);
    xsBackground = xsBackground(~isnan(xsBackground));
    nXsBackground = length(xsBackground);
    medianXsBackground = median(xsBackground(:));
    
    sumMedian0 = sum(xsBackground == (medianXsBackground-1));
    sumMedian1 = sum(xsBackground == medianXsBackground);
    sumMedian2 = sum(xsBackground == (medianXsBackground+1));
    allSumMedian = sumMedian0 + sumMedian1 + sumMedian2;
    
    correctDx = 0;
    if (allSumMedian > 0.6 * nXsBackground)
        correctDx = -(((sumMedian0 * (medianXsBackground-1)) + (sumMedian1 * medianXsBackground) + (sumMedian2 * (medianXsBackground+1)))/allSumMedian);
    end
    
    medianPDx = allSumMedian/nXsBackground;
end
