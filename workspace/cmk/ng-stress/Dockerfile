FROM ubuntu
 
#ENV http_proxy
#ENV https_proxy
 
RUN apt update && apt install -y stress-ng
 
ENV SHELL=/bin/bash
 
ENTRYPOINT ["/usr/bin/stress-ng"] 

