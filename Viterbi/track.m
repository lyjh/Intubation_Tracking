function track(vid_feed_path, cl, k)
% TRACK
%   AUTH: Jaleel Salhi, jsalhi@umich.edu
%         John H. Kuhn, hkuhn@umich.edu
%         Professor Honglak Lee, honglak@eecs.umich.edu
%   DESC: Tracks an object defined by model through a video
%
%   INPU: model = DPM model struct previously trained
%         vid_feed_path = directory path where the video file is located
%         k = max number of boxes per frame
%
%   OUTP: detection_array = sequential box locations in all frames of video
%
%

% initialize paths
addpath('rp/matlab');
addpath('rp/cmex');
addpath('caffe')

configFile = 'rp/config/rp_4segs.mat'; 
configParams = LoadConfigFile(configFile);

% caffe initialization
use_gpu = true;
input_batch_size = 250;
input_size = 100;
model_def_file = './caffe/vocnet_deploy.prototxt';
model_file = '/mnt/neocortex/scratch/tsechiw/caffe/build/caffe_intunet_train_iter_140000';
% set the ID of GPU being used, e.g., 1
caffe('set_device', 1);
caffe('init', model_def_file, model_file);

if exist('use_gpu', 'var') && use_gpu
  caffe('set_mode_gpu');
else
  caffe('set_mode_cpu');
end

% put into test mode
caffe('set_phase_test');

% PARSE VIDEO
display(sprintf('\n-------------------------------------'));
display(sprintf('PROCESSING VIDEO'));
display(sprintf('-------------------------------------\n'));
display(sprintf('Specified path to feed data: %s', vid_feed_path));

% search directory for all frames    
d = dir([vid_feed_path '/*.jpg']);


% IMAGE PROCESSING
display(sprintf('\n-------------------------------------'));
display(sprintf('PROCESSING IMAGES'));
display(sprintf('-------------------------------------\n'));

try
    load '../tmp/bbox_data.mat'
    display('Bounding Box Locations Loaded...');
catch exception
    % For all frames:
    %   Evaluate model on frame
    %   Threshold number of bounding boxes to k (plus-1 for neg state)
    N = size(d, 1);
	% num_class x num_frame x num_bbox x 5
	bbox_cell_array = zeros(cl, N, k+1, 5);

    for i=1:N
        display(sprintf('Loading image: %d/%d', i, N));
        im = imread([vid_feed_path '/' d(i).name]);

        display('Evaluating model on frame');
		
		proposals = RP(im, configParams);
		proposals = checkRegion(proposals, 12, 12);
		
		scores_matrix = detect_cnn(im, proposals, input_size, input_batch_size, 5);
		[score_epi, idx_epi] = sort(scores_matrix(2,:)', 'descend');
		[score_voc, idx_voc] = sort(scores_matrix(3,:)', 'descend');
		[score_tra, idx_tra] = sort(scores_matrix(4,:)', 'descend');
		[score_car, idx_car] = sort(scores_matrix(5,:)', 'descend');

        bbox_epi = selectBbox(score_epi, idx_epi, proposals, k, 0.9);
		bbox_voc = selectBbox(score_voc, idx_voc, proposals, k, 0.9);
		bbox_tra = selectBbox(score_tra, idx_tra, proposals, k, 0.9);
		bbox_car = selectBbox(score_car, idx_car, proposals, k, 0.9);
        bbox_cell_array(1,i,:,:) = bbox_epi;
		bbox_cell_array(2,i,:,:) = bbox_voc;
		bbox_cell_array(3,i,:,:) = bbox_tra;
		bbox_cell_array(4,i,:,:) = bbox_car;
    end
    display(sprintf('Saving data to file...'));
    save('../tmp/bbox_data.mat', 'bbox_cell_array', 'k'); 
end   


% TRANSITION SCORING
display(sprintf('\n-------------------------------------'));
display(sprintf('TRANSITION SCORING'));
display(sprintf('-------------------------------------\n'));


try
    load '../tmp/trans_data.mat'
    display('Transition Scores Loaded...');
catch exception
    % For all frames:
    %   Compute transition score between frames
    %   Store all scores in a cell array
    N = length(bbox_cell_array);
    transition_score_cell_array = zeros(cl,N-1, k+1, k+1);

    % compute transition scores for all bbox pairs
	for c = 1:cl % for each class
		for i=1:N-1 % for each frame
			for ii=1:k+1 % for each bbox
				transition_score_cell_array(c,i,ii,:) = ...
					get_trans_score(bbox_cell_array(c,i,ii,:), bbox_cell_array(c,i+1,:,:))';
			end
		end
	end
    display(sprintf('Saving transition scores to file...'));
    save('../tmp/trans_data.mat', 'transition_score_cell_array'); 
end




% VITERBI SEQUENCING
display(sprintf('\n-------------------------------------'));
display(sprintf('VITERBI SEQUENCING'));
display(sprintf('-------------------------------------\n'));
            


% For all frames:
%   Compute the emissions values for all scores
%       Sigmoid Function for normalization of scores
display('Calculating Emissions Scores...');
N = length(bbox_cell_array);
emissions_cell_array = zeros(cl,N,k+1);

for c = 1:cl
	for i=1:N
		emissions_cell_array(c,i,:) = bbox_cell_array(c,i,:,5);
		emissions_cell_array(c,i,k+1) = 0;
	end
end


% run viterbi, retrieve sequence
display('Building Viterbi Algorithm...');
display('Calculating Optimal Sequence...');
try
    load('../tmp/hmm_data.mat');
catch exception
	seq = zeros(cl, N);
	for c = 1:cl
		seq(c,:) = viterbi(squeeze(transition_score_cell_array(c,:,:,:)), squeeze(emissions_cell_array(c,:,:)));
	end

	display('Saving HMM data to file...');
	save('../tmp/hmm_data.mat', 'seq');
end


% FINALIZE SEQUENCE
display(sprintf('\n-------------------------------------'));
display(sprintf('FINALIZING SEQUENCE'));
display(sprintf('-------------------------------------\n'));

% STEP 1: retrieve bounding box locations from tags in seq
% STEP 2: overlay bounding boxes onto each frame
% STEP 3: export all frames as video


% STEP 1: retrieve bounding box locations from tags in seq
% display('Retrieving bounding boxes from sequence tags...');
% detection_array = zeros(cl,N,5);

% for c = 1:cl
	% for i=1:N
		% detection_array(c,i,:) = bbox_cell_array(c,i,seq(c,i),:);
	% end
% end


% STEP 2: overlay bounding boxes onto each frame
display('Annotating Frames...');

h = figure;
set(h, 'visible', 'off');
hold on;
for c = 1:cl
	outputVideo = VideoWriter(fullfile('../output/',['track_out_' num2str(c) '.avi']));
	outputVideo.FrameRate = 25;%video.FrameRate;
	open(outputVideo);
	fid = fopen(['../output/dets_' num2str(c) '.txt'], 'w');
	for i=1:N
		display(sprintf('Annotating frame: %d/%d', i, N));
		im = imread([vid_feed_path '/' d(i).name]);
		
		det = squeeze(bbox_cell_array(c,i,seq(c,i),:))';
		
		annotate_image(det, im, i);
		F = getframe(h);
		
		writeVideo(outputVideo,F);
		fprintf(fid, '%s %.2f %3d %3d %3d %3d\n', [vid_feed_path '/' d(i).name], det(5), det(1), det(2), det(3), det(4));
	end
	close(outputVideo);
	fclose(fid);
end

display('Exporting Complete. Tracked video can be found at: ../output/track_out.avi');
display('Be sure to rename this file to give it significance and prevent it from being overwritten');
display('Closing Program...');

    
end

% ===========================================================
%   HELPER FUNCTIONS BELOW
% ===========================================================

% Reject proposals that are too small
function p = checkRegion(proposals, minw, minh)
	w = proposals(:, 3) - proposals(:, 1);
	h = proposals(:, 4) - proposals(:, 2);
	I = find(w >= minw & h >= minh);
	p = proposals(I, :);
end

function bbox = selectBbox(scores, index, proposals, k, threshold)
	num = length(find(scores >= threshold));
	% if there are more than k regions have scores greater than threshold,
	% keep top k of them
	if num >= k
		bbox = [proposals(index(1:k),:), scores(1:k); 0 0 0 0 -Inf];
	% if none of region have scores greater than threshold,
	% set all of them to be 0
	elseif num == 0
		bbox = [zeros(k, 5); 0 0 0 0 -Inf];
	% if there are fewer than k regions have scores greater than threshold,
	% filling remaining with last one
	else
		bbox = [proposals(index(1:num),:), scores(1:num)];
		bbox = [bbox; repmat([proposals(index(num), :), scores(num)], k-num, 1); 0 0 0 0 -Inf];
	end
end