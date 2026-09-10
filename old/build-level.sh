#!/usr/bin/env bash

PLEVEL=./tools/plevel/target/plevel
if [[ -f "$PLEVEL" ]]; then
	mkdir -p src/datafiles/world
	./tools/plevel/target/plevel map src/datafiles/world
	read -p "enter to continue"
else
	echo "file $PLEVEL missing"
fi

