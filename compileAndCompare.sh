#!/bin/sh
cd cuda/gaussian/
make
cd ../../
cd impGaussian/
make
cd ../
echo "Original:"
cuda/gaussian/gaussian -f data/gaussian/matrix16.txt -q
echo "Improved:"
impGaussian/gaussian -f data/gaussian/matrix16.txt -q