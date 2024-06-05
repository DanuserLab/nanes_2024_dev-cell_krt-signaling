%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Extract tabular data after running the u-delineate package.
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
% This example uses Slide Set (https://github.com/bnanes/slideset) to organize 
% image MovieData files and associated ROIs marking cell areas. See other scripts
% in this repository for alternate organization strategies.
xmlInFile = [eDir 'slideset-table.xml'];
xmlOutFile = [eDir 'slideset-table-out.xml'];
csvOutFile = [eDir 'result.csv'];
missingImage = '!!!';

mdFileNames = bnGetSlidesetTableColumn(xmlInFile, "Data", "ImageMD");
mdDirs = bnGetSlidesetTableColumn(xmlInFile, "Data", "ImageMDdir");
sequenceIDs = bnGetSlidesetTableColumn(xmlInFile, "Data", "Sequence");
plateIDs = bnGetSlidesetTableColumn(xmlInFile, "Data", "Plate");
imgNames = bnGetSlidesetTableColumn(xmlInFile, "Data", "Name");
cellROIs = bnGetSlidesetTableColumn(xmlInFile, "Data", "ROI");
batches = bnGetSlidesetTableColumn(xmlInFile, "Data", "Batch");
cellLines = bnGetSlidesetTableColumn(xmlInFile, "Data", "Line");

f2List = regexp(mdDirs, '(?<=MDs/).+', 'match');
f2List = regexprep([f2List{:}], '(?<=_s)0(?=\d)', '');

%% Construct output data image lists
fapC1 = "/FilamentAnalysisPackage/FilamentSegmentation/Channel1/";
fapC2 = "/FilamentAnalysisPackage/FilamentSegmentation/Channel2/";
C1segBinT0 = string(zeros(1,length(mdFileNames)));
C1segBinT1 = string(zeros(1,length(mdFileNames)));
C1segBinT2 = string(zeros(1,length(mdFileNames)));
C1segBinT3 = string(zeros(1,length(mdFileNames)));
C1segBinT4 = string(zeros(1,length(mdFileNames)));
C1sim1 = string(zeros(1,length(mdFileNames)));
C1sim2 = string(zeros(1,length(mdFileNames)));
C1sim3 = string(zeros(1,length(mdFileNames)));
C1sim4 = string(zeros(1,length(mdFileNames)));
C2segBinT0 = string(zeros(1,length(mdFileNames)));
C2segBinT1 = string(zeros(1,length(mdFileNames)));
C2segBinT2 = string(zeros(1,length(mdFileNames)));
C2segBinT3 = string(zeros(1,length(mdFileNames)));
C2segBinT4 = string(zeros(1,length(mdFileNames)));
C2sim1 = string(zeros(1,length(mdFileNames)));
C2sim2 = string(zeros(1,length(mdFileNames)));
C2sim3 = string(zeros(1,length(mdFileNames)));
C2sim4 = string(zeros(1,length(mdFileNames)));
C1C2sim0 = string(zeros(1,length(mdFileNames)));
for i = 1:length(mdFileNames)
    C1segBinT0(i) = strcat(mdDirs(i), fapC1, "segment_binary_", f2List(i), "_c1_t1.tif");
    if(~isfile(C1segBinT0(i))); C1segBinT0(i) = missingImage; end
    C1segBinT1(i) = strcat(mdDirs(i), fapC1, "segment_binary_", f2List(i), "_c1_t2.tif");
    if(~isfile(C1segBinT1(i))); C1segBinT1(i) = missingImage; end
    C1segBinT2(i) = strcat(mdDirs(i), fapC1, "segment_binary_", f2List(i), "_c1_t3.tif");
    if(~isfile(C1segBinT2(i))); C1segBinT2(i) = missingImage; end
    C1segBinT3(i) = strcat(mdDirs(i), fapC1, "segment_binary_", f2List(i), "_c1_t4.tif");
    if(~isfile(C1segBinT3(i))); C1segBinT3(i) = missingImage; end
    C1segBinT4(i) = strcat(mdDirs(i), fapC1, "segment_binary_", f2List(i), "_c1_t5.tif");
    if(~isfile(C1segBinT4(i))); C1segBinT4(i) = missingImage; end
    C1sim1(i) = strcat(mdDirs(i), "/dt1c1dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C1sim1(i))); C1sim1(i) = missingImage; end
    C1sim2(i) = strcat(mdDirs(i), "/dt2c1dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C1sim2(i))); C1sim2(i) = missingImage; end
    C1sim3(i) = strcat(mdDirs(i), "/dt3c1dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C1sim3(i))); C1sim3(i) = missingImage; end
    C1sim4(i) = strcat(mdDirs(i), "/dt4c1dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C1sim4(i))); C1sim4(i) = missingImage; end
    C2segBinT0(i) = strcat(mdDirs(i), fapC2, "segment_binary_", fList(i), "_c2_t1.tif");
    if(~isfile(C2segBinT0(i))); C2segBinT0(i) = missingImage; end
    C2segBinT4(i) = strcat(mdDirs(i), fapC2, "segment_binary_", fList(i), "_c2_t5.tif");
    if(~isfile(C2segBinT4(i))); C2segBinT4(i) = missingImage; end
    C2sim1(i) = strcat(mdDirs(i), "/dt1c2dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C2sim1(i))); C2sim1(i) = missingImage; end
    C2sim2(i) = strcat(mdDirs(i), "/dt2c2dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C2sim2(i))); C2sim2(i) = missingImage; end
    C2sim3(i) = strcat(mdDirs(i), "/dt3c2dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C2sim3(i))); C2sim3(i) = missingImage; end
    C2sim4(i) = strcat(mdDirs(i), "/dt4c2dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C2sim4(i))); C2sim4(i) = missingImage; end
    C1C2sim0(i) = strcat(mdDirs(i), "/c1c2dynamics/Similarity_maps_frame1.tif");
    if(~isfile(C1C2sim0(i))); C1C2sim0(i) = missingImage; end
end

%% Prepare XML output
%  This example assumes segmentations on two channels
col1 = '<col name="';
col2 = '" elementClass="edu.emory.cellbio.ijbat.dm.FileLinkElement" mimeType="image">';
col3 = '</col>';

xmlInsert = '';

xmlInsert = strcat(xmlInsert, [col1 'C1segBinT0' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1segBinT0)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1segBinT1' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1segBinT1)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1segBinT2' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1segBinT2)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1segBinT3' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1segBinT3)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1segBinT4' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1segBinT4)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1sim1' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1sim1)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1sim2' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1sim2)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1sim3' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1sim3)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1sim4' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1sim4)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2segBinT0' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2segBinT0)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2segBinT4' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2segBinT4)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2sim1' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2sim1)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2sim2' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2sim2)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2sim3' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2sim3)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C2sim4' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C2sim4)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

xmlInsert = strcat(xmlInsert, [col1 'C1C2sim0' col2]);
xmlInsert = strcat(xmlInsert, '\n ', join(bnWrapXmlE(C1C2sim0)));
xmlInsert = strcat(xmlInsert, ['\n' col3 '\n\n']);

%% Write XML output
theXML = join(readlines(xmlInFile));
theXML = regexprep(theXML, '</SlideSet>', strcat(xmlInsert, ' </SlideSet>'));
fid = fopen(xmlOutFile, 'w+');
fprintf(fid, theXML);
fclose(fid);

%% Prepare the tabular output
%  This example assumes segmentations on one channel; extracting data from the second channel is a streightforward modification
nVar = 500; % output preallocation size
C1sim1score = zeros(nVar,1);
C1sim2score = zeros(nVar,1);
C1sim3score = zeros(nVar,1);
C1sim4score = zeros(nVar,1);
C1segDensityT0 = zeros(nVar,1);
cellArea = zeros(nVar,1);
imgIndex = zeros(nVar,1);
imgName = strings(nVar,1);
imgSequence = strings(nVar,1);
cellIndex = zeros(nVar,1);
krt = strings(nVar,1);
batch = strings(nVar,1);
nextResult = 1;

%%
for iImg = 1:length(mdFileNames)
    %%
    disp(['Working on ' char(mdFileNames(iImg))]);
    %%

    C1segBinT0image = imread(char(C1segBinT0(iImg)));
    C1sim1image = imread(char(C1sim1(iImg)));
    C1sim2image = imread(char(C1sim2(iImg)));
    C1sim3image = imread(char(C1sim3(iImg)));
    C1sim4image = imread(char(C1sim4(iImg)));

    ROI = bnGetMasksFromRoiSvg(cellROIs(iImg), [2048 2048]); % ROI masks; need to specify image dimensions
    if isempty(ROI)
        continue; % No ROI in this image
    end

    %%
    nROI = size(ROI, 3);
    ROIc = cell(1, nROI);
    ROIcc = zeros(size(ROI, [1 2]));
    for(iROI = 1 : nROI) % Loop through each ROI (cell)
        anyROI = sum(ROI, 3) > 0;
        thisROI = ROI(:, :, iROI) > 0;
        otherROI = anyROI & ~thisROI;

        C1sim1score(nextResult) = mean(C1sim1image(thisROI & C1sim1image>=5), 'omitnan');
        C1sim2score(nextResult) = mean(C1sim2image(thisROI & C1sim2image>=5), 'omitnan');
        C1sim3score(nextResult) = mean(C1sim3image(thisROI & C1sim3image>=5), 'omitnan');
        C1sim4score(nextResult) = mean(C1sim4image(thisROI & C1sim4image>=5), 'omitnan');
        C1segDensityT0(nextResult) = mean(C1segBinT0image(thisROI), 'omitnan');
        cellArea(nextResult) = sum(thisROI, 'all');
        imgIndex(nextResult) = iImg;
        imgName(nextResult) = imgNames(iImg);
        imgSequence(nextResult) = sequenceIDs(iImg);
        cellIndex(nextResult) = iROI;
        krt(nextResult) = cellLines(iImg);
        batch(nextResult) = batches(iImg);
        
        nextResult = nextResult + 1;  
    end
end

%%
T = table(C1sim1score,C1sim2score,C1sim3score,C1sim4score,C1segDensityT0,cellArea,imgIndex,imgName,imgSequence,cellIndex,krt,batch);
goodResults = imgIndex > 0;
T = T(goodResults, :);
writetable(T, csvOutFile);
