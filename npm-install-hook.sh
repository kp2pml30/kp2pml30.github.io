npmInstallHook() {
	echo "Executing kp2pml30-website npmInstallHook"

	runHook preInstall

	npm exec -- vite build --outDir "$out"

	runHook postInstall

	echo "Finished npmInstallHook"
}

if [ -z "${dontNpmInstall-}" ] && [ -z "${installPhase-}" ]; then
	installPhase=npmInstallHook
fi
