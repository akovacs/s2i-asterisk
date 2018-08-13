# asterisk-centos7
FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Arpad Kovacs <akovacs@cs.stanford.edu>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Asterisk Container" \
      io.k8s.display-name="builder asterisk" \
      io.openshift.expose-services="5060:sip" \
      io.openshift.tags="builder,asterisk" \
      io.openshift.min-memory="1Gi" \
      io.openshift.min-cpu="1" \
      io.openshift.non-scalable="false"

# Install required packages here:
RUN yum update -y && \
    yum install -y epel-release && \
    yum install -y subversion patch wget git kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel uuid-devel speex-devel gsm-devel libuuid-devel net-snmp-devel xinetd tar jansson-devel make bzip2 libsrtp libsrtp-devel gnutls-devel doxygen texinfo curl-devel net-snmp-devel neon-devel libedit-devel rpm-build perl-interpreter lksctp-tools-devel perl perl-Test-Simple perl-Module-Load-Conditional && \
    yum clean all

# Copy configuration files
COPY ./etc/asterisk/ /etc/asterisk

WORKDIR /tmp
# Build and install OpenSSL 1.1.0h rpm
RUN wget https://dl.fedoraproject.org/pub/fedora-secondary/updates/28/Everything/i386/Packages/c/crypto-policies-20180425-5.git6ad4018.fc28.noarch.rpm
RUN rpm -i crypto-policies-20180425-5.git6ad4018.fc28.noarch.rpm
RUN wget https://dl.fedoraproject.org/pub/fedora/linux/updates/27/SRPMS/Packages/o/openssl-1.1.0h-3.fc27.src.rpm
RUN rpmbuild --rebuild openssl-1.1.0h-3.fc27.src.rpm
WORKDIR /opt/app-root/src/rpmbuild/RPMS/x86_64
RUN rpm -i --force --excludedocs openssl-libs-1.1.0h-3.el7.x86_64.rpm
RUN yum erase -y openssl-devel
RUN rpm -i --excludedocs openssl-devel-1.1.0h-3.el7.x86_64.rpm
RUN mv /usr/bin/openssl /usr/bin/openssl_1.0.1k
RUN rpm -i --force --excludedocs openssl-1.1.0h-3.el7.x86_64.rpm

# Clone asterisk-gvsip sources and build
WORKDIR /tmp
RUN git clone -b gvsip --depth 1 https://github.com/naf419/asterisk.git

WORKDIR /tmp/asterisk
RUN ./configure --with-jansson-bundled
# Optionally add MP3 Support:
# RUN contrib/scripts/get_mp3_source.sh
RUN make menuselect.makeopts

# Continue with a standard make.
RUN make
RUN make install
RUN make config
RUN cp configs/samples/asterisk.conf.sample /etc/asterisk/asterisk.conf
RUN cp configs/samples/modules.conf.sample /etc/asterisk/modules.conf
RUN sed -i 's/^\[directories.*/\[directories\]/' /etc/asterisk/asterisk.conf


# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
#RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

# TODO: Set the default port for applications built using this image
# to something nonstandard to deter attackers
EXPOSE 5060

# Set the default CMD for the image
CMD ["run"]
