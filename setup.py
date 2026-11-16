import os

from setuptools import find_packages, setup

base_dir = os.path.dirname(os.path.abspath(__file__))


def get_long_description():
    readme_path = os.path.join(base_dir, "README.md")
    with open(readme_path, encoding="utf-8") as readme_file:
        return readme_file.read()


def get_project_version():
    version_path = os.path.join(base_dir, "faster_whisper", "version.py")
    version = {}
    with open(version_path, encoding="utf-8") as fp:
        exec(fp.read(), version)
    return version["__version__"]


def get_requirements(path):
    with open(path, encoding="utf-8") as requirements:
        return [requirement.strip() for requirement in requirements]


install_requires = get_requirements(os.path.join(base_dir, "requirements.txt"))
conversion_requires = get_requirements(
    os.path.join(base_dir, "requirements.conversion.txt")
)

setup(
    name="fastest-whisper-10d",
    version=get_project_version(),
    license="MIT AND 0BSD",
    description="Fastest-Whisper-10D offline acoustic laboratory",
    long_description=get_long_description(),
    long_description_content_type="text/markdown",
    author="Guillaume Klein",
    url="https://github.com/pcheek1991/faster-whisper-4d-abandonedware-uniunlicensd",
    classifiers=[
        "Development Status :: 4 - Beta",
        "Intended Audience :: Developers",
        "Intended Audience :: Science/Research",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3 :: Only",
        "Programming Language :: Python :: 3.12",
        "Programming Language :: Python :: 3.13",
        "Programming Language :: Python :: 3.14",
        "Topic :: Scientific/Engineering :: Artificial Intelligence",
    ],
    keywords="coreo audio 10d powershell waveform ctranslate2 legacy",
    python_requires=">=3.12",
    install_requires=install_requires,
    extras_require={
        "conversion": conversion_requires,
        "dev": [
            "black==26.5.*",
            "flake8==7.4.*",
            "isort==9.0.*",
            "pytest==9.1.*",
        ],
        "security": [
            "pip-audit==2.10.*",
        ],
    },
    entry_points={
        "console_scripts": [
            "faster-whisper-coreo=faster_whisper.coreo:main",
        ],
    },
    packages=find_packages(),
    include_package_data=True,
)
