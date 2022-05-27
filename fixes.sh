#!/bin/bash

set -euxo pipefail

# Remove Fortran macros
sed -i "/INTEGER(KIND/d" LibP4est.jl

# Remove other probably unused macros
sed -i "/P4EST_NOTICE/d" LibP4est.jl
sed -i "/P4EST_GLOBAL_NOTICE/d" LibP4est.jl

