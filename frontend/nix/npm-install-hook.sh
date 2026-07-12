npmInstallHook() {
	echo "Executing kp2pml30-website npmInstallHook"

	runHook preInstall

	npm run build
	mkdir -p "$out"
	cp -r dist/* "$out"/

	runHook postInstall

	echo "Finished npmInstallHook"
}

if [ -z "${dontNpmInstall-}" ] && [ -z "${installPhase-}" ]; then
	installPhase=npmInstallHook
fi
