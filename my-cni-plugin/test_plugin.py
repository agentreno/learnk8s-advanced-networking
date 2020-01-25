import os
import json
from unittest import mock

import pytest

import plugin


sample_netconf = {
    "cniVersion": "0.3.1",
    "name": "my-pod-network",
    "type": "my-cni-plugin",
    "myHostNet": "10.0.0.0/16",
    "myPodNet": "200.200.0.0/16",
    "myPodNodeSubnet": "200.200.1.0/24"
}

def test_prints_valid_version(capsys):
    plugin.version()
    captured = capsys.readouterr()

    version_data = json.loads(captured.out)

    assert "cniVersion" in version_data
    assert "supportedVersions" in version_data

@mock.patch("plugin.sys")
def test_reads_inputs(mock_sys):
    mock_sys.stdin.read.return_value = json.dumps(sample_netconf)

    (netconf, host_network, pod_network, pod_node_subnet) = plugin.read_inputs()

    assert netconf == sample_netconf
    assert host_network == sample_netconf["myHostNet"]
    assert pod_network == sample_netconf["myPodNet"]
    assert pod_node_subnet == sample_netconf["myPodNodeSubnet"]

@mock.patch("plugin.sys")
@mock.patch("plugin.subprocess")
def test_add_invokes_ipam(mock_subprocess, mock_sys):
    os.environ["CNI_NETNS"] = "/proc/pid/ns/net"
    os.environ["CNI_CONTAINERID"] = "someid"
    os.environ["CNI_IFNAME"] = "eth0"
    mock_sys.stdin.read.return_value = json.dumps(sample_netconf)
    mock_subprocess_result = mock.MagicMock()
    mock_subprocess_result.returncode = 0
    mock_subprocess_result.stdout.decode.return_value = \
        '{"ips": [{"address": "0.0.0.0", "gateway": "0.0.0.0"}]}'
    mock_subprocess.run.return_value = mock_subprocess_result

    plugin.add()

    mock_subprocess.run.assert_any_call(
        [plugin.IPAM_BINARY],
        input=mock.ANY,
        stdout=mock.ANY
    )

@mock.patch("plugin.sys")
@mock.patch("plugin.subprocess")
def test_delete_invokes_ipam(mock_subprocess, mock_sys):
    mock_sys.stdin.read.return_value = json.dumps(sample_netconf)

    plugin.delete()

    mock_subprocess.run.assert_any_call(
        [plugin.IPAM_BINARY],
        input=mock.ANY
    )
