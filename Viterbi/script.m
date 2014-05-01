% Testing script for epiglottis
%load('/mnt/neocortex/scratch/tsechiw/Intubation/Intubation_Tracking/models/2013:10:10_epiglottis/epiglottis_final.mat')
%load('/mnt/neocortex/scratch/tsechiw/Intubation/Intubation_Tracking/models/carina_manikin.mat');

data_path = input(sprintf('Specify path to the images: \n'), 's');
num_class = 4;
num_keep = 6;

det = track2(data_path, num_class, num_keep);
[det, seq, tag] = mult_track(data_path, num_class, num_keep);
