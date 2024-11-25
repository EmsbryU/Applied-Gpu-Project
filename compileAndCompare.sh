#!/bin/sh
cd cuda/gaussian/
make
cd ../../
cd impGaussian/
make
cd ../
cuda/gaussian/gaussian -f data/gaussian/matrix16.txt -q
impGaussian/gaussian -f data/gaussian/matrix16.txt -q