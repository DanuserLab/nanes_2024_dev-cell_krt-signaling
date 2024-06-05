%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Conveniece function to prepare file lists for
%%  the u-inferforce (TFM) package.
%%  See: https://github.com/DanuserLab/u-inferforce
%%  Based on Han et al., Nature Methods, 2015
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function fileLists = getFileLists()

%%
eDir = '/project/directory/'; % Set this
imgDir = '../raw/';
mdDir = 'MDs/';
refTifDir = 'refTif/';
slideSetTab = 'slideset.xml'; % This example uses Slide Set (https://github.com/bnanes/slideset) to organize cell ROI masks
fileLists.eDir = eDir;
fileLists.imgDir = [eDir imgDir];
fileLists.mdDir = [eDir mdDir];
fileLists.refTifDir = [eDir refTifDir];
fileLists.slideSetTab = [eDir slideSetTab];

%%
imgFiles = ['imagefile.tiff']; % Set this by hand or programatically
fileLists.imgFiles = imgFiles;

cellLine = repmat("MyCells", length(imgFiles), 1);
fileLists.cellLine = cellLine;

imgName = regexp(imgFiles, "(?<=.+raw/).+(?=\.tiff)", 'match');
imgName = [imgName{:}]';
fileLists.imgName = imgName;

imgPlate = regexp(imgFiles, "(?<=.+raw/plate-).+(?=-pre_)", 'match');
imgPlate = [imgPlate{:}]';
fileLists.imgPlate = imgPlate;

%%
beadsImgFiles = ['imagefile_postBleach.tiff']; % Set this by hand or programatically
fileLists.beadsImgFiles = beadsImgFiles;

beadsImgName = regexp(imgFiles, "(?<=.+raw/).+(?=\.tiff)", 'match');
beadsImgName = [beadsImgName{:}]';
fileLists.beadsImgName = beadsImgName;

refTif = strcat(eDir, refTifDir, beadsImgName, '.tif'); % If reference images are not already TIFFs, they need to be converted
fileLists.refTif = refTif;

%% MD dirs and file names, to match bfImport.m
mdDirs = strcat(eDir, mdDir, imgName); 
fileLists.mdDirs = mdDirs;

[~, movieName, movieExt] = fileparts(imgFiles);
for i = 1 : length(movieName)
    token = regexp(char(strcat(movieName(i),movieExt(i))), '^(.+)\.ome\.tiff{0,1}$', 'tokens');
    if ~isempty(token)
        movieName(i) = string(token{1}{1});
    end
end
mdFileNames = strcat(movieName, ".mat");
mdFullFileNames = strcat(mdDirs, "/", mdFileNames);
fileLists.mdFileNames = mdFileNames;
fileLists.mdFullFileNames = mdFullFileNames;

%% MD dirs and file names for beads images, to match bfImport.m
mdDirsBeads = strcat(eDir, mdDir, beadsImgName); 
fileLists.mdDirsBeads = mdDirsBeads;

[~, movieName, movieExt] = fileparts(beadsImgFiles);
for i = 1 : length(movieName)
    token = regexp(char(strcat(movieName(i),movieExt(i))), '^(.+)\.ome\.tiff{0,1}$', 'tokens');
    if ~isempty(token)
        movieName(i) = string(token{1}{1});
    end
end
mdFileNamesBeads = strcat(movieName, ".mat");
mdFullFileNamesBeads = strcat(mdDirsBeads, "/", mdFileNamesBeads);
fileLists.mdFileNamesBeads = mdFileNamesBeads;
fileLists.mdFullFileNamesBeads = mdFullFileNamesBeads;

%%
ssImg = bnGetSlidesetTableColumn(char(fileLists.slideSetTab), 'Data', 'Img')';
ssImgName = regexp(ssImg, "(?<=.+raw/).+(?=\.dv)", 'match');
ssImgName = [ssImgName{:}]';
ssRoi = bnGetSlidesetTableColumn(char(fileLists.slideSetTab), 'Data', 'Cells')';
cellROIs = strings(length(imgName),1);
for i = 1 : length(ssImg)
    cellROIs(contains(imgFiles, ssImgName(i))) = ssRoi(i);
end
cellROIs = strcat(eDir, cellROIs);
fileLists.cellROIs = cellROIs;

end
