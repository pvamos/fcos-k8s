# fcos-k8s

## Kubernetes v1.25.4 deploy on Fedora CoreOS 37.20221106.3.0 with ignition, ansible and kubeadm

## Installation

### Create 4 nodes, 1 controlplane and 3 workers

- Create the nodes, boot the fedora-coreos-37.XXXXXXXX.X.X-live.x86_64.iso or PXE.
- Configure DHCP networking, actualize `ansible/hosts` file.
- Check `*.ign` files povided in `ignition` to configure the nodes.

- If changes are needed, `*.ign` files can be generated with `butane`. For example:
```sh
butane --pretty --strict ignition/node1.fcc > node1.ign
```

- Apply the settings from the `*.ign` files. You you can use a HTTP/HTTPS server to provide the files. For example:

```sh
sudo coreos install /dev/vda --ignition-url=https://[DOMAIN].[TLD]/node1.ign
```

After completion (re)boot from the installed system.

Please note, that the nodes will have an additional reboot:
We use a one time only service to deploy python 3 at ignition to the nodes before ansible:
```sh
[Unit]
Requires=network-online.target
After=network-online.target
Before=sshd.service
[Service]
Type=oneshot
ExecCondition=/usr/bin/test ! -f /etc/python3-for-ansible.done
ExecStart=/usr/bin/sed -i '/\\[updates\\]/,/^\\[/ s/^enabled=.*$/enabled=0/' /etc/yum.repos.d/fedora-updates.repo
ExecStart=/usr/bin/rpm-ostree install python3 libselinux-python3
ExecStart=/usr/bin/sed -i '/\\[updates\\]/,/^\\[/ s/^enabled=.*$/enabled=1/' /etc/yum.repos.d/fedora-updates.repo
ExecStart=/usr/bin/sed -i '/^\\[updates\\]/a exclude=libxcrypt-compat* mpdecimal* python-pip-wheel* python-setuptools-wheel* python-unversioned-command* python3* python3-libs* python3-selinux*' /etc/yum.repos.d/fedora-updates.repo
ExecStartPost=/usr/bin/touch /etc/python3-for-ansible.done
ExecStartPost=/usr/sbin/shutdown -r now
[Install]
WantedBy=multi-user.target
```

We remove the temporary service with ansible later.

### Use ansible to deploy Kubernetes

```sh
time ansible-playbook -i hosts fcos-k8s.yaml
```

