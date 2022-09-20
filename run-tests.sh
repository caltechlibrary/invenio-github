#!/usr/bin/env bash
# -*- coding: utf-8 -*-
#
# This file is part of Invenio.
# Copyright (C) 2016-2022 CERN.
#
# Invenio is free software; you can redistribute it and/or modify it under
# the terms of the MIT License; see LICENSE file for more details.
#
# In applying this license, CERN does not waive the privileges and immunities
# granted to it by virtue of its status as an Intergovernmental Organization
# or submit itself to any jurisdiction.

# Usage:
#   ./run-tests.sh [pytest options and args...]
#
# Note: the DB, SEARCH and CACHE services are determined by the values of the
#       corresponding environment variables if those variables are set;
#       otherwise, the following default values are used:
#              DB=postgresql, SEARCH=elasticsearch, CACHE=redis
#
# To change these values, you can set the environment variable on the command
# line when running this script. Example: to use mysql instead of postgresql,
# you can run this script as follows (assuming your shell is bash or sh):
#
#    DB=mysql ./run-tests.sh

# Quit on errors:
set -o errexit

# Quit on unbound symbols:
set -o nounset

# Test that the Docker daemons are running, or else docker-services-cli will
# dump a stack trace to the terminal and it won't necessarily be obvious why.
if ! docker stats --no-stream > /dev/null 2>&1 ; then
    echo "The Docker daemons do not appear to be running."
    exit 1
fi

# Define a cleanup function to shut down Invenio Docker services on exit:
function cleanup {
  eval "$(docker-services-cli down --env)"
}
trap cleanup EXIT

python -m check_manifest
python -m sphinx.cmd.build -qnN docs docs/_build/html
eval "$(docker-services-cli up --db ${DB:-postgresql} --search ${SEARCH:-elasticsearch} --cache ${CACHE:-redis} --env)"
python -m pytest
tests_exit_code=$?
python -m sphinx.cmd.build -qnNW -b doctest docs docs/_build/doctest
exit "$tests_exit_code"
