#!/bin/bash

files=`find ! -path "*/src/gtest/*" \
            ! -path "*/src/mcnp/mcnp5/Source/*" \
            ! -path "*/src/mcnp/mcnp6/Source/*" \
            \( -name "*.cc"  -or \
               -name "*.cpp" -or \
               -name "*.h"   -or \
               -name "*.hh"  -or \
               -name "*.hpp" \)`
clang-format -i --verbose --style=google ${files}
