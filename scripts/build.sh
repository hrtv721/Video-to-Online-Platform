#!/usr/bin/env bash

BASE_DIR=${PWD}

# install Conda virtual environment
conda env create -f environment.yml

eval "$(conda shell.bash hook)"
conda activate Hysia

# compile decode module
cd "${BASE_DIR}"/hysia/core/HysiaDecode || return 1
make clean

# obtain nv driver version
version=$(nvidia-smi --query-gpu=driver_version --format=csv,noheader,nounits | head -n 1)
major=${version%.*}
# check if nv driver major version higher than 396
if ((major > 396))
then
  make
else
  make NV_VERSION="${major}"
fi

# build mmdect
echo "Building mmdect"
cd "${BASE_DIR}"/third || return 1
bash ./compile.sh

# build server
echo "Building server"
cd "${BASE_DIR}"/server || return 1
bash ./reset-db.sh

# generate rpc
python -m grpc_tools.protoc -I . --python_out=. --grpc_python_out=. protos/api2msl.proto
