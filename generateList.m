% Generating more bounding boxes using ground truth list file
% It first uses region proposals to generate more samples,
% and if the number is not enough, it generates more randomly
% Read XXX_grountTruth.txt which contains the bounding box for ground truths
% Output XXX_list.txt which is the augmented version of list,
% used for cropImg subsequently

addpath('rp-master/matlab');
addpath('rp-master/cmex');

configFile = 'rp-master/config/rp_4segs.mat'; 
configParams = LoadConfigFile(configFile);

% Change   the parameters below:
% class:   XXX is replaced with class
% label:   label of class
% samples: number of samples you want to generate per ground truth
%          the final number of samples is (num_of_grount_truth) x samples
class = 'trachea';
clabel = 3;
samples = 25;

% Read image names and ground truths
[name, y0, x0, y1, x1, label] = textread('trachea_groundTruth.txt', '%s %d %d %d %d %d');

N = size(name, 1);
fid=fopen('trachea_list.txt', 'w');

for i=1:N
	if label ~= clabel
		continue;
	end
	goods = [];
	I = imread([class '/' name{i}]);
	gt = [x0(i), y0(i), x1(i), y1(i)];
	% generating proposals
	proposals = RP(I, configParams);
	
	% check overlap region
	ind = overlap(proposals, gt, 0.5);
	goods = [gt; proposals(ind,:)];
	
	% if there are not enough samples,
	% generate more randomly
	while(size(goods,1) < samples)
		newbbox = generateBbox(gt);
		ind = overlap(newbbox, gt);
		goods = [goods; newbbox(ind,:)];
	end
	for j = 1:samples
		fprintf(fid, '%s %d %d %d %d %d\n', [class '/' name{i}], goods(j,2), goods(j,1), goods(j,4), goods(j,3), label);
	end
	fprintf('Process %d/%d\n', i, N);
end
  
fclose(fid);