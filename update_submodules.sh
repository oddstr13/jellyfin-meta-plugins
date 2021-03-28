#!/bin/bash
git submodule update --init --remote --checkout --force
git submodule foreach git checkout -B master origin/master