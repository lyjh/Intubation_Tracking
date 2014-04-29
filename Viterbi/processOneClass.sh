rm ../data/*
cp ../../frames/"manikin_$1"/*.jpg ../data/
matlab -nosplash -nodisplay -nodesktop -r "script; quit "
mkdir ../tmp/"manikin_$1_carina"
mv ../tmp/*.mat ../tmp/"manikin_$1_carina"/
mv ../tmp/"manikin_$1_carina" ../../../result/
mv ../output/track_out.avi ../../../result/"manikin_$1_carina.avi"
