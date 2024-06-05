%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Extract a table of monolayer areas, most
%%  useful for calculating distance closed.
%%  Requires running the MonolayerKymographs package.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Setup
eDir = '/project/directory/'; % Set this
indexFile = 'MDindex-combined.mat'; % Index file containing list of MovieData files to process.
load([eDir indexFile]);
minDist = 10; % um
maxDist = 200; % um
nMovie = length(mdFileNames);
stem = 'movieFileNamePattern'; % Adjust this
nFrames = 100; % Adjust this

rois = getRoiAreas(getRoiFile(eDir,stem,nMovie,nFrames));

writematrix(rois, [eDir 'area_table.csv']);
% File name, image index, frame, area

%%
function fileTable = getRoiFile(eDir, stem, n, f) % File name, image index, frame
    fileNames = strings(n*f,1);
    imageIndex = strings(n*f,1);
    frameIndex = strings(n*f,1);
    for(ni = 1:n)
        for(fi = 1:f)
            fileNames((ni-1)*f+fi) = strcat(eDir, stem, sprintf('%d',ni), '/ROI/roi/', sprintf('%03d',fi), '_roi.mat');
            imageIndex((ni-1)*f+fi) = num2str(ni);
            frameIndex((ni-1)*f+fi) = num2str(fi);
        end
    end
    fileTable = cat(2, fileNames, imageIndex, frameIndex);
end

function areaTable = getRoiAreas(roiTable) % File name, image index, frame, area
    areas = strings(length(roiTable),1);
    for(i = 1:length(roiTable))
        lf = load(roiTable(i,1));
        areas(i) = num2str(sum(lf.ROI, 'all'));
    end
    areaTable = cat(2, roiTable, areas);
end
