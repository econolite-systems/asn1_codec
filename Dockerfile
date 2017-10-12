FROM ubuntu
USER root

WORKDIR /home

VOLUME ["/asn1_codec"]

# Add build tools.
RUN apt-get update && apt-get install -y software-properties-common wget git make gcc-4.9 g++-4.9 gcc-4.9-base && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-4.9 100 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.9 100

#install editors vim and nano
RUN apt-get update && apt-get install -y vim
RUN apt-get update && apt-get install -y nano

# Install cmake and automake.
RUN wget https://cmake.org/files/v3.7/cmake-3.7.2.tar.gz && tar -xvf cmake-3.7.2.tar.gz
RUN cd cmake-3.7.2 && ./bootstrap && make && make install && cd /home
RUN apt-get update && apt-get install -y automake

# install libtool
RUN apt-get update && apt-get install -y libtool

# Install flex
RUN apt-get update && apt-get install -y flex

#install bison 2.7.1
RUN wget http://launchpadlibrarian.net/140087283/libbison-dev_2.7.1.dfsg-1_amd64.deb
RUN wget http://launchpadlibrarian.net/140087282/bison_2.7.1.dfsg-1_amd64.deb
RUN dpkg -i libbison-dev_2.7.1.dfsg-1_amd64.deb
RUN dpkg -i bison_2.7.1.dfsg-1_amd64.deb
# To prevent update manager from overwriting this package
RUN apt-mark hold libbison-dev
RUN apt-mark hold bison

# Install librdkafka.
RUN git clone https://github.com/edenhill/librdkafka.git && cd librdkafka && ln -s /usr/bin/python3 /usr/bin/python && ./configure && make && make install

# Install pugixml library
#RUN wget https://github.com/zeux/pugixml/releases/download/v1.8/pugixml-1.8.tar.gz && tar -xvf pugixml-1.8.tar.gz
#cd pugixml-1.8 && mkdir -p build && cd build
#cmake ..
#make
#make install

# add the source and build files
ADD ./build_codec.sh /home
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib" >> ~/.profile
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib" >> ~/.bashrc
RUN echo "export CC=gcc" >> ~/.profile
RUN echo "export CC=gcc" >> ~/.bashrc

CMD ["/bin/bash"]
