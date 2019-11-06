FROM alpine:3.10.3
LABEL maintainer="kalaksi@users.noreply.github.com"

# Since by default the first user has UID 1000, it's probably what most people want.
# You're free to change it though, no need to rebuild the container either.
ENV MC_UID 1000
ENV MC_GID 1000
# Space-separated list. Supplementary groups to add the user to.
ENV MC_SUPPLEMENTARY_GIDS ""
# Change to 'yes' if the given password is already hashed and not a plain password.
# XXX: disabled until chpasswd bug has been fixed! https://github.com/alpinelinux/aports/pull/7239
#ENV MC_PASSWORD_HASHED "no"
# Provide the login password. This is not the preferred method especially for plain passwords
# and will be overridden by secrets-file if that is provided.
ENV MC_PASSWORD ""
# The preferred way for providing passwords. Use e.g. docker-compose secrets for which this
# variable has been configured for by default. Alternatively, you could bind-mount the
# password-file manually and change this if necessary:
ENV MC_PASSWORD_FILE "/run/secrets/mc_password"
# SSH pubkeys for login.
ENV MC_AUTHORIZED_KEYS ""

RUN apk --no-cache upgrade && \
    apk add --no-cache \
      shadow \
      mc \
      openssh

RUN groupadd -g "$MC_GID" mc && \
    # '*' is the same as --disabled-password on non-busybox useradd-command,
    # so pubkey authentication will still work.
    useradd --password '*' -u "$MC_UID" -g "$MC_GID" -d /home/mc -s /bin/sh mc && \
    mv /etc/ssh /etc/ssh-default && \
    # Make sure we don't have any host keys generated at this point
    rm -f /etc/ssh-default/*_key /etc/ssh-default/*.pub && \
    echo 'ForceCommand /usr/bin/mc /data /data' >> /etc/ssh-default/sshd_config && \
    # Lock root account. Seriously, Alpine has the root account unlocked by default (and with empty password)! :(
    # Noticed that in some containers it's not SUID but maybe shadow-package makes it SUID?
    # Opened an issue: https://github.com/gliderlabs/docker-alpine/issues/430
    passwd -l root

# Volume for storing sshd_config and host keys so they don't change on every restart
VOLUME /etc/ssh
EXPOSE 2222

# XXX: Currently, it's impossible to run newer (7.5) openssh without root :(
ENTRYPOINT set -eu; \
           export chpasswd_opts=""; \
           [ -f "/etc/ssh/sshd_config" ]      || cp /etc/ssh-default/sshd_config /etc/ssh; \
           [ -f "/etc/ssh/moduli" ]           || cp /etc/ssh-default/moduli /etc/ssh; \
           [ -f "/etc/ssh/ssh_host_rsa_key" ] || ssh-keygen -A; \
           # XXX: chpasswd too seems to currently have an issue so chpasswd is not currently working!
           # https://github.com/alpinelinux/aports/pull/7239
           # [ "$MC_PASSWORD_HASHED" == "no" ]  || chpasswd_opts="--encrypted"; \
           # [ -z "$MC_PASSWORD" ]              || echo -n "mc:$MC_PASSWORD" | chpasswd $chpasswd_opts; \
           # [ -f "$MC_PASSWORD_FILE" ]         && echo -n "mc:" | cat - "$MC_PASSWORD_FILE" | chpasswd $chpasswd_opts; \
           # Using passwd as a workaround:
           [ -z "$MC_PASSWORD" ]              || echo -en "${MC_PASSWORD}\n${MC_PASSWORD}" | passwd mc; \
           [ -f "$MC_PASSWORD_FILE" ]         && cat "$MC_PASSWORD_FILE" | cat - "$MC_PASSWORD_FILE" | passwd mc; \
           # Modify the UID/GID if user has changed them from defaults
           [ $MC_UID -eq 1000 ]               || usermod -u "$MC_UID" mc; \
           [ $MC_GID -eq 1000 ]               || groupmod -g "$MC_GID" mc; \
           # XXX: *sigh* there's a weird permission issue if the home directory and usermodes are done in base image
           #      but ownership changed in entrypoint: even root can't modify authorized_keys on second start then.
           #      Creating those here then...
           mkdir -p /home/mc/.ssh && \
           echo "$MC_AUTHORIZED_KEYS" > "/home/mc/.ssh/authorized_keys"; \
           chmod 700 -R /home/mc && \
           chown -R "$MC_UID:$MC_GID" /home/mc; \
           for ngid in $MC_SUPPLEMENTARY_GIDS; do \
               # Don't create if already exists
               getent group "$ngid" || groupadd -g "$ngid" "group_${ngid}"; \
               usermod -a -G "group_${ngid}" mc; \
           done; \
           /usr/sbin/sshd -f "/etc/ssh/sshd_config" -D -p 2222 -e
