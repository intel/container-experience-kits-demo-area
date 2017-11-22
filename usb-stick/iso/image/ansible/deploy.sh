#!/bin/bash

ansible-playbook -u ubuntu -i ./host.yml ./hello.yml
