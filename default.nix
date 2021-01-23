with import <nixpkgs> { };

buildGoModule rec {
  pname = "coredns";
  version = "1.8.1";

  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns";
    rev = "v${version}";
    sha256 = "04hkz70s5i7ndwyg39za3k83amvmi90rkjm8qp3w3a8fbmq4q4y6";
  };

  vendorSha256 = "1f4kikra3b67ipvwbw9yxr575q1pbgakdnp28naz007vh1rg8qf8";

  doCheck = false;

  # Add ads plugin to coredns
  patches = [
    ./ads-plugin.patch
  ];

  #overrideModAttrs = (old: {
  #  preConfigure = ''
  #    go mod edit -require=github.com/c-mueller/ads@v0.2.5-0.20201010140624-51e1b415ae8f
  #    go generate
  #  '';
  #});

  #preConfigure = ''
  #  go mod edit -require=github.com/c-mueller/ads@v0.2.5-0.20201010140624-51e1b415ae8f
  #  go generate
  #'';

  overrideModAttrs = (old: {
    preBuild = ''
      go mod edit -require=github.com/ooesili/coredns-docker@a1ebae1be1170a0a7673ca0a4b57ff2aed238d51
    '';
  });
  preBuild = ''
    sed -i '/^hosts:/a docker:github.com/ooesili/coredns-docker/docker' plugin.cfg
    go generate
  '';

  meta = with stdenv.lib; {
    homepage = "https://coredns.io";
    description = "A DNS server that runs middleware";
    license = licenses.asl20;
    maintainers = with maintainers; [ rushmorem rtreffer deltaevo ];
  };
}
