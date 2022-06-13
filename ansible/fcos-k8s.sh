# MIT License
#
# Copyright (c) 2020 Kim Wittenburg
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.

# This script prepares a Fedora CoreOS node to create or join a Kubernetes cluster
# via kubeadm. The script may be run directly on a node (or for example via SSH).
# At the end the script will trigger a reboot. When the node comes back up it
# can be joined into the cluster (or create a cluster) via the kubeadm too.
#
# When running kubeadm remember to explicitly specify --cri-socket=/var/run/crio/crio.sock
# in order to use the crio container runtime.

# Kubernetes Version
K8S_VERSION=1.24.1
# The CRICTL_VERSION must match the tag name on GitHub.
# See https://github.com/kubernetes-sigs/cri-tools/releases
CRICTL_VERSION=v1.24.2
# cri-o Versions.
# See https://github.com/cri-o/cri-o/releases
CRIO_VERSION=1.24.1
CRIO_REPO_VERSION="${CRIO_VERSION%.*}"

################################################################################

# Set SELinux in permissive mode (effectively disabling it)
# See: https://github.com/kubernetes/website/issues/14457
sudo setenforce 0
sudo sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config

# Enable the Kubernetes RPM repository. The Fedora repos do have variants of
# these tools but in older versions. By using the official repos we make sure
# that we have access to the latest version.
#
# See: https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/
sudo tee /etc/yum.repos.d/kubernetes.repo <<- EOF > /dev/null
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-\$basearch
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

# Enable cri-o repository.
# See: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o
sudo curl -fsSL -o /etc/yum.repos.d/devel:kubic:libcontainers:stable.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/CentOS_7/devel:kubic:libcontainers:stable.repo
sudo curl -fsSL -o /etc/yum.repos.d/devel:kubic:libcontainers:stable:cri-o:$CRIO_REPO_VERSION.repo https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable:cri-o:$CRIO_REPO_VERSION/CentOS_7/devel:kubic:libcontainers:stable:cri-o:$CRIO_REPO_VERSION.repo

################################################################################

# Configure Network Interfaces for use with cri-o
# See: https://kubernetes.io/docs/setup/production-environment/container-runtimes/#cri-o
# See: https://jebpages.com/2019/02/25/installing-kubeadm-on-fedora-coreos/
# We configure systemd to load the required kernel modules on the next boot.
#sudo tee /etc/modules-load.d/crio-net.conf << EOF > /dev/null
## Kernel modules required by the cri-o container engine.
#overlay
#br_netfilter
#EOF
#sudo tee /etc/sysctl.d/99-kubernetes-cri.conf <<- EOF > /dev/null
#net.bridge.bridge-nf-call-iptables  = 1
#"net.ipv4.ip_forward                 = 1
#net.bridge.bridge-nf-call-ip6tables = 1
#EOF
#sudo sysctl --system > /dev/null

# The following is equivalent to 
#   sudo systemctl enable cri-o
#   sudo systemctl enable kubelet
# However because we haven't installed cri-o and the kubelet yet we create the
# symlinks manually so that both services start on the next boot.
sudo ln -s /usr/lib/systemd/system/kubelet.service /etc/systemd/system/multi-user.target.wants/kubelet.service
sudo ln -s /usr/lib/systemd/system/crio.service /etc/systemd/system/multi-user.target.wants/crio.service


################################################################################

# The cri-tools from the kubernetes repo are relatively old. We replace the
# binary with the one from GitHub.
crictl_file=crictl-$CRICTL_VERSION-$(uname -s)-amd64.tar.gz
curl -fsSLO https://github.com/kubernetes-sigs/cri-tools/releases/download/$CRICTL_VERSION/$crictl_file
sudo tar -zxf $crictl_file -C /usr/local/bin
rm -f $crictl_file

sudo rpm-ostree refresh-md

# Install the kubelet and kubeadm binaries
sudo rpm-ostree install \
  kubelet-$K8S_VERSION \
  kubeadm-$K8S_VERSION \
  kubectl-$K8S_VERSION \
  cri-o-$CRIO_VERSION

# Before rebooting we sleep 1s to allow SSH connections to properly terminate.
# When running interactively this is not required and a simple 'systemctl reboot'
# is sufficient.
#{ sleep 1s; sudo systemctl reboot; } &

