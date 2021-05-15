#!/usr/bin/env bash
set -euo pipefail

NIXPKGS=channel:nixos-20.09

wififw_models=(
	MacBookAir8,1
	MacBookPro15,1
	MacBookPro15,2
	MacBookPro15,3
	MacBookPro16,1
	MacBookPro16,2
)

packages=(
	kernel/linux-mbp
)

modules=(
	apple-bce
	apple-ib-drv
)

built_drvs=()

for p in ${packages[@]}; do
	echo ">>> Building '${p}'"

	drv="$(nix-build --no-out-link -I nixpkgs="${NIXPKGS}" -E 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./packages/'"${p}"' {}')"
	built_drvs+=(${drv})

	echo ">>> Built '${p}' (-> '${drv}')"
	du -sh "${drv}"
done

for model in ${wififw_models[@]}; do
	p='firmware/apple-wifi-firmware'
	echo ">>> Building '${p}' for model '${model}'"

	drv="$(nix-build --no-out-link -I nixpkgs="${NIXPKGS}" -E 'let pkgs = import <nixpkgs> {}; in pkgs.callPackage ./packages/'"${p}"' { macModel = "'"${model}"'"; }')"
	built_drvs+=(${drv})

	echo ">>> Built '${p}' (-> '${drv}')"
	du -sh "${drv}"
done

for p in ${modules[@]}; do
	echo ">>> Building '${p}'"

	drv="$(nix-build --no-out-link -I nixpkgs="${NIXPKGS}" -E 'let pkgs = import <nixpkgs> {}; mbp = pkgs.callPackage ./packages/kernel/linux-mbp {}; in pkgs.callPackage ./packages/kernel-modules/'"${p}"' { kernel = mbp; }')"
	built_drvs+=(${drv})

	echo ">>> Built '${p}' (-> '${drv}')"
	du -sh "${drv}"
done

if [ -n "${CACHIX_AUTH_TOKEN:-}" ] && [ -n "${CACHIX_SIGNING_KEY:-}" ]; then
	for d in ${built_drvs[@]}; do
		cachix push t2linux "${d}"
	done
fi
