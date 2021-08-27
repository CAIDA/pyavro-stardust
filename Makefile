.PHONY: build dist redist install install-from-source clean uninstall

build:
	CYTHONIZE=1 ./setup.py build

dist:
	CYTHONIZE=1 ./setup.py sdist bdist_wheel

redist: clean dist

install:
	CYTHONIZE=1 pip3 install .

install-from-source: dist
	pip3 install dist/pyavro-stardust-1.0.0.tar.gz

clean:
	$(RM) -r build dist src/*.egg-info
	$(RM) -r src/pyavro_stardust/*.c src/pyavro_stardust/*.cpp
	$(RM) -r src/pyavro_stardust/*.html
	$(RM) -r .pytest_cache
	find . -name __pycache__ -exec rm -r {} +
	#git clean -fdX

uninstall:
	pip3 uninstall pyavro-stardust

