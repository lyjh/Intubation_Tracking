% GET ALL IMAGES SCRIPT
%   DESC: This script will retrieve all frames from an avi video file and
%       will begin executing user-labelling. Annotation files and individual
%       labeled image files will be generated, which can then be used with the
%       VOC train/test code.
%   NOTE: Be sure to specifiy which video to use (denoted on line 15)

% change parameters below:
vid_name = '14.mp4';
class = 'epiglottis';
fid = fopen([class '_groundTruth.txt'], 'a');
label = 1;

d = dir('frames/*.jpg');
if size(d,1) == 0
	getFrames(vid_name);
	d = dir('frames/*.jpg');
end

N = size(d,1);

%Number of frames to jump each iteration
jumpSize = 5;

coords = [];
inter = zeros(N, 4);

for i = 1:jumpSize:N
	im = imread(['frames/' d(i).name]);
    imshow(im);
	promptMessage = sprintf(['Are the ' class ' showing?');
	%The first parameter in MFquestdlg (in brackets) specifies the
	%location of the dialog box. Play with this to make it easier to
	%view the frames while the dialog box is open. Numbers must be
	%between 0 and 1.
	button = MFquestdlg([0.8, 0.8], promptMessage, [class ' showing?','Yes');
	if strcmp(button, 'Yes')
		[x y] = ginput(2);
		x(1) = max(x(1), 1);
		x(2) = min(x(2), size(im,2));
		y(1) = max(y(1), 1);
		y(2) = min(y(2), size(im,1));
		rectangle('Position', [x(1), y(1), abs(x(2)-x(1)), abs(y(2)-y(1))], 'edgecolor', 'g');
		button2 = MFquestdlg([0.8, 0.8], 'Is this an appropriate bounding box?', 'Appropriate bounding box?','Yes');
		while strcmp(button2, 'No')
			close all
			imshow(im);
			[x, y] = ginput(2);
			x(1) = max(x(1), 1);
			x(2) = min(x(2), size(im,2));
			y(1) = max(y(1), 1);
			y(2) = min(y(2), size(im,1));
			rectangle('Position', [x(1), y(1), abs(x(2)-x(1)), abs(y(2)-y(1))], 'edgecolor', 'g');
			button2 = MFquestdlg([0.8, 0.8], 'Is this an appropriate bounding box?', 'Appropriate bounding box?','Yes');
		end
		if strcmp(button2, 'Yes')
			coords = [coords; i, x(1), y(1), x(2), y(2)];
		end
	end
	if strcmp(button, 'Cancel')
		break
	end
end

%Spline interpolation
for i = 1:size(coords, 1)
	if i < size(coords, 1)
		currentRow = coords(i, :);
		nextRow = coords(i+1, :);
	end

	if nextRow(1) - currentRow(1) == jumpSize
		x1 = interp1([currentRow(1); nextRow(1)], [currentRow(2); nextRow(2)], currentRow(1):nextRow(1))';
		y1 = interp1([currentRow(1); nextRow(1)], [currentRow(3); nextRow(3)], currentRow(1):nextRow(1))';
		x2 = interp1([currentRow(1); nextRow(1)], [currentRow(4); nextRow(4)], currentRow(1):nextRow(1))';
		y2 = interp1([currentRow(1); nextRow(1)], [currentRow(5); nextRow(5)], currentRow(1):nextRow(1))';

		inter(currentRow(1):nextRow(1), :) = [x1, y1, x2, y2];
	end
end

%Export all images (selected + interpolated) and generate XML files
for i = 1:N
	% if inter(i, 1) == 0 && inter(i, 2) == 0 && inter(i, 3) == 0 && inter(i, 4) == 0
		% im = imread(['frames/' d(i).name]);
		% flname = strcat(newVid, '_0_', sprintf('%04d', i), '.jpg');
		% imwrite(img, ['img/' flname], 'jpeg');
		% close all
		% GenerateNegativeLabels(inter(i, 1), inter(i, 2), inter(i, 3), inter(i, 4), flname);
	% else
		% im = imread(['frames/' d(i).name]);
		% flname = strcat(newVid, '_1_', sprintf('%04d', i), '.jpg');
		% imwrite(img, ['img/' flname], 'jpeg');
		% close all
		% GeneratePositiveLabels(inter(i, 1), inter(i, 2), inter(i, 3), inter(i, 4), flname);
	% end
	if inter(i,:) ~= [0 0 0 0]
		fprintf(fid, '%s %3d %3d %3d %3d %3d\n', d(i).name, inter(i,1), inter(i,2), inter(i,3), inter(i,4), label);
	else
		fprintf(fid, '%s %3d %3d %3d %3d %3d\n', d(i).name, 0,0,0,0,0);
	end
end
fclose(fid);