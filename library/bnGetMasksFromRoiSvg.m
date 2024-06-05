function masks = bnGetMasksFromRoiSvg(fileName, dims)
%bnGetMasksFromRoiSvg - Get binary masks coresponding to ROIs in an SVG file
%
% Syntax: masks = bnGetMasksFromRoiSvg(fileName, dims)
%
% Create binary image masks from polygon ROIs in an SVG file, such as those
% created with Slide Set. Returns a matrix with the mask of each ROI stacked
% along the z axis. Only works for polygon ROIs at the moment.
%
% Benjamin Nanes 2021

    DOM = xmlread(fileName);
    ROIs = DOM.getElementsByTagName('polygon');
    masks = zeros([dims ROIs.getLength()]);
    for iPoly = 0 : (ROIs.getLength()-1)
        ROI = ROIs.item(iPoly);
        Ps = ROI.getAttributes().getNamedItem('points').getNodeValue();
        Ps = strsplit(strtrim(char(Ps)));
        P = zeros(length(Ps), 2);
        for(iPt = 1:length(Ps))
            U = strsplit(Ps{iPt},',');
            P(iPt,1) = str2double(U{1});
            P(iPt,2) = str2double(U{2});
        end
        masks(:,:,iPoly+1) = poly2mask(P(:,1), P(:,2), dims(1), dims(2));
    end

end