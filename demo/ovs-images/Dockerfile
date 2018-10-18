FROM ubuntu:bionic
RUN apt-get update && apt-get install -y dpdk;
WORKDIR /home
COPY get-prefix.sh /home
RUN chmod +x /home/get-prefix.sh
ENTRYPOINT ["bash"]
