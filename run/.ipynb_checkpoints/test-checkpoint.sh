#!/bin/bash

sed -i  '6s|.*|''base_dir            = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/test"''|' namelist.py
sed -i  '52s|.*|''RTPP_coefficient    = 10''|' namelist.py
#sed -i "52s|.*|""RTPP_coefficient    = 0.9,""|" namelist.py

#sed -i '6s/base_dir            =/base_dir            ="/work/jessica.mcdonald/CM1_LETKF_2025/experiments/test"' namelist.py

