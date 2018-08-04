FROM alpine:3.8

# Since by default the first user has UID 1000, it's probably what most people want.
# You're free to change it though, no need to rebuild the container either.
ENV MC_UID 1000
ENV MC_GID 1000
# Space-separated list. Supplementary groups to add the user to.
ENV MC_SUPPLEMENTARY_GIDS ""
ENV MC_PASSWORD ""
ENV MC_AUTHORIZED_KEYS ""

RUN apk --no-cache upgrade && \
    apk add --no-cache \
      shadow \
      mc \
      openssh

RUN groupadd -g "$MC_GID" mc && \
    # '*' is the same as --disabled-password on non-busybox useradd-command, so pubkey authentication will still work.
    useradd --password '*' -u "$MC_UID" -g "$MC_GID" -d /home/mc -s /bin/sh mc && \
    mkdir -p /home/mc/.ssh && \
    chmod 700 /home/mc/.ssh && \
    mv /etc/ssh /etc/ssh-default && \
    # Make sure we don't have any host keys generated at this point
    rm -f /etc/ssh-default/*_key /etc/ssh-default/*.pub && \
    echo 'ForceCommand /usr/bin/mc /data /data' >> /etc/ssh-default/sshd_config && \
    # Seriously, Alpine has the root account unlocked (and with empty password)! :(
    # Noticed that in some containers it's not SUID but maybe shadow-package makes it SUID?
    passwd -l root

# Volume for storing sshd_config and host keys so they don't change on every restart
VOLUME /etc/ssh
VOLUME /data
EXPOSE 2222

# XXX: Currently, it's impossible to run newer (7.5) openssh without root :(
ENTRYPOINT set -eu; \
           [ -f "/etc/ssh/sshd_config" ]      || cp /etc/ssh-default/sshd_config /etc/ssh; \
           [ -f "/etc/ssh/moduli" ]           || cp /etc/ssh-default/moduli /etc/ssh; \
           [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -A; \
           [ -z "$MC_PASSWORD" ]              || echo "mc:$MC_PASSWORD" | chpasswd; \
           echo "$MC_AUTHORIZED_KEYS" > "/home/mc/.ssh/authorized_keys"; \
           # Modify the UID/GID if user has changed them from defaults
           [ $MC_UID -eq 1000 ] || usermod -u "$MC_UID" mc; \
           [ $MC_GID -eq 1000 ] || groupmod -g "$MC_GID" mc; \
           chown -R "$MC_UID:$MC_GID" /home/mc; \
           for ngid in $MC_SUPPLEMENTARY_GIDS; do \
               # Don't create if already exists
               getent group "$ngid" || groupadd -g "$ngid" "group_${ngid}"; \
               usermod -a -G "group_${ngid}" mc; \
           done; \
           /usr/sbin/sshd -f "/etc/ssh/sshd_config" -D -p 2222 -e