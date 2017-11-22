#!/bin/bash

for i in {0..1}
do
  sudo dpkg -i ./*.deb
done
