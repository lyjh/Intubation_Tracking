function [ detection_array, seq, tags ] = mult_track(vid_feed_path, c, k)
% MULT TRACK
%   AUTH: Jaleel Salhi, jsalhi@umich.edu
%         John H. Kuhn, hkuhn@umich.edu
%         Professor Honglak Lee, honglak@eecs.umich.edu
%   DESC: Tracks multiple objects defined by models through a video
%
%   INPU: vid_feed_path = directory path where the video file is located
%         c = number of classes
%
%   OUTP: detection_array = sequential box locations in all frames of
%           video with labelled class
%         seq = tag sequence
%
%
lambda = 0.55; % scoring constant for bbox score
null_value = 0.1; % null score


% IMAGE PROCESSING
display(sprintf('\n-------------------------------------'));
display(sprintf('PROCESSING IMAGES'));
display(sprintf('-------------------------------------\n'));
% search directory for all frames    
d = dir([vid_feed_path '/*.jpg']);


% LOAD DATA
display(sprintf('\n-------------------------------------'));
display(sprintf('LOADING DATA'));
display(sprintf('-------------------------------------\n'));

% retrieve probs matrix
load('class_trans_matrix');

% retrieve c bbox_cell_arrays
display(sprintf('\n'));
%bbox_struct_cell_array = cell(1, c);

bbox_path = '../tmp/';%input(sprintf('Specify path to model corresponding to object number %i in the class transition matrix: \n'), 's');
try
	load([bbox_path 'bbox_data']);
catch exception
	error('Error loading the bounding box data...');
end

% create null class
N = length(bbox_cell_array);
% num of bbox obtained for each frame

% create bbox_cell_array
% bbox_cell_array: c x N x (k+1) x 5
% bbox_array: N x c(k+1) x 5
bbox_array = zeros(N,c*(k+1),5);
for i=1:N
    bbox_matrix = zeros(c*(k+1),5);
    for j=1:c
        bbox_matrix((j-1)*(k+1)+1:j*(k+1),:) = bbox_cell_array(j,i,:,:);
    end
    bbox_array(i,:,:) = bbox_matrix;
end


% TRANSITION SCORING
display(sprintf('\n-------------------------------------'));
display(sprintf('TRANSITION SCORING'));
display(sprintf('-------------------------------------\n'));
% For all frames:
%   Compute transition score between frames
%   Store all scores in a cell array
display('Please wait while the scores are calculated...');

try
    load('../tmp/mult_trans_data.mat');
catch exception
    transition_score_cell_array = zeros(N-1, (k+1)*c, (k+1)*c);
    
    % compute transition scores for all bbox pairs
    for i=1:N-1    
        transition_score_matrix = zeros((k+1)*c,(k+1)*c); % each row designates cur frame
        % each col designates next frame
        
        for ii=1:(k+1)*c        
			class_score = log(reshape(repmat(class_trans_matrix(ceil(ii/(k+1)), :), k+1, 1), 1, c*(k+1)));
			bbox_score = get_trans_score(bbox_array(i,ii,:), bbox_array(i+1,:,:))';
			transisition_score_matrix(ii, :) = class_score + lambda .* bbox_score;
        end
        
        transition_score_cell_array(i,:,:) = transition_score_matrix;
        
    end
    save('../tmp/mult_trans_data.mat', 'transition_score_cell_array');   
end

    


% VITERBI SEQUENCING
display(sprintf('\n-------------------------------------'));
display(sprintf('VITERBI SEQUENCING'));
display(sprintf('-------------------------------------\n'));

            
% For all frames:
%   Compute the emissions values for all scores
%       Sigmoid Function for normalization of scores
display('Calculating Emissions Scores...');

emissions_cell_array = zeros(N, c*(k+1));

for i=1:N
    current_emissions_vector = bbox_array(i,:,5); % c(k+1) vector
    
    neg_state_score = null_value;
    for j=1:c
        current_emissions_vector((k+1)*j) = neg_state_score;
    end
    if i==1 % init to first class null
        current_emissions_vector(k+1) = 100; % large number, but not inf
    end
    
    emissions_cell_array(i,:) = current_emissions_vector;
end


% run viterbi, retrieve sequence
display('Building Viterbi Algorithm...');
display('Calculating Optimal Sequence...');

try
    load('../tmp/mult_hmm_data.mat');
catch exception
	seq = viterbi(transition_score_cell_array, emissions_cell_array);

	display('Saving HMM data to file...');
	save('../tmp/mult_hmm_data.mat', 'seq');
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
% detection_array = zeros(N,5);

% tags = seq;

% for i=1:N
    % bbox = bbox_array(i,seq(i),:);
    % detection_array(i,:) = bbox;
    % if squeeze(bbox(1:4)) == zeros(4,1)
        % seq(i) = 0;
    % end
% end


% STEP 2: overlay bounding boxes onto each frame
display('Annotating Frames...');

outputVideo = VideoWriter(fullfile('../output/','track_full.avi'));
outputVideo.FrameRate = 25;%video.FrameRate;
open(outputVideo);

for i=1:N
    display(sprintf('Annotating frame: %d/%d', i, N));
	im = imread([vid_feed_path '/' d(i).name]);
	det = squeeze(bbox_array(i,seq(i),:))';
    frame = annotate_image2(det, im, i, seq(i), k);

	writeVideo(outputVideo,frame);
end

close(outputVideo);
display('Exporting Complete. Tracked video can be found at: ../output/track_out.avi');
display('Be sure to rename this file to give it significance and prevent it from being overwritten');
display('Closing Program...');
delete(sprintf('../tmp/*.jpg'));
    
end