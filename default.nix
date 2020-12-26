with import <nixpkgs> { };

buildGoModule rec {
  pname = "coredns";
  version = "1.8.0";

  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "04hkz70s5i7ndwyg39za3k83amvmi90rkjm8qp3w3a8fbmq4q4y6";
  };

  # Add ads plugin to coredns
  patches = [
    ./ads-plugin.patch
  ];

  # Skip tests
  doCheck = false;

  # Update the internal coredns plugin imports
  preBuild = ''
    go generate coredns.go
    # Trying to build off the actual release seems to pull in some broken deps?
    #  # go.etcd.io/etcd/clientv3/balancer/picker
    # vendor/go.etcd.io/etcd/clientv3/balancer/picker/err.go:25:9: cannot use &errPicker literal (type *errPicker) as type Picker in return argument:
    #         *errPicker does not implement Picker (wrong type for Pick method)
    #                 have Pick(context.Context, balancer.PickInfo) (balancer.SubConn, func(balancer.DoneInfo), error)
    #                 want Pick(balancer.PickInfo) (balancer.PickResult, error)
    # vendor/go.etcd.io/etcd/clientv3/balancer/picker/roundrobin_balanced.go:33:9: cannot use &rrBalanced literal (type *rrBalanced) as type Picker in return argument:
    #         *rrBalanced does not implement Picker (wrong type for Pick method)
    #                 have Pick(context.Context, balancer.PickInfo) (balancer.SubConn, func(balancer.DoneInfo), error)
    #                 want Pick(balancer.PickInfo) (balancer.PickResult, error)
    #
    GOPROXY="https://proxy.golang.org,direct" go get github.com/c-mueller/ads@51e1b415ae8f750fb372a69c495abdaa4c9174a4
    GOPROXY="https://proxy.golang.org,direct" go mod vendor
  '';

  buildFlagsArray = [
    "-ldflags='-s -w -X github.com/coredns/coredns/coremain.GitCommit=${version}'"
  ];

  #vendorSha256 = "1zwrf2pshb9r3yvp7mqali47163nqhvs9ghflczfpigqswd1m0p0";
  # Need to set vendorSha to null here so we can manually handle the vendoring
  # in the prebuild stage.
  # This is necessary so we can pull in the ads plugin dependency
  vendorSha256 = null;

  meta = with stdenv.lib; {
    homepage = "https://github.com/coredns/coredns";
    description =
      "CoreDNS is a DNS server that chains plugins.";
    license = licenses.asl20;
  };
}
