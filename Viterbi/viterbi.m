function [ seq ] = viterbi(tr, e)
% VITERBI
%   AUTH: Jaleel Salhi, jsalhi@umich.edu
%         John H. Kuhn, hkuhn@umich.edu
%         Professor Honglak Lee, honglak@eecs.umich.edu
%   DESC: Viterbi Algorithm given a transition cell array and an emission
%         cell array. This viterbi function will create an HMM given these
%         parameters and solve for the most optimal sequence of tags.
%
%   INPU: tr = transition score cell array of size (1 - numFrames)
%         e = emissions score cell array of size (numFrames)
%
%   OUTP: seq = array of tags corresponding to optimal sequence
%           tags: 1, 2, ..., k, k + 1
%           each tag corresponds to index of bbox at frame
%           k + 1 tag corresponds to the non-deetection bbox
%
%

% NOTE: transition scores multiplied by a factor of 10 for more weight

% initialize algorithm
N = length(e); % number of frames in sequence
               % add 2 for initialization frames (S-1 = S0 = *)
p = size(e,2); % number of possible tags
pi_matrix = zeros(p, p, N+2); % dynamic 3D matrix for pi values
bp_matrix = zeros(p, p, N); % dynamic 3D matrix for bp values

% add initialization frames (*, *)
pi_matrix(1, 1, 1) = 1; % pi(*, *, 0)
pi_matrix(1, :, 2) = 1; % pi(*, S, 1) where S = set of all tags


for k=1:N % for all frames
    
    i = k+2; % pi matrix index (since -1 and 0 are initialized)
    
    for u=1:p % for all tags at previous frame
        for v=1:p % for all tags at current frame
            
            
            if k == 1 % base case (tr = 1)
                [pi_matrix(u,v,i) bp_matrix(u,v,k)] = ...
                        max( pi_matrix(:,u,i-1) + (1 + e(k,v)) );
                continue;
            end
      
            [pi_matrix(u,v,i) bp_matrix(u,v,k)] = ...
                        max( pi_matrix(:,u,i-1) + (tr(k-1,:,u) + e(k,v))' );
            
        end
        
    end
end

% initialize sequence
seq = zeros(1, N);
[~, arg] = max(pi_matrix(:,:,N));
seq(N) = arg(1);
seq(N-1) = seq(N);

% retrieve sequence
for k=1:N-2
    i = N - 2 - k + 1;
    seq(i) = bp_matrix(seq(i+1), seq(i+2), i+2);
end           
            
end