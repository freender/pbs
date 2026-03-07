FROM debian:trixie

ENV DEBIAN_FRONTEND=noninteractive
ARG PBS_VERSION

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    runit \
    tzdata \
  && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://enterprise.proxmox.com/debian/proxmox-release-trixie.gpg \
  -o /usr/share/keyrings/proxmox-archive-keyring.gpg

RUN cat > /etc/apt/sources.list.d/proxmox.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF

RUN cat > /etc/apt/sources.list.d/pbs-enterprise.sources <<'EOF'
Types: deb
URIs: https://enterprise.proxmox.com/debian/pbs
Suites: trixie
Components: pbs-enterprise
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
Enabled: false
EOF

RUN printf '#!/bin/sh\nexit 0\n' > /usr/bin/systemctl \
  && chmod +x /usr/bin/systemctl \
  && apt-get update \
  && if [ -n "$PBS_VERSION" ]; then DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confnew "proxmox-backup-server=${PBS_VERSION}" "proxmox-backup-client=${PBS_VERSION}"; else DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends -o Dpkg::Options::=--force-confnew proxmox-backup-server proxmox-backup-client; fi \
  && rm -f /usr/bin/systemctl \
  && rm -rf /var/lib/apt/lists/* \
  && printf '\nEnabled: false\n' >> /etc/apt/sources.list.d/proxmox.sources

RUN mkdir -p /etc/service/proxmox-backup /etc/service/proxmox-backup-proxy

RUN cat > /etc/service/proxmox-backup/run <<'EOF'
#!/bin/sh
exec /usr/lib/x86_64-linux-gnu/proxmox-backup/proxmox-backup-api
EOF

RUN cat > /etc/service/proxmox-backup-proxy/run <<'EOF'
#!/bin/sh
exec chpst -u backup:backup /usr/lib/x86_64-linux-gnu/proxmox-backup/proxmox-backup-proxy
EOF

RUN chmod +x /etc/service/proxmox-backup/run /etc/service/proxmox-backup-proxy/run

RUN cat > /etc/apt/apt.conf.d/no-nag-script <<'EOF'
DPkg::Post-Invoke { "if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i \"s/!== 'active'/== 'NoMoreNagging'/g\" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi"; };
EOF

RUN if [ -s /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js ] && ! grep -q -F 'NoMoreNagging' /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; then sed -i "s/!== 'active'/== 'NoMoreNagging'/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js; fi

COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 8007

ENTRYPOINT ["/entrypoint.sh"]
