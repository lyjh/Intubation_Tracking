function annotate_image(bbox, im, frame, seq, k)
% ANNOTATE IMAGE
%   AUTH: Jaleel Salhi, jsalhi@umich.edu
%         John Hobart Kuhn, hkuhn@umich.edu
%         Professor Honglak Lee, honglak@eecs.umich.edu
%   DESC: Annotates an input image with bounding box. 
%
%   INPU: bbox = bounding box location
%         im = image to be annotated
%         frame = frame number
%         seq = tag number (not needed in single tracking)
%         k = number of frames per class (not needed in single tracking)
%
%   OUTP: out = annotated image handle
%
%

% init
s = '-';
cwidth = 2;

clf

imshow(im)
axis off;
color = 'red';

if nargin == 5
    if floor((seq-1)/(k+1))+1 == 1
        color = 'blue';
        label = 'epiglottis';
    elseif floor((seq-1)/(k+1))+1 == 2
        color = 'red';
        label = 'vocalcord';
    elseif floor((seq-1)/(k+1))+1 == 3
        color = 'green';
        label = 'trachea';
    elseif floor((seq-1)/(k+1))+1 == 4
        color = 'yellow';
        label = 'carina';
    end
end

no_detection = [0 0 0 0];

if bbox(1:4) ~= no_detection

    rectangle('position', [bbox(1), bbox(2), bbox(3)-bbox(1), bbox(4)-bbox(2)],'edgecolor', color, 'linewidth', cwidth, 'linestyle', s);
            
    if nargin == 5
        text('Position', [bbox(3) bbox(4)], 'string', sprintf('%s', label), 'color', 'black', 'FontSize', 14, 'FontWeight', 'Bold', 'BackgroundColor', 'white');
    end
end

%saveas(handle, sprintf('../tmp/%i', frame), 'jpg');
%close all;
%out = imread(sprintf('../tmp/%i.jpg', frame));

end