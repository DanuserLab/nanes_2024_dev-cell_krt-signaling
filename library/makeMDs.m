%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%
%%  Create MovieData classes which organize image data, metadeta,
%%  and analyses. This step is required for each of the routines
%%  in this repository.
%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%%
eDir = '/project/directory/'; % Set this
mdDir = [eDir 'MDs/'];
imgFiles = ["image1.tif" "image2.tif"]; % Set this
imgNames = ["image1" "image2"]; % Set this, probably programatically

%%
nImages = length(imgFiles);

for iImg = 1 : nImages
    %%
    MD = MovieData(char(imgFiles(iImg)), [meDir char(imgNames(iImg))]);
    % May or may not need to set channel metadeta manually depending on file type
    c2 = MD.channels_(1);
    c2.emissionWavelength_=509;
    c2.excitationWavelength_=488;
    c1 = MD.channels_(2);
    c1.emissionWavelength_=670;
    c1.excitationWavelength_=642;
    MD.pixelSize_ = 162.5;
    MD.pixelSizeZ_ = 300;
    MD.timeInterval_ = 1;
    MD.numAperture_=1.515;
    MD.camBitdepth_=16;
    MD.sanityCheck;
    MD.save;
    MD.reset; % clean up processes_ and packages_
end
