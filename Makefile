.PHONY: joey
joey:
	nixos-rebuild switch --flake ".#joey" --sudo

.PHONY: yugi
yugi:
	nixos-rebuild switch --flake ".#yugi" --sudo
	nix run home-manager -- switch --flake ".#yugi"

.PHONY: work
work:
	rm -rf work
	mkdir -p work
	cp -rL ~/.config/fish work
	cp -rL ~/.config/zellij work
	cp -rL ~/.config/helix work
	cp -rL ~/.config/ghostty work
	cp -rL ~/.config/yazi work
	cd work; zip ../work.zip -r .
