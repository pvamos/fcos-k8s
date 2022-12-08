# fcos-k8s

## Install Kubernetes v1.25.4 on Fedora CoreOS 37 with ignition, ansible and kubeadm

This is a simple solution to install a Kubernetes test cluster in a fully automated way.

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

---

MIT License

Copyright (c) 2022 Péter Vámos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
