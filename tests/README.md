# Tests

Run `python scripts/validate_structure.py` from the repository root. Run `cd backend && npm ci && npm run typecheck && npm test` for API static and policy tests. Swift must be built with a Darwin/iOS toolchain through xtool on Windows/WSL or an iOS SDK-enabled environment. Parser validation alone is not an on-device build.
