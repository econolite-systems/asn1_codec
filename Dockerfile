# === BUILDER IMAGE ===
FROM alpine:3.18 as builder
USER root
WORKDIR /asn1_codec
VOLUME ["/asn1_codec_share"]
ARG J2735_YEAR

# add build dependencies
RUN apk add --upgrade --no-cache --virtual .build-deps \
    cmake \
    g++ \
    make \
    bash \
    librdkafka \
    librdkafka-dev 

# Dependencies that are not needed if asn1c is not installed in the build container:
# libtool
# automake
# autoconf
# bison
# flex

# Install pugixml
ADD ./pugixml /asn1_codec/pugixml
RUN cd /asn1_codec/pugixml && mkdir -p build && cd build && cmake .. && make && make install

# The codec C files are pre-generated manually so it isn't necessary to build asn1c in the container
# # Build and install asn1c submodule
# ADD ./usdot-asn1c /asn1_codec/asn1c
# RUN cd asn1c && test -f configure || autoreconf -iv && ./configure && make && make install

# Make generated files available to the build & compile example
RUN export LD_LIBRARY_PATH=/usr/local/lib
ADD ./asn1c_combined /asn1_codec/asn1c_combined
RUN cd /asn1_codec/asn1c_combined && bash doIt.sh

# Remove any lingering .asn files
RUN rm -rf /asn1c_codec/asn1c_combined/j2735-asn-files
RUN rm -rf /asn1c_codec/asn1c_combined/semi-asn-files
RUN rm -rf /asn1c_codec/asn1c_combined/scms-asn-files

# Remove duplicate files
RUN rm -rf /asn1c_codec/asn1c_combined/generated-files

# add the source and build files
ADD CMakeLists.txt /asn1_codec
ADD ./config /asn1_codec/config
ADD ./include /asn1_codec/include
ADD ./src /asn1_codec/src
ADD ./kafka-test /asn1_codec/kafka-test
ADD ./unit-test-data /asn1_codec/unit-test-data
ADD ./data /asn1_codec/data
ADD ./run_acm.sh /asn1_codec
ADD ./data /asn1_codec/data

RUN echo "export LD_LIBRARY_PATH=/usr/local/lib" >> ~/.profile
RUN echo "export LD_LIBRARY_PATH=/usr/local/lib" >> ~/.bashrc
RUN echo "export CC=gcc" >> ~/.profile
RUN echo "export CC=gcc" >> ~/.bashrc

# Build acm.
RUN mkdir -p /build && cd /build && cmake /asn1_codec && make

# === RUNTIME IMAGE ===
FROM alpine:3.18
USER root
WORKDIR /asn1_codec
VOLUME ["/asn1_codec_share"]

# add runtime dependencies
RUN apk add --upgrade --no-cache \
    bash \
    librdkafka \
    librdkafka-dev

# copy the built files from the builder
COPY --from=builder /asn1_codec /asn1_codec
COPY --from=builder /build /build

# run ACM
RUN chmod 7777 /asn1_codec/run_acm.sh
CMD ["/asn1_codec/run_acm.sh"]
