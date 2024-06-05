function RGB = bnRGBfromSinglet(I, r, g, b)
%bnRGBfromSinglet - Turn a single-channel image into a single-color gradient RGB image
%
% Syntax: RGB = bnRGBfromSinglet(I, r, g, b)
%               bnRGBfromSinglet(__, 10, 100, 255)
%
% TODO

    if(islogical(I))
        R = zeros(size(I));
        G = R;
        B = R;
        R(I) = r;
        G(I) = g;
        B(I) = b;
    else
        R = I .* r;
        G = I .* g;
        B = I .* b;
    end
    RGB = uint8(cat(3, R, G, B));
    
end