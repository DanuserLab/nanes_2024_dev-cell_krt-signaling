function RGB = bnRGBoverlay(RGB, M, r, g, b)
%bnRGBoverlay - Overlay a mask on an RGB image using a color
%
% Syntax: RGB = bnRGBoverlay(RGB, M, r, g, b)
%               bnRGBoverlay(__, 0, 62, 255)
%
% Assumes RGB and M have the same width and height
    U = bnRGBfromSinglet(M, r, g, b);
    V = repmat(M > 0, 1, 1, 3);
    RGB(V) = 0;
    RGB = RGB + U;
end
