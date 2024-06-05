function U = bnFirstFrameSegmentationEEC(I)
%bnFirstFrameSegmentationEEC - Initial segmentation estimate for EEC migration (replaces texture-based estimate, which does not work so well here)
%
    [level, U] = thresholdOtsu(I);
    U = imfill(U, 'holes');
    [yMax, xMax] = size(U);
    [xGrid,yGrid] = meshgrid(1:xMax, 1:yMax);
    xMean = mean(xGrid(U>0), 'all');
    yMean = mean(yGrid(U>0), 'all');
    if(xMean < xMax/2) % L to R motion
        topRow = U(1,:);
        botRow = U(end,:);
        colNum = 1:xMax;
        topCorner = max(colNum(topRow>0));
        botCorner = max(colNum(botRow>0));
        tops = [repelem(1, topCorner-1); 1:(topCorner-1)].';
        bots = [repelem(yMax, botCorner-1); 1:(botCorner-1)].';
        backs = [1:yMax; repelem(1, yMax)].';
        edgePoints = vertcat(tops, bots, backs);
    else % R to L motion
        topRow = U(1,:);
        botRow = U(end,:);
        colNum = 1:xMax;
        topCorner = min(colNum(topRow>0));
        botCorner = min(colNum(botRow>0));
        tops = [repelem(1, xMax-topCorner); (topCorner+1):xMax].';
        bots = [repelem(yMax, xMax-botCorner); (botCorner+1):xMax].';
        backs = [1:yMax; repelem(xMax, yMax)].';
        edgePoints = vertcat(tops, bots, backs);
    end
    U = imfill(logical(U), edgePoints);
end
