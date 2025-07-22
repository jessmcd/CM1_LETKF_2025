#!/bin/bash

sed -i  '5s|.*|''base_dir             = "/work/jessica.mcdonald/CM1_LETKF_2025/experiments/CI_3min"''|' forecast_namelist.py
sed -i  '9s|.*|''forecast_start       = dt.datetime(2024,5,8,21,0)''|' forecast_namelist.py


# sed -i  '54s|.*|''post_inflate        = 0''|' namelist.py
# sed -i  '55s|.*|''post_inflate_alpha  = 1.0''|' namelist.py

#sed -i "52s|.*|""RTPP_coefficient    = 0.9,""|" namelist.py

#sed -i '6s/base_dir            =/base_dir            ="/work/jessica.mcdonald/CM1_LETKF_2025/experiments/test"' namelist.py

#sed -i  '55s|.*|''post_inflate_alpha  = 1.0''|' forecast_namelist.py