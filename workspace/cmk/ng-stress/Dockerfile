FROM centos:7

#ENV http_proxy
#ENV https_proxy 

ENV SHELL=/bin/bash

RUN \
  rpm --rebuilddb && yum clean all && \
  yum install -y epel-release && \
  yum install -y stress-ng
  
ENTRYPOINT ["/usr/bin/stress-ng"]
