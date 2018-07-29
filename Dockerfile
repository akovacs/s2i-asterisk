# asterisk-centos7
FROM openshift/base-centos7

# TODO: Put the maintainer name in the image metadata
LABEL maintainer="Arpad Kovacs <akovacs@cs.stanford.edu>"

# TODO: Rename the builder environment variable to inform users about application you provide them
ENV BUILDER_VERSION 1.0

# Set labels used in OpenShift to describe the builder images
LABEL io.k8s.description="Asterisk Container" \
      io.k8s.display-name="builder asterisk" \
      io.openshift.expose-services="8088:http,5060:sip" \
      io.openshift.tags="builder,asterisk" \
      io.openshift.min-memory="1Gi" \
      io.openshift.min-cpu="1" \
      io.openshift.non-scalable="false"

Install required packages here:
RUN yum update -y && \
    yum install -y epel-release && \
    yum install subversion patch wget git kernel-headers gcc gcc-c++ cpp ncurses ncurses-devel libxml2 libxml2-devel sqlite sqlite-devel openssl-devel newt-devel kernel-devel uuid-devel speex-devel gsm-devel libuuid-devel net-snmp-devel xinetd tar jansson-devel make bzip2 libsrtp libsrtp-devel gnutls-devel doxygen texinfo curl-devel net-snmp-devel neon-devel -y && \
    yum clean all
RUN cd /tmp && \
    git clone https://github.com/naf419/asterisk.git -b gvsip --depth 1

# TODO (optional): Copy the builder files into /opt/app-root
# COPY ./<builder_folder>/ /opt/app-root/

# TODO: Copy the S2I scripts to /usr/libexec/s2i, since openshift/base-centos7 image
# sets io.openshift.s2i.scripts-url label that way, or update that label
COPY ./s2i/bin/ /usr/libexec/s2i

# TODO: Drop the root user and make the content of /opt/app-root owned by user 1001
RUN chown -R 1001:1001 /opt/app-root

# This default user is created in the openshift/base-centos7 image
USER 1001

# TODO: Set the default port for applications built using this image
EXPOSE 8088
EXPOSE 5060

# Set the default CMD for the image
CMD ["run"]
